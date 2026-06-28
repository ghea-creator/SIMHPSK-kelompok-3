class Season {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final String status;
  final String? notes;
  final double targetKg;
  final double totalPanen;

  Season({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.notes,
    this.targetKg = 0,
    this.totalPanen = 0,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as int,
      name: json['name'] as String,
      startDate: (json['start_date'] as String? ?? '').split('T')[0],
      endDate: (json['end_date'] as String? ?? '').split('T')[0],
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
      targetKg: double.tryParse(json['target_kg']?.toString() ?? '') ?? 0.0,
      totalPanen: double.tryParse(json['total_harvest_kg']?.toString() ?? '') ?? 0.0,
    );
  }
}
