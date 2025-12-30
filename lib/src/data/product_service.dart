// CHANGE PLAN:
// - products sorgularında olmayan is_available kolonu hata veriyor; select ve filtrelerden kaldıracağım.
// - price_tl kolonunu temel alıp mappingi Product.priceTl ile standardize edeceğim, mevcut retry akışını koruyacağım.
// - Ek kolon seçimi mevcut şema ile uyumlu kalacak; genel servis yapısını değiştirmeyeceğim.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/network_helper.dart';

class ProductService {
  static final _sb = Supabase.instance.client;

  /// products tablosundan restoran urunlerini ceker
  /// Beklenen kolonlar: id, restaurant_id, category_id, name, description, price_tl, image_url, is_popular
  static Future<List<Product>> getProductsByRestaurant(String restaurantId) async {
    return NetworkHelper.executeWithRetry<List<Product>>(
      operation: () async {
        final res = await _sb
            .from('products')
            .select('id,restaurant_id,category_id,name,description,price_tl,image_url,is_popular')
            .eq('restaurant_id', restaurantId)
            .order('name');

        final rows = (res as List).cast<Map<String, dynamic>>();

        return rows.map(Product.fromMap).toList();
      },
    );
  }

  /// Tek bir urun ID ile ceker
  static Future<Product?> getProductById(String productId) async {
    return NetworkHelper.executeWithRetry<Product?>(
      operation: () async {
        final res = await _sb
            .from('products')
            .select('id,restaurant_id,category_id,name,description,price_tl,image_url,is_popular')
            .eq('id', productId)
            .maybeSingle();

        if (res == null) return null;

        final m = res as Map<String, dynamic>;
        return Product.fromMap(m);
      },
    );
  }
}
