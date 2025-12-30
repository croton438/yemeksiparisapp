// CHANGE PLAN:
// - CartItem eklerken selections json'u da saklayacağım, mevcut fiyat/restaurant akışını bozmayacağım.
// - API imzasını minimal genişletip var olan çağrıları güncelleyeceğim.

import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CartStore extends ChangeNotifier {
  Restaurant? _restaurant;
  final List<CartItem> _items = [];

  bool _plasticCutlery = false;

  Restaurant? get restaurant => _restaurant;
  List<CartItem> get items => List.unmodifiable(_items);
  bool get plasticCutlery => _plasticCutlery;

  bool get isEmpty => _items.isEmpty;

  int get subtotalTl => _items.fold(0, (sum, it) => sum + it.lineTotalTl);
  int get deliveryFeeTl => _items.isEmpty ? 0 : 0;
  int get discountTl => 0;
  int get totalTl => subtotalTl + deliveryFeeTl - discountTl;

  bool get canCheckout {
    final r = _restaurant;
    if (r == null) return false;
    return totalTl >= r.minOrderTl && _items.isNotEmpty;
  }

  void togglePlasticCutlery(bool v) {
    _plasticCutlery = v;
    notifyListeners();
  }

  void addItem({
    required Restaurant restaurant,
    required Product product,
    required int quantity,
    Map<String, List<ProductOptionItem>> selectedOptions = const {},
    List<String> selectedAddOnIds = const [],
    Map<String, dynamic> selections = const {},
  }) {
    // restaurant set
    _restaurant ??= restaurant;

    // farklı restoran -> sepeti temizle (basit kural)
    if (_restaurant!.id != restaurant.id) {
      clear();
      _restaurant = restaurant;
    }

    final id = '${product.id}_${DateTime.now().millisecondsSinceEpoch}';
    _items.add(
      CartItem(
        id: id,
        product: product,
        quantity: quantity,
        selectedOptions: Map.of(selectedOptions),
        selectedAddOnIds: List.of(selectedAddOnIds),
        selections: Map.of(selections),
      ),
    );
    notifyListeners();
  }

  void setQuantity(String cartItemId, int q) {
    final idx = _items.indexWhere((x) => x.id == cartItemId);
    if (idx == -1) return;

    if (q <= 0) {
      _items.removeAt(idx);
    } else {
      final old = _items[idx];
      _items[idx] = CartItem(
        id: old.id,
        product: old.product,
        quantity: q,
        selectedOptions: old.selectedOptions,
        selectedAddOnIds: old.selectedAddOnIds,
        selections: old.selections,
      );
    }

    if (_items.isEmpty) _restaurant = null;
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((x) => x.id == cartItemId);
    if (_items.isEmpty) _restaurant = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _restaurant = null;
    _plasticCutlery = false;
    notifyListeners();
  }

  String buildWhatsappMessage({
    required Address address,
    required PaymentMethod paymentMethod,
  }) {
    final r = _restaurant;

    final b = StringBuffer();
    b.writeln('🛒 ${r?.name ?? "Sipariş"}');
    b.writeln('');

    for (final it in _items) {
      b.writeln('• ${it.product.name} x${it.quantity} = ${it.lineTotalTl} TL');
      final s = it.selectionsSummary;
      if (s.trim().isNotEmpty) b.writeln('  - $s');
    }

    b.writeln('');
    b.writeln('Ara toplam: $subtotalTl TL');
    b.writeln('Teslimat: ${deliveryFeeTl == 0 ? "Ücretsiz" : "$deliveryFeeTl TL"}');
    if (discountTl > 0) b.writeln('İndirim: -$discountTl TL');
    b.writeln('Toplam: $totalTl TL');

    b.writeln('');
    b.writeln('Ödeme: ${paymentMethod == PaymentMethod.cash ? "Nakit" : "Kredi Kartı"}');
    b.writeln('Çatal-bıçak: ${plasticCutlery ? "İstiyorum" : "Gerek yok"}');

    b.writeln('');
    b.writeln('📍 Teslimat Adresi');
    b.writeln(address.full);

    return b.toString();
  }
}
