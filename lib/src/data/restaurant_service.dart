import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/network_helper.dart';

class RestaurantService {
  static final _sb = Supabase.instance.client;

  /// restaurants tablosundan liste çeker.
  /// Beklenen kolonlar (snake_case):
  /// id, name, hero_image_url, min_order_tl, min_delivery_min, max_delivery_min, rating
  ///
  /// Opsiyonel (varsa): description, is_open, cuisine
  static Future<List<Restaurant>> getRestaurants() async {
    return NetworkHelper.executeWithRetry<List<Restaurant>>(
      operation: () async {
        final res = await _sb
            .from('restaurants')
            .select('id,name,hero_image_url,min_order_tl,min_delivery_min,max_delivery_min,rating,description,is_open,cuisine')
            .order('rating', ascending: false);

        final rows = (res as List).cast<Map<String, dynamic>>();

        return rows.map((m) {
          final desc = (m['description'] ?? '').toString();

          return Restaurant(
            id: m['id'].toString(),
            name: (m['name'] ?? '').toString(),
            heroImageUrl: (m['hero_image_url'] ?? '').toString(),
            minOrderTl: (m['min_order_tl'] ?? 0) as int,
            minDeliveryMin: (m['min_delivery_min'] ?? 0) as int,
            maxDeliveryMin: (m['max_delivery_min'] ?? 0) as int,
            rating: (m['rating'] is num) ? (m['rating'] as num).toDouble() : 0.0,
            description: desc,
          );
        }).toList();
      },
    );
  }
}
