import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  final List<Address> _addresses = [
    const Address(
      id: 'a1',
      title: 'Ev',
      city: 'İstanbul',
      district: 'Kadıköy',
      neighborhood: 'Moda',
      line: 'Moda Cd. No: 10 D: 3',
      note: '',
    ),
  ];

  List<Address> get addresses => List.unmodifiable(_addresses);

  Address get defaultAddress => _addresses.first;

  void addAddress(Address a) {
    _addresses.insert(0, a);
    notifyListeners();
  }
}
