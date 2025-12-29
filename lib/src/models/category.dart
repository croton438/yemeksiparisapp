import 'package:flutter/foundation.dart';

@immutable
class Category {
  final String id;
  final String restaurantId;
  final String title;

  const Category({
    required this.id,
    required this.restaurantId,
    required this.title,
  });
}
