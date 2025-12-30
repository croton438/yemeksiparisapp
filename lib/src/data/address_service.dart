import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address.dart';

class AddressService {
  AddressService._();
  static final instance = AddressService._();
  final _sb = Supabase.instance.client;

  Future<List<Address>> listAddresses() async {
    final dynamic res = await _sb.from('addresses').select().order('created_at', ascending: false);

    List<dynamic> data = [];
    if (res is List) {
      data = res;
    } else if (res is PostgrestResponse) {
      final dyn = res as dynamic;
      if (dyn.error != null) throw Exception(dyn.error);
      data = dyn.data as List<dynamic>;
    }

    return data.map((m) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(m);
      return Address(
        id: map['id'].toString(),
        title: map['title'] ?? 'Adres',
        city: map['city'] ?? '',
        district: map['district'] ?? '',
        neighborhood: map['neighborhood'] ?? '',
        line: map['line'] ?? '',
        note: map['note'] ?? '',
      );
    }).toList();
  }

  Future<Address> createAddress({required String title, required String city, required String district, required String neighborhood, required String line, String note = ''}) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('Unauthorized');
    final row = {
      'user_id': user.id,
      'title': title,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'line': line,
      'note': note,
    };
    final res = await _sb.from('addresses').insert(row).select().maybeSingle();
    if (res == null) throw Exception('Insert failed');
    final Map<String, dynamic> map = Map<String, dynamic>.from(res);
    return Address(
      id: map['id'].toString(),
      title: map['title'] ?? 'Adres',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      neighborhood: map['neighborhood'] ?? '',
      line: map['line'] ?? '',
      note: map['note'] ?? '',
    );
  }

  Future<void> updateAddress(Address a) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('Unauthorized');
    final row = {
      'title': a.title,
      'city': a.city,
      'district': a.district,
      'neighborhood': a.neighborhood,
      'line': a.line,
      'note': a.note,
    };
    await _sb.from('addresses').update(row).eq('id', a.id).select().maybeSingle();
  }

  Future<void> deleteAddress(String id) async {
    await _sb.from('addresses').delete().eq('id', id);
  }
}
