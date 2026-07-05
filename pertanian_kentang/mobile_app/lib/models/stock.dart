class StockTransaction {
  final int id;
  final String type;
  final int quantity;
  final String transactionDate;
  final String? notes;
  final String? reference;
  final String createdAt;

  StockTransaction({
    required this.id,
    required this.type,
    required this.quantity,
    required this.transactionDate,
    this.notes,
    this.reference,
    required this.createdAt,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'] as int,
      type: json['type'] as String,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      transactionDate: json['transaction_date'] as String? ?? '',
      notes: json['notes'] as String?,
      reference: json['reference'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class StockData {
  final int totalIncoming;
  final int totalOutgoing;
  final int currentStock;
  final List<StockTransaction> transactions;

  StockData({
    required this.totalIncoming,
    required this.totalOutgoing,
    required this.currentStock,
    required this.transactions,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      totalIncoming: int.tryParse(json['totalIncoming']?.toString() ?? '') ?? 0,
      totalOutgoing: int.tryParse(json['totalOutgoing']?.toString() ?? '') ?? 0,
      currentStock: int.tryParse(json['currentStock']?.toString() ?? '') ?? 0,
      transactions: (json['transactions'] as List?)
              ?.map((e) => StockTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
