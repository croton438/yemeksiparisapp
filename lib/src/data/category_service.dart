import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/network_helper.dart';

class CategoryService {
  static final _sb = Supabase.instance.client;

  /// categories tablosundan restoran kategorilerini çeker
  /// Beklenen kolonlar: id, restaurant_id, name (veya title)
  static Future<List<Category>> getCategoriesByRestaurant(String restaurantId) async {
    try {
      return await NetworkHelper.executeWithRetry<List<Category>>(
        operation: () async {
          // Önce categories tablosu var mı kontrol et, yoksa products'tan unique category_id'leri çek
          final res = await _sb
              .from('categories')
              .select('id,restaurant_id,name')
              .eq('restaurant_id', restaurantId)
              .order('name');

          final rows = (res as List).cast<Map<String, dynamic>>();

          if (rows.isEmpty) {
            // Categories tablosu yoksa, products'tan kategori çıkar
            return _getCategoriesFromProducts(restaurantId);
          }

          return rows.map((m) {
            return Category(
              id: m['id'].toString(),
              restaurantId: m['restaurant_id'].toString(),
              title: (m['name'] ?? m['title'] ?? 'Diğer').toString(),
            );
          }).toList();
        },
      );
    } catch (e) {
      // Categories tablosu yoksa products'tan çıkar
      return _getCategoriesFromProducts(restaurantId);
    }
  }

  static Future<List<Category>> _getCategoriesFromProducts(String restaurantId) async {
    try {
      final res = await _sb
          .from('products')
          .select('category_id,category_name')
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true);

      final rows = (res as List).cast<Map<String, dynamic>>();
      final categoryMap = <String, String>{};

      for (final m in rows) {
        final catId = (m['category_id'] ?? '').toString();
        final catName = (m['category_name'] ?? 'Diğer').toString();
        if (catId.isNotEmpty) {
          categoryMap[catId] = catName;
        }
      }

      if (categoryMap.isEmpty) {
        // Hiç kategori yoksa varsayılan bir kategori döndür
        return [
          Category(
            id: '${restaurantId}_default',
            restaurantId: restaurantId,
            title: 'Tüm Ürünler',
          ),
        ];
      }

      return categoryMap.entries.map((e) {
        return Category(
          id: e.key,
          restaurantId: restaurantId,
          title: e.value,
        );
      }).toList();
    } catch (e) {
      // Hata durumunda varsayılan kategori
      return [
        Category(
          id: '${restaurantId}_default',
          restaurantId: restaurantId,
          title: 'Tüm Ürünler',
        ),
      ];
    }
  }
}

