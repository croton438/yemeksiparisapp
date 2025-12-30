import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class OrdersService {
  OrdersService._();
  static final instance = OrdersService._();

  final _sb = Supabase.instance.client;

  Future<Order> createOrder({
    required String userId,
    required String restaurantId,
    required int total,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod, // 'cash' or 'credit_card'
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final resp = await _sb.from('orders').insert({
      'user_id': userId,
      'restaurant_id': restaurantId,
      'status': 'pending',
      'total': total,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'note': note,
    }).select().maybeSingle();

    if (resp == null || resp is! Map<String, dynamic>) {
      throw Exception('Failed creating order');
    }

    final orderId = resp['id'].toString();

    // insert order items
    for (final it in items) {
      final m = Map<String, dynamic>.from(it);
      m['order_id'] = orderId;
      await _sb.from('order_items').insert(m);
    }

    // re-fetch order
    final o = await _sb.from('orders').select().eq('id', orderId).maybeSingle();
    if (o == null || o is! Map<String, dynamic>) throw Exception('Order created but cannot fetch');
    return Order.fromMap(o);
  }

  Future<List<Order>> listOrdersForUser(String userId) async {
    final res = await _sb.from('orders').select().eq('user_id', userId).order('created_at', ascending: false);
    if (res is List) return res.map((e) => Order.fromMap(e as Map<String, dynamic>)).toList();
    return [];
  }
}
