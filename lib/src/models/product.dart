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
}
