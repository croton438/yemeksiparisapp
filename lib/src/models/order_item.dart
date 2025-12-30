class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final int priceTl;
  final Map<String, dynamic>? selectedOptions;
  final List<String>? selectedAddOnIds;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceTl,
    this.selectedOptions,
    this.selectedAddOnIds,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) {
    return OrderItem(
      id: m['id'].toString(),
      orderId: m['order_id'].toString(),
      productId: m['product_id'].toString(),
      productName: m['product_name'] as String? ?? '',
      quantity: m['quantity'] as int,
      priceTl: m['price_tl'] as int,
      selectedOptions: m['selected_options'] as Map<String, dynamic>?,
      selectedAddOnIds: (m['selected_addon_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}
