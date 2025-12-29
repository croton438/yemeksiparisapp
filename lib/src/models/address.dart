import 'package:flutter/foundation.dart';

@immutable
class Address {
  final String id;
  final String title;
  final String city;
  final String district;
  final String neighborhood;
  final String line;
  final String note;

  const Address({
    required this.id,
    required this.title,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.line,
    this.note = '',
  });

  String get full =>
      '$city / $district / $neighborhood\n$line${note.trim().isEmpty ? '' : '\nNot: $note'}';
}
