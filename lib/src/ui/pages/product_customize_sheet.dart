// Bu sayfa artık kullanılmıyor; yeni özelleştirme sayfası `sheets/product_customize_sheet.dart` üzerinden sağlanmaktadır.

import 'package:flutter/material.dart';
import 'package:wellfud/src/ui/sheets/product_customize_sheet.dart' as sheets;
import '../../models/models.dart';

class ProductCustomizeSheet {
  static Future<void> addFromMenu({
    required BuildContext context,
    required Restaurant restaurant,
    required Product product,
  }) async {
    // Delegasyon: eski API'yi kullanan çağrılar yeni sheet'i açsın
    await sheets.ProductCustomizeSheet.open(context: context, restaurant: restaurant, product: product);
  }
}

