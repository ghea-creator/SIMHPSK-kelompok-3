import 'package:flutter/material.dart';
import '../models/season.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class SeasonScreen extends StatefulWidget {
  const SeasonScreen({super.key});

  @override
  State<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends State<SeasonScreen> {
  final _apiService = ApiService();
  List<Season> _seasons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() => _isLoading = true);
    try {
      final seasons = await _apiService.getSeasons();
      setState(() {
        _seasons = seasons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSeasonForm({Season? season}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SeasonFormBottomSheet(
        apiService: _apiService,
        season: season,
        existingSeasons: _seasons,
        onSuccess: (_) {
          _loadSeasons();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteSeason(Season season) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Musim Tanam'),
        content: Text('Yakin hapus musim tanam "${season.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _apiService.deleteSeason(season.id);
      if (result['success'] == true) {
        _loadSeasons();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Musim tanam berhasil dihapus')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal menghapus')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Musim Tanam', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
          : _seasons.isEmpty
              ? _buildEmptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return _buildDesktopLayout();
                    }
                    return _buildMobileLayout();
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSeasonForm(),
        backgroundColor: const Color(0xFF27AE60),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Musim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Belum ada musim tanam', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Mulai dengan menambahkan musim tanam baru.', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _seasons.length,
      itemBuilder: (context, index) {
        final season = _seasons[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(season.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${_formatDateString(season.startDate)} s/d ${_formatDateString(season.endDate)}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(season.status),
                    Text('Target: ${season.targetKg} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showSeasonForm(season: season);
                } else if (value == 'delete') {
                  _deleteSeason(season);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Musim Tanam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  Text('Total: ${_seasons.length} Musim', style: const TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                    return const Color(0xFFF9FAFB);
                  }),
                  dataRowMaxHeight: 65,
                  columns: const [
                    DataColumn(label: Text('Nama Musim', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tanggal Mulai', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tanggal Selesai', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Target (Kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _seasons.map((season) {
                    return DataRow(
                      cells: [
                        DataCell(Text(season.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text(_formatDateString(season.startDate))),
                        DataCell(Text(_formatDateString(season.endDate))),
                        DataCell(Text('${season.targetKg} kg')),
                        DataCell(_buildStatusBadge(season.status)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () => _showSeasonForm(season: season),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Hapus',
                              onPressed: () => _deleteSeason(season),
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        label = 'Aktif';
        break;
      case 'completed':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        label = 'Selesai';
        break;
      default:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDateString(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }
}

class _SeasonFormBottomSheet extends StatefulWidget {
  final ApiService apiService;
  final Season? season;
  final List<Season> existingSeasons;
  final Function(Season) onSuccess;

  const _SeasonFormBottomSheet({
    required this.apiService,
    this.season,
    required this.existingSeasons,
    required this.onSuccess,
  });

  @override
  State<_SeasonFormBottomSheet> createState() => _SeasonFormBottomSheetState();
}

class _SeasonFormBottomSheetState extends State<_SeasonFormBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _targetKgController;
  late TextEditingController _notesController;
  String _status = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.season?.name ?? '');
    _startDateController = TextEditingController(text: widget.season?.startDate ?? '');
    _endDateController = TextEditingController(text: widget.season?.endDate ?? '');
    _notesController = TextEditingController(text: widget.season?.notes ?? '');
    _targetKgController = TextEditingController(text: widget.season != null ? widget.season!.targetKg.toString() : '');
    _status = widget.season?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _targetKgController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _startDateController.text.isEmpty ||
        _endDateController.text.isEmpty ||
        _targetKgController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    final normalizedName = _nameController.text.trim().toLowerCase();
    final hasDuplicateName = widget.existingSeasons.any((season) {
      final seasonName = season.name.trim().toLowerCase();
      return seasonName == normalizedName && (widget.season == null || season.id != widget.season!.id);
    });

    if (hasDuplicateName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama musim tanam sudah digunakan. Gunakan nama lain.')),
      );
      return;
    }

    final startDate = DateTime.tryParse(_startDateController.text);
    final endDate = DateTime.tryParse(_endDateController.text);
    if (startDate == null || endDate == null || endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal akhir harus setelah tanggal mulai.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final targetKg = double.tryParse(_targetKgController.text) ?? 0;

      Map<String, dynamic> result;

      if (widget.season == null) {
        // Create new season
        result = await widget.apiService.createSeason(
          name: _nameController.text,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          status: _status,
          targetKg: targetKg,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      } else {
        // Update existing season
        result = await widget.apiService.updateSeason(
          widget.season!.id,
          name: _nameController.text,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          status: _status,
          targetKg: targetKg,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Berhasil disimpan')),
          );
          widget.onSuccess(result['season']);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal disimpan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.season != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditMode ? 'Edit Musim Tanam' : 'Tambah Musim Tanam',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Musim Tanam',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _startDateController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Mulai',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.date_range),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(_startDateController),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _endDateController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Selesai',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.date_range),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(_endDateController),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _targetKgController,
                  decoration: InputDecoration(
                    labelText: 'Target Kg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.scale),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.info),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')),
                  ],
                  onChanged: (value) => setState(() => _status = value ?? 'active'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditMode ? 'Perbarui' : 'Simpan'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
