import 'package:flutter/material.dart';
import '../widgets/cart_sheet.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // ✅ arka plan açık kalmasın
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CartSheetBody(isModal: false),
      ),
    );
  }
}
