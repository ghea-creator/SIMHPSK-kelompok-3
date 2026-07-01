class Harvest {
  final int id;
  final int seasonId;
  final String seasonName;
  final int quantity;
  final double weightKg;
  final String harvestDate;
  final String notes;
  final String status;

  Harvest({
    required this.id,
    required this.seasonId,
    required this.seasonName,
    required this.quantity,
    required this.weightKg,
    required this.harvestDate,
    required this.notes,
    required this.status,
  });

  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      id: json['id'] as int,
      seasonId: json['season_id'] as int,
      seasonName: json['season_name'] as String? ?? (json['season'] != null ? json['season']['name'] as String? : null) ?? 'N/A',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      weightKg: double.tryParse(json['weight_kg']?.toString() ?? '') ?? 0.0,
      harvestDate: ((json['harvest_date'] ?? json['date']) as String? ?? '1970-01-01').split('T')[0],
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'recorded',
    );
  }
}
