import 'enums.dart';

enum OrderStatus { pending, confirmed, preparing, on_the_way, delivered, cancelled }

class Order {
  final String id;
  final String userId;
  final String restaurantId;
  final OrderStatus status;
  final int total;
  final Map<String, dynamic>? deliveryAddress;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.status,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> m) {
    return Order(
      id: m['id'].toString(),
      userId: m['user_id']?.toString() ?? '',
      restaurantId: m['restaurant_id']?.toString() ?? '',
      status: _parseStatus(m['status'] as String),
      total: (m['total'] as num?)?.toInt() ?? 0,
      deliveryAddress: m['delivery_address'] as Map<String, dynamic>?,
      paymentMethod: _parsePayment(m['payment_method'] as String),
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }

  static OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'on_the_way':
        return OrderStatus.on_the_way;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  static PaymentMethod _parsePayment(String s) {
    if (s == 'credit_card') return PaymentMethod.creditCard;
    return PaymentMethod.cash;
  }
}
