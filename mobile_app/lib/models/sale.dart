class Sale {
  final int id;
  final int quantity;
  final int pricePerUnit;
  final int totalPrice;
  final String saleDate;
  final String buyerName;
  final String? buyerPhone;
  final String? notes;
  final String status;

  Sale({
    required this.id,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.saleDate,
    required this.buyerName,
    this.buyerPhone,
    this.notes,
    required this.status,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse(json['quantity']?.toString() ?? '') ?? 
                double.tryParse(json['weight_kg']?.toString() ?? '')?.round() ?? 0;
                
    final price = int.tryParse(json['price_per_unit']?.toString() ?? '') ?? 
                  double.tryParse(json['price_per_kg']?.toString() ?? '')?.round() ?? 0;
                  
    final total = int.tryParse(json['total_price']?.toString() ?? '') ?? 
                  double.tryParse(json['total']?.toString() ?? '')?.round() ?? 0;
                  
    final date = json['sale_date'] as String? ?? json['date'] as String? ?? '1970-01-01';
    
    String statusVal = json['status'] as String? ?? '';
    if (statusVal.isEmpty) {
      final paymentStatus = json['payment_status'] as String? ?? '';
      statusVal = (paymentStatus == 'paid') ? 'completed' : 'pending';
    }
    if (statusVal.isEmpty) statusVal = 'completed';

    return Sale(
      id: json['id'] as int,
      quantity: qty,
      pricePerUnit: price,
      totalPrice: total,
      saleDate: date.split('T')[0],
      buyerName: json['buyer_name'] as String? ?? '',
      buyerPhone: json['buyer_phone'] as String?,
      notes: json['notes'] as String?,
      status: statusVal,
    );
  }
}
