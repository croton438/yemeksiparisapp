import 'package:flutter/foundation.dart';

@immutable
class Restaurant {
  final String id;
  final String name;
  final String description; // ✅ ekli
  final String heroImageUrl;
  final int minOrderTl;
  final int minDeliveryMin;
  final int maxDeliveryMin;
  final double rating;

  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.heroImageUrl,
    required this.minOrderTl,
    required this.minDeliveryMin,
    required this.maxDeliveryMin,
    required this.rating,
  });

  String get eta => '$minDeliveryMin-$maxDeliveryMin dk';
  String get etaLabel => eta; // ✅ SettingsPage kırılmasın
}
