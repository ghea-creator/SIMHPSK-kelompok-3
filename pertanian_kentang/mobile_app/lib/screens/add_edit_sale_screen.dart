import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// intl removed: date input is text-only YYYY-MM-DD
import '../services/api_service.dart';
import '../models/sale.dart';
import '../models/season.dart';
import '../utils/thousands_formatter.dart';
import '../widgets/app_theme.dart';

class AddEditSaleScreen extends StatefulWidget {
  final Sale? sale;
  final VoidCallback? onSaved;

  const AddEditSaleScreen({
    this.sale,
    this.onSaved,
    super.key,
  });

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  late ApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _buyerNameController;
  late TextEditingController _buyerPhoneController;
  late TextEditingController _quantityController;
  late TextEditingController _pricePerUnitController;
  late TextEditingController _notesController;

  bool _isSaving = false;
  int? _totalPrice;
  late String _paymentStatus;

  List<Season> _seasons = [];
  Season? _selectedSeason;
  bool _isLoadingSeasons = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();

    _dateController = TextEditingController(
      text: widget.sale?.saleDate ?? '',
    );
    _buyerNameController = TextEditingController(
      text: widget.sale?.buyerName ?? '',
    );
    _buyerPhoneController = TextEditingController(
      text: widget.sale?.buyerPhone ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.sale?.quantity.toString() ?? '',
    );
    _pricePerUnitController = TextEditingController(
      text: widget.sale?.pricePerUnit != null ? ThousandsFormatter.format(widget.sale!.pricePerUnit.toString()) : '',
    );
    _notesController = TextEditingController(
      text: widget.sale?.notes ?? '',
    );
    _paymentStatus = widget.sale?.status == 'pending' ? 'unpaid' : 'paid';

    _updateTotal();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _isLoadingSeasons = true;
    });

    try {
      final seasons = await _apiService.getSeasons();
      if (mounted) {
        setState(() {
          _seasons = seasons;
          if (widget.sale != null && widget.sale!.seasonId != null) {
            _selectedSeason = _seasons.firstWhere(
              (s) => s.id == widget.sale!.seasonId,
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
          _isLoadingSeasons = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSeasons = false;
        });
      }
    }
  }

  void _updateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = int.tryParse(_pricePerUnitController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _totalPrice = quantity * price;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2100);

    final DateTime? currentInputDate = DateTime.tryParse(_dateController.text);
    if (currentInputDate != null) {
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

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final pricePerUnit = int.tryParse(_pricePerUnitController.text.replaceAll('.', '')) ?? 0;
    if (pricePerUnit > 0 && pricePerUnit < 1000) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Harga rendah'),
          content: const Text('Harga per kg kurang dari Rp 1.000. Apakah Anda yakin ingin melanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> result;

      if (widget.sale == null) {
        // Create new
        result = await _apiService.createSale(
          quantity: int.parse(_quantityController.text),
          pricePerUnit: int.parse(_pricePerUnitController.text.replaceAll('.', '')),
          saleDate: _dateController.text,
          buyerName: _buyerNameController.text,
          buyerPhone: _buyerPhoneController.text.isEmpty
              ? null
              : _buyerPhoneController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: 'completed',
          paymentStatus: _paymentStatus,
          seasonId: _selectedSeason?.id,
        );
      } else {
        // Edit existing
        result = await _apiService.updateSale(
          widget.sale!.id,
          quantity: int.parse(_quantityController.text),
          pricePerUnit: int.parse(_pricePerUnitController.text.replaceAll('.', '')),
          saleDate: _dateController.text,
          buyerName: _buyerNameController.text,
          buyerPhone: _buyerPhoneController.text.isEmpty
              ? null
              : _buyerPhoneController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: 'completed',
          paymentStatus: _paymentStatus,
          seasonId: _selectedSeason?.id,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.sale == null
                  ? 'Penjualan berhasil ditambahkan'
                  : 'Penjualan berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSaved?.call();
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _quantityController.dispose();
    _pricePerUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.sale != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Catatan Penjualan' : 'Tambah Catatan Penjualan'),
        backgroundColor: AppTheme.green700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                      // Heading
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shopping_cart, color: Color(0xFF27AE60)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Form Ubah Penjualan' : 'Form Penjualan Baru',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Season Dropdown
                      const Text('Musim Tanam (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _isLoadingSeasons
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<Season?>(
                              value: _selectedSeason,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                fillColor: Colors.grey.shade50,
                                filled: true,
                              ),
                              items: [
                                const DropdownMenuItem<Season?>(
                                  value: null,
                                  child: Text('Semua Musim / Tanpa Musim'),
                                ),
                                ..._seasons.map((Season season) {
                                  return DropdownMenuItem<Season?>(
                                    value: season,
                                    child: Text(season.name),
                                  );
                                }),
                              ],
                              onChanged: (Season? newValue) {
                                setState(() {
                                  _selectedSeason = newValue;
                                  
                                  if (newValue != null && _dateController.text.isNotEmpty) {
                                    final currentDate = DateTime.tryParse(_dateController.text);
                                    final seasonStart = DateTime.tryParse(newValue.startDate);
                                    final seasonEnd = DateTime.tryParse(newValue.endDate);
                                    
                                    if (currentDate != null && seasonStart != null && seasonEnd != null) {
                                      if (currentDate.isBefore(seasonStart) || currentDate.isAfter(seasonEnd)) {
                                        _dateController.text = '';
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tanggal direset karena di luar musim tanam terpilih.')),
                                        );
                                      }
                                    }
                                  }
                                });
                              },
                            ),
                      const SizedBox(height: 20),

                      // Date
                      const Text('Tanggal Penjualan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          hintText: 'Pilih Tanggal Penjualan',
                          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF27AE60)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          fillColor: Colors.grey.shade50,
                          filled: true,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Tanggal harus diisi';
                          if (DateTime.tryParse(value!) == null) return 'Tanggal tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Buyer Name
                      const Text('Nama Pembeli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _buyerNameController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama pembeli...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Nama pembeli harus diisi' : null,
                      ),
                      const SizedBox(height: 20),

                      // Buyer Phone
                      const Text('Nomor Telepon Pembeli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _buyerPhoneController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: 081234567890 (Opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Quantity
                      const Text('Jumlah Terjual (Kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quantityController,
                        onChanged: (_) => _updateTotal(),
                        decoration: InputDecoration(
                          hintText: 'Masukkan berat kentang...',
                          suffixText: 'kg',
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

                      // Price Per Unit
                      const Text('Harga per Kg (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pricePerUnitController,
                        onChanged: (_) => _updateTotal(),
                        inputFormatters: [ThousandsFormatter()],
                        decoration: InputDecoration(
                          hintText: 'Contoh: 12.000',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Harga harus diisi';
                          final cleanValue = value!.replaceAll('.', '');
                          if (int.tryParse(cleanValue) == null ||
                              int.parse(cleanValue) < 1) {
                            return 'Harga minimal 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Total Price Display
                      if (_totalPrice != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Estimasi Total Pendapatan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatCurrency(_totalPrice!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Payment Status
                      const Text('Status Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text('Lunas'),
                          ),
                          DropdownMenuItem(
                            value: 'unpaid',
                            child: Text('Belum Lunas'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _paymentStatus = value;
                          });
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
                          onPressed: _isSaving ? null : _saveSale,
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
                                  isEdit ? 'Perbarui Penjualan' : 'Simpan Penjualan',
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

  String _formatCurrency(int value) {
    return 'Rp ${(value).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }
}
