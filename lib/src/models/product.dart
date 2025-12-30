// CHANGE PLAN:
// - Product fiyat alanını priceTl olarak koruyup map/JSON girişlerini price_tl'den okumak için factory ekleyeceğim.
// - is_available alanı şemada yok; modele eklemeyeceğim, mevcut alanların davranışını değiştirmeyeceğim.
// - Opsiyon grupları ve addon listelerini aynen bırakacağım.

import 'package:flutter/foundation.dart';
import 'enums.dart';

@immutable
class ProductOptionItem {
  final String id;
  final String title;
  final int extraPriceTl;

  const ProductOptionItem({
    required this.id,
    required this.title,
    required this.extraPriceTl,
  });
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
    );
  }
}
