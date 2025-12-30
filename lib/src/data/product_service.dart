// CHANGE PLAN:
// - products sorgularında olmayan is_available kolonu hata veriyor; select ve filtrelerden kaldıracağım.
// - price_tl kolonunu temel alıp mappingi Product.priceTl ile standardize edeceğim.
// - Option groups/items için Supabase fetch ekleyip şema uyumlu select listeleri kullanacağım.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network_helper.dart';
import '../models/models.dart';

class ProductService {
  static final _sb = Supabase.instance.client;

  static const _selectCols =
      'id,restaurant_id,category_id,is_popular,price_tl,name,description,image_url,created_at,updated_at';

  /// products tablosundan restoran urunlerini ceker
  /// Beklenen kolonlar: id, restaurant_id, category_id, is_popular, price_tl, name, description, image_url
  static Future<List<Product>> getProductsByRestaurant(String restaurantId) async {
    return NetworkHelper.executeWithRetry<List<Product>>(
      operation: () async {
        final res = await _sb
            .from('products')
            .select(_selectCols)
            .eq('restaurant_id', restaurantId)
            .order('is_popular', ascending: false)
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
            .select(_selectCols)
            .eq('id', productId)
            .maybeSingle();

        if (res == null) return null;
        final map = Map<String, dynamic>.from(res as Map);
        return Product.fromMap(map);
      },
    );
  }

  static Future<List<ProductOptionGroup>> getOptionGroups(String productId) async {
    return NetworkHelper.executeWithRetry<List<ProductOptionGroup>>(
      operation: () async {
        final groupRes = await _sb
            .from('option_groups')
            .select('id,product_id,title,type,required_one,max_select,sort_order')
            .eq('product_id', productId)
            .order('sort_order');

        final groupRows = (groupRes as List).cast<Map<String, dynamic>>();
        if (groupRows.isEmpty) return [];

        final groupIds = groupRows.map((g) => g['id']).where((id) => id != null).toList();
        final itemsRes = await _sb
            .from('option_items')
            .select('id,group_id,title,price_delta_tl,is_default,sort_order,is_active')
            .inFilter('group_id', groupIds)
            .order('sort_order');

        final itemRows = (itemsRes as List).cast<Map<String, dynamic>>();
        final itemsByGroup = <String, List<Map<String, dynamic>>>{};
        for (final m in itemRows) {
          if (m['is_active'] == false) continue;
          final gid = (m['group_id'] ?? '').toString();
          if (gid.isEmpty) continue;
          itemsByGroup.putIfAbsent(gid, () => []).add(m);
        }

        return groupRows.map((g) {
          final gid = g['id'].toString();
          final items = itemsByGroup[gid] ?? const [];
          return ProductOptionGroup.fromMap(group: g, items: items);
        }).toList();
      },
    );
  }
}
