// CHANGE PLAN:
// - Product fiyat alanını priceTl + Supabase mapping ile standart tutacağım.
// - option_groups/option_items Supabase şemasına uygun fromMap ekleyip type/required/max_select alanlarını map edeceğim.
// - Var olan AddOn ve product alanlarını koruyacağım, extra field eklemeyeceğim.

import 'package:flutter/foundation.dart';
import 'enums.dart';

@immutable
class ProductOptionItem {
  final String id;
  final String title;
  final int extraPriceTl;
  final bool isDefault;

  const ProductOptionItem({
    required this.id,
    required this.title,
    required this.extraPriceTl,
    this.isDefault = false,
  });

  factory ProductOptionItem.fromMap(Map<String, dynamic> m) {
    final price = m['price_delta_tl'];
    final priceInt = price is int ? price : (price is num ? price.toInt() : 0);
    return ProductOptionItem(
      id: m['id'].toString(),
      title: (m['title'] ?? '').toString(),
      extraPriceTl: priceInt,
      isDefault: m['is_default'] == true,
    );
  }
}

@immutable
class ProductOptionGroup {
  final String id;
  final String title;
  final OptionGroupType type;
  final bool requiredOne;
  final int maxSelect;
  final List<ProductOptionItem> items;

  const ProductOptionGroup({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
    this.requiredOne = false,
    this.maxSelect = 0,
  });

  factory ProductOptionGroup.fromMap({
    required Map<String, dynamic> group,
    List<Map<String, dynamic>> items = const [],
  }) {
    final typeStr = (group['type'] ?? 'single').toString();
    final OptionGroupType type = typeStr.toLowerCase() == 'multi' ? OptionGroupType.multi : OptionGroupType.single;
    return ProductOptionGroup(
      id: group['id'].toString(),
      title: (group['title'] ?? '').toString(),
      type: type,
      requiredOne: group['required_one'] == true,
      maxSelect: (group['max_select'] is int) ? group['max_select'] as int : (group['max_select'] is num ? (group['max_select'] as num).toInt() : 0),
      items: items.map(ProductOptionItem.fromMap).toList(),
    );
  }
}

@immutable
class AddOn {
  final String id;
  final String title;
  final int priceTl;

  const AddOn({
    required this.id,
    required this.title,
    required this.priceTl,
  });
}

@immutable
class Product {
  final String id;
  final String restaurantId;
  final String categoryId;
  final String name;
  final String description;
  final String imageUrl;
  final int priceTl;
  final bool isPopular;
  final List<ProductOptionGroup> optionGroups;
  final List<AddOn> addOns;
  final int maxAddOn;

  const Product({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.priceTl,
    this.isPopular = false,
    this.optionGroups = const [],
    this.addOns = const [],
    this.maxAddOn = 0,
  });

  factory Product.fromMap(Map<String, dynamic> m) {
    final price = m['price_tl'];
    final priceInt = price is int ? price : (price is num ? price.toInt() : 0);
    return Product(
      id: m['id'].toString(),
      restaurantId: (m['restaurant_id'] ?? '').toString(),
      categoryId: (m['category_id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      imageUrl: (m['image_url'] ?? '').toString(),
      priceTl: priceInt,
      isPopular: m['is_popular'] == true,
      optionGroups: const [],
    );
  }
}
