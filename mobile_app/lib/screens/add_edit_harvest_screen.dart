import 'package:flutter/material.dart';
// intl not needed after replacing date picker with text input
import '../services/api_service.dart';
import '../models/harvest.dart';
import '../models/season.dart';

class AddEditHarvestScreen extends StatefulWidget {
  final Harvest? harvest;
  final VoidCallback? onSaved;

  const AddEditHarvestScreen({
    this.harvest,
    this.onSaved,
    super.key,
  });

  @override
  State<AddEditHarvestScreen> createState() => _AddEditHarvestScreenState();
}

class _AddEditHarvestScreenState extends State<AddEditHarvestScreen> {
  late ApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _quantityController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;

  List<Season> _seasons = [];
  Season? _selectedSeason;
  bool _isLoading = false;
  bool _isSaving = false;
  String _status = 'recorded';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();

    _dateController = TextEditingController(
      text: widget.harvest?.harvestDate ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.harvest?.quantity.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.harvest?.weightKg.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.harvest?.notes ?? '',
    );
    _status = widget.harvest?.status ?? 'recorded';

    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final seasons = await _apiService.getSeasons();
      if (mounted) {
        setState(() {
          _seasons = seasons;
          if (widget.harvest != null) {
            _selectedSeason = _seasons.firstWhere(
              (s) => s.id == widget.harvest!.seasonId,
              orElse: () => _seasons.isNotEmpty ? _seasons.first : Season(
                id: 0,
                name: 'N/A',
                startDate: '',
                endDate: '',
                status: 'active',
              ),
            );
          } else if (_seasons.isNotEmpty) {
            _selectedSeason = _seasons.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2100);

    // Determine initial date
    DateTime initialDate = DateTime.now();
    final DateTime? currentInputDate = DateTime.tryParse(_dateController.text);

    if (currentInputDate != null &&
        !currentInputDate.isBefore(firstDate) &&
        !currentInputDate.isAfter(lastDate)) {
      initialDate = currentInputDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF27AE60),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF27AE60),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final String formatted = "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _dateController.text = formatted;
      });
    }
  }

  Future<void> _saveharvest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSeason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih musim tanam terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final Map<String, dynamic> result;

      if (widget.harvest == null) {
        // Create new
        result = await _apiService.createHarvest(
          seasonId: _selectedSeason!.id,
          harvestDate: _dateController.text,
          quantity: int.parse(_quantityController.text),
          weightKg: double.parse(_weightController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: _status,
        );
      } else {
        // Edit existing
        result = await _apiService.updateHarvest(
          widget.harvest!.id,
          seasonId: _selectedSeason!.id,
          harvestDate: _dateController.text,
          quantity: int.parse(_quantityController.text),
          weightKg: double.parse(_weightController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: _status,
        );
      }

      setState(() {
        _isSaving = false;
      });

      if (result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(widget.harvest == null
                ? 'Panen berhasil ditambahkan'
                : 'Panen berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved?.call();
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.harvest != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Catatan Panen' : 'Tambah Catatan Panen'),
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF27AE60)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Form
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.agriculture, color: Color(0xFF27AE60)),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isEdit ? 'Form Ubah Panen' : 'Form Panen Baru',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(height: 32),

                            // Season Dropdown
                            const Text('Musim Tanam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Season>(
                              initialValue: _selectedSeason,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                fillColor: Colors.grey.shade50,
                                filled: true,
                              ),
                              items: _seasons
                                  .map((season) => DropdownMenuItem(
                                        value: season,
                                        child: Text(season.name),
                                      ))
                                  .toList(),
                              onChanged: (Season? value) {
                                setState(() {
                                  _selectedSeason = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Pilih musim tanam' : null,
                            ),
                            const SizedBox(height: 20),

                            // Date
                            const Text('Tanggal Panen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Pilih Tanggal Panen',
                                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF27AE60)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                fillColor: Colors.grey.shade50,
                                filled: true,
                              ),
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Tanggal harus diisi';
                                final DateTime? parsedDate = DateTime.tryParse(value!);
                                if (parsedDate == null) return 'Tanggal tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Quantity
                            const Text('Jumlah Tanaman (Unit)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                hintText: 'Contoh: 150',
                                suffixText: 'unit',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Jumlah harus diisi';
                                if (int.tryParse(value!) == null ||
                                    int.parse(value) < 1) {
                                  return 'Jumlah minimal 1';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Weight
                            const Text('Berat Hasil Panen (Kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                hintText: 'Contoh: 75.5',
                                suffixText: 'kg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Berat harus diisi';
                                if (double.tryParse(value!) == null ||
                                    double.parse(value) < 0.01) {
                                  return 'Berat minimal 0.01 kg';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                             // Status
                             const Text('Status Panen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                             const SizedBox(height: 8),
                             DropdownButtonFormField<String>(
                               initialValue: _status,
                               decoration: InputDecoration(
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(10),
                                 ),
                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                 fillColor: Colors.grey.shade50,
                                 filled: true,
                               ),
                               items: const [
                                 DropdownMenuItem(value: 'recorded', child: Text('Tercatat')),
                                 DropdownMenuItem(value: 'verified', child: Text('Terverifikasi')),
                                 DropdownMenuItem(value: 'cancelled', child: Text('Batal')),
                               ],
                               onChanged: (String? value) {
                                 if (value != null) {
                                   setState(() {
                                     _status = value;
                                   });
                                 }
                               },
                             ),
                             const SizedBox(height: 20),

                             // Notes
                             const Text('Catatan / Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                hintText: 'Keterangan tambahan...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              maxLines: 3,
                              maxLength: 500,
                            ),
                            const SizedBox(height: 32),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF27AE60),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _isSaving ? null : _saveharvest,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isEdit ? 'Perbarui Panen' : 'Simpan Panen',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
