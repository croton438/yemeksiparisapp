import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/network_helper.dart';

class ProductService {
  static final _sb = Supabase.instance.client;

  /// products tablosundan restoran ürünlerini çeker
  /// Beklenen kolonlar: id, restaurant_id, name, description, price, image_url, is_available
  static Future<List<Product>> getProductsByRestaurant(String restaurantId) async {
    return NetworkHelper.executeWithRetry<List<Product>>(
      operation: () async {
        final res = await _sb
            .from('products')
            .select('id,restaurant_id,name,description,price,image_url,is_available')
            .eq('restaurant_id', restaurantId)
            .eq('is_available', true)
            .order('name');

        final rows = (res as List).cast<Map<String, dynamic>>();

      return rows.map((m) {
        final price = m['price'];
        final priceInt = price is int 
            ? price 
            : (price is num ? price.toInt() : 0);
        return Product(
          id: m['id'].toString(),
          restaurantId: m['restaurant_id'].toString(),
          categoryId: '', // TODO: category_id eklenecek
          name: (m['name'] ?? '').toString(),
          description: (m['description'] ?? '').toString(),
          imageUrl: (m['image_url'] ?? '').toString(),
          priceTl: priceInt,
          isPopular: false, // TODO: is_popular kolonu eklenecek
        );
      }).toList();
      },
    );
  }

  /// Tek bir ürünü ID ile çeker
  static Future<Product?> getProductById(String productId) async {
    return NetworkHelper.executeWithRetry<Product?>(
      operation: () async {
        final res = await _sb
            .from('products')
            .select('id,restaurant_id,name,description,price,image_url,is_available')
            .eq('id', productId)
            .eq('is_available', true)
            .maybeSingle();

        if (res == null) return null;

        final m = res as Map<String, dynamic>;
        final price = m['price'];
        final priceInt = price is int 
            ? price 
            : (price is num ? price.toInt() : 0);
        
        return Product(
          id: m['id'].toString(),
          restaurantId: m['restaurant_id'].toString(),
          categoryId: '',
          name: (m['name'] ?? '').toString(),
          description: (m['description'] ?? '').toString(),
          imageUrl: (m['image_url'] ?? '').toString(),
          priceTl: priceInt,
          isPopular: false,
        );
      },
    );
  }
}

