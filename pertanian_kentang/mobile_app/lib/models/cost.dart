class Cost {
  final int id;
  final int? seasonId;
  final String seasonName;
  final String category;
  final double amount;
  final String date;
  final String notes;

  Cost({
    required this.id,
    this.seasonId,
    required this.seasonName,
    required this.category,
    required this.amount,
    required this.date,
    required this.notes,
  });

  factory Cost.fromJson(Map<String, dynamic> json) {
    String name = 'N/A';
    if (json['season'] != null && json['season'] is Map) {
      name = json['season']['name'] as String? ?? 'N/A';
    }
    
    return Cost(
      id: json['id'] as int,
      seasonId: int.tryParse(json['season_id']?.toString() ?? ''),
      seasonName: name,
      category: json['category'] as String? ?? 'other',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      date: json['date'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}
