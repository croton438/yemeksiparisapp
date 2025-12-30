import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../data/address_service.dart';
import '../data/orders_service.dart';
import '../state/cart_store.dart';
import '../services/auth_service.dart';

class AppStore extends ChangeNotifier {
  final List<Address> _addresses = [];
  final List<Order> _orders = [];
  bool _loading = false;
  bool _ordersLoading = false;

  List<Address> get addresses => List.unmodifiable(_addresses);
  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _loading;
  bool get ordersLoading => _ordersLoading;

  Address? get defaultAddress => _addresses.isNotEmpty ? _addresses.first : null;

  final _svc = AddressService.instance;
  final _ordersSvc = OrdersService.instance;
  StreamSubscription<dynamic>? _authSub;

  AppStore() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((ev) {
      final session = ev?.session;
      if (session != null && session.user != null) {
        loadAddresses();
        loadOrders();
      } else {
        _addresses.clear();
        _orders.clear();
        notifyListeners();
      }
    });
  }

  Future<void> loadAddresses() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _svc.listAddresses();
      _addresses
        ..clear()
        ..addAll(list);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    _ordersLoading = true;
    notifyListeners();
    try {
      final list = await _ordersSvc.listOrdersForUser(user.id);
      _orders
        ..clear()
        ..addAll(list);
    } finally {
      _ordersLoading = false;
      notifyListeners();
    }
  }

  /// Creates an order from a cart. Returns created Order.
  Future<Order> createOrderFromCart({
    required CartStore cart,
    required Address address,
    required PaymentMethod paymentMethod,
    bool plasticCutlery = false,
    String? note,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final items = cart.items.map((it) {
      return {
        'product_id': it.product.id,
        'product_name': it.product.name,
        'quantity': it.quantity,
        'price_tl': it.unitPriceTl,
        'selected_options': it.selectedOptions.map((k, v) => MapEntry(k, v.map((e) => e.id).toList())),
        'selected_addon_ids': it.selectedAddOnIds,
      };
    }).toList();

    final pm = paymentMethod == PaymentMethod.creditCard ? 'credit_card' : 'cash';

    final addrMap = {
      'id': address.id,
      'title': address.title,
      'city': address.city,
      'district': address.district,
      'neighborhood': address.neighborhood,
      'line': address.line,
      'note': address.note,
    };

    final order = await _ordersSvc.createOrder(
      userId: user.id,
      restaurantId: cart.restaurant!.id,
      total: cart.totalTl,
      deliveryAddress: addrMap,
      paymentMethod: pm,
      items: items.map((m) {
        // adapt to DB schema: product_id, name, unit_price, quantity, selections
        return {
          'product_id': m['product_id'],
          'name': m['product_name'],
          'unit_price': m['price_tl'],
          'quantity': m['quantity'],
          'selections': m['selected_options'],
        };
      }).toList(),
      note: note,
    );

    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  Future<void> addAddress(Address a) async {
    // try to create on server first (if authorized), otherwise add local
    try {
      final created = await _svc.createAddress(
        title: a.title,
        city: a.city,
        district: a.district,
        neighborhood: a.neighborhood,
        line: a.line,
        note: a.note,
      );
      _addresses.insert(0, created);
      notifyListeners();
    } catch (_) {
      _addresses.insert(0, a);
      notifyListeners();
    }
  }

  Future<void> updateAddress(Address a) async {
    try {
      await _svc.updateAddress(a);
      final idx = _addresses.indexWhere((e) => e.id == a.id);
      if (idx != -1) _addresses[idx] = a;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _svc.deleteAddress(id);
      _addresses.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
