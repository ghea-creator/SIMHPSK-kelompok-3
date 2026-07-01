import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/cost.dart';
import '../models/season.dart';
import '../utils/thousands_formatter.dart';
import '../widgets/app_theme.dart';

class AddEditCostScreen extends StatefulWidget {
  final Cost? cost;

  const AddEditCostScreen({super.key, this.cost});

  @override
  State<AddEditCostScreen> createState() => _AddEditCostScreenState();
}

class _AddEditCostScreenState extends State<AddEditCostScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  late DateTime _selectedDate;
  int? _selectedSeasonId;
  String _selectedCategory = 'seed';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<Season> _seasons = [];
  bool _isLoadingSeasons = true;
  bool _isSaving = false;

  final List<Map<String, String>> _categories = [
    {'value': 'seed', 'label': 'Bibit'},
    {'value': 'fertilizer', 'label': 'Pupuk'},
    {'value': 'pesticide', 'label': 'Pestisida'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = (widget.cost != null && widget.cost!.date.isNotEmpty)
        ? (DateTime.tryParse(widget.cost!.date) ?? DateTime.now())
        : DateTime.now();
    _selectedCategory = widget.cost?.category ?? 'seed';
    _selectedSeasonId = widget.cost?.seasonId;
    _amountController.text = widget.cost != null ? ThousandsFormatter.format(widget.cost!.amount.toStringAsFixed(0)) : '';
    _notesController.text = widget.cost?.notes ?? '';
    _loadSeasons();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSeasons() async {
    try {
      final seasons = await _apiService.getSeasons();
      setState(() {
        _seasons = seasons;
        _isLoadingSeasons = false;
        // If we are in Add Mode and seasons exist, pre-select the first season
        if (widget.cost == null && _selectedSeasonId == null && seasons.isNotEmpty) {
          _selectedSeasonId = seasons.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSeasons = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar musim: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF27AE60),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;
    
    final Map<String, dynamic> result;
    if (widget.cost != null) {
      // Edit Mode
      result = await _apiService.updateCost(
        widget.cost!.id,
        date: formattedDate,
        seasonId: _selectedSeasonId,
        category: _selectedCategory,
        amount: amount,
        notes: _notesController.text.trim(),
      );
    } else {
      // Add Mode
      result = await _apiService.createCost(
        date: formattedDate,
        seasonId: _selectedSeasonId,
        category: _selectedCategory,
        amount: amount,
        notes: _notesController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.cost != null 
              ? 'Catatan biaya berhasil diperbarui!' 
              : 'Catatan biaya berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan catatan biaya'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.cost != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Catatan Biaya' : 'Tambah Catatan Biaya'),
        backgroundColor: AppTheme.green700,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingSeasons
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Heading Title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.receipt_long, color: Color(0xFF27AE60)),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isEdit ? 'Form Ubah Biaya' : 'Form Biaya Baru',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(height: 32),

                            // Date Selector
                            const Text('Tanggal Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade50,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                    ),
                                    const Icon(Icons.calendar_today, color: Color(0xFF27AE60)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Season Dropdown
                            const Text('Musim Tanam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              initialValue: _selectedSeasonId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                fillColor: Colors.grey.shade50,
                                filled: true,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Tanpa Musim (Biaya Umum)'),
                                ),
                                ..._seasons.map((s) => DropdownMenuItem<int?>(
                                      value: s.id,
                                      child: Text(s.name),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedSeasonId = val);
                              },
                            ),
                            const SizedBox(height: 20),

                            // Category Selector
                            const Text('Kategori Biaya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                fillColor: Colors.grey.shade50,
                                filled: true,
                              ),
                              items: _categories.map((c) => DropdownMenuItem<String>(
                                    value: c['value'],
                                    child: Text(c['label']!),
                                  )).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            // Amount Input
                            const Text('Jumlah Pengeluaran (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                             TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [ThousandsFormatter()],
                              decoration: InputDecoration(
                                hintText: 'Contoh: 150.000',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Jumlah biaya tidak boleh kosong';
                                }
                                final cleanValue = value.replaceAll('.', '');
                                final val = double.tryParse(cleanValue);
                                if (val == null || val <= 0) {
                                  return 'Jumlah biaya harus berupa angka positif';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Notes Input
                            const Text('Catatan / Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Masukkan keterangan tambahan (contoh: Beli bibit granola super 50kg)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.all(16),
                              ),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 2,
                                ),
                                onPressed: _isSaving ? null : _save,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        isEdit ? 'Perbarui Biaya' : 'Simpan Pengeluaran',
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
