class DashboardData {
  final int totalStok;
  final int totalPenjualan;
  final int totalBiaya;
  final int targetPanen;
  final List<HarvestSummary> harvests;
  final List<TransactionSummary> transactions;
  final ProfitLoss profitLoss;
  final List<MonthlyStat> monthlyStats;

  DashboardData({
    required this.totalStok,
    required this.totalPenjualan,
    required this.totalBiaya,
    required this.targetPanen,
    required this.harvests,
    required this.transactions,
    required this.profitLoss,
    required this.monthlyStats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalStok: json['totalStok'] as int? ?? 0,
      totalPenjualan: json['totalPenjualan'] as int? ?? 0,
      totalBiaya: json['totalBiaya'] as int? ?? 0,
      targetPanen: json['targetPanen'] as int? ?? 0,
      harvests: (json['harvests'] as List?)
              ?.map((e) => HarvestSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      transactions: (json['transactions'] as List?)
              ?.map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      profitLoss: ProfitLoss.fromJson(json['profitLoss'] as Map<String, dynamic>? ?? {}),
      monthlyStats: (json['monthlyStats'] as List?)
              ?.map((e) => MonthlyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MonthlyStat {
  final String label;
  final double harvest;
  final double sales;

  MonthlyStat({
    required this.label,
    required this.harvest,
    required this.sales,
  });

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    return MonthlyStat(
      label: json['label'] as String? ?? '',
      harvest: (json['harvest'] as num?)?.toDouble() ?? 0.0,
      sales: (json['sales'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HarvestSummary {
  final int id;
  final String seasonName;
  final int quantity;
  final String status;

  HarvestSummary({
    required this.id,
    required this.seasonName,
    required this.quantity,
    required this.status,
  });

  factory HarvestSummary.fromJson(Map<String, dynamic> json) {
    return HarvestSummary(
      id: json['id'] as int,
      seasonName: json['season_name'] as String? ?? 'N/A',
      quantity: json['quantity'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class TransactionSummary {
  final int id;
  final String type;
  final int quantity;
  final String createdAt;

  TransactionSummary({
    required this.id,
    required this.type,
    required this.quantity,
    required this.createdAt,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'unknown',
      quantity: json['quantity'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ProfitLoss {
  final int revenue;
  final int cost;
  final int profit;

  ProfitLoss({
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  factory ProfitLoss.fromJson(Map<String, dynamic> json) {
    return ProfitLoss(
      revenue: json['revenue'] as int? ?? 0,
      cost: json['cost'] as int? ?? 0,
      profit: json['profit'] as int? ?? 0,
    );
  }
}
