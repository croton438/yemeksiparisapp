// CHANGE PLAN:
// - CartItem içine selections json'u ekleyip option seçimlerini saklayacağım.
// - Mevcut selectedOptions ve toplam hesaplarını koruyacağım.
// - Var olan constructor alanlarını bozmayacağım.

import 'package:flutter/foundation.dart';
import 'product.dart';

@immutable
class CartItem {
  final String id;
  final Product product;
  final int quantity;

  /// groupId -> seçilen option item’lar
  final Map<String, List<ProductOptionItem>> selectedOptions;

  /// AddOn id listesi
  final List<String> selectedAddOnIds;

  /// Seçimlerin json özetleri (checkout için)
  final Map<String, dynamic> selections;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedOptions = const {},
    this.selectedAddOnIds = const [],
    this.selections = const {},
  });

  /// Tek ürün fiyatı (opsiyon + addon dahil)
  int get unitPriceTl {
    var total = product.priceTl;

    for (final entry in selectedOptions.entries) {
      for (final it in entry.value) {
        total += it.extraPriceTl;
      }
    }

    for (final id in selectedAddOnIds) {
      final a = product.addOns.firstWhere(
        (x) => x.id == id,
        orElse: () => const AddOn(id: '_', title: '', priceTl: 0),
      );
      total += a.priceTl;
    }

    return total;
  }

  /// Satır toplamı
  int get lineTotalTl => unitPriceTl * quantity;

  /// UI için özet
  String get selectionsSummary {
    final parts = <String>[];

    for (final entry in selectedOptions.entries) {
      if (entry.value.isEmpty) continue;
      parts.add(entry.value.map((e) => e.title).join(', '));
    }

    if (selectedAddOnIds.isNotEmpty) {
      final addOnTitles = selectedAddOnIds.map((id) {
        final a = product.addOns.firstWhere(
          (x) => x.id == id,
          orElse: () => const AddOn(id: '_', title: '', priceTl: 0),
        );
        return a.title;
      }).where((t) => t.trim().isNotEmpty).toList();

      if (addOnTitles.isNotEmpty) {
        parts.add('Ekstra: ${addOnTitles.join(', ')}');
      }
    }

    return parts.isEmpty ? 'Seçim yok' : parts.join(' • ');
  }
}
