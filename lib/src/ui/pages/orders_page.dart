import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../state/cart_store.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: cart.isEmpty ? const _EmptyCart() : const _CartInline(),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text('Sepet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.35),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sepetin boş', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'Restoranlardan ürün ekleyince burada direkt gözükecek.',
                style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartInline extends StatefulWidget {
  const _CartInline();

  @override
  State<_CartInline> createState() => _CartInlineState();
}

class _CartInlineState extends State<_CartInline> {
  PaymentMethod pm = PaymentMethod.cash;
  Address? selectedAddress;

  final city = TextEditingController();
  final district = TextEditingController();
  final neighborhood = TextEditingController();
  final line = TextEditingController();

  @override
  void dispose() {
    city.dispose();
    district.dispose();
    neighborhood.dispose();
    line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final app = context.watch<AppStore>();
    final r = cart.restaurant;

    selectedAddress ??= app.defaultAddress;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Sepet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            Text('${cart.totalTl} TL', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 10),

        Expanded(
          child: ListView(
            children: [
              if (r != null) _minOrderBanner(context, cart),

              const SizedBox(height: 10),

              ...cart.items.map(
                (it) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CartLine(item: it),
                ),
              ),

              const SizedBox(height: 10),

              _sectionTitle('Teslimat adresi'),
              const SizedBox(height: 8),
              if (app.addresses.isNotEmpty)
                DropdownButtonFormField<Address>(
                  value: selectedAddress,
                  items: app.addresses
                      .map((a) => DropdownMenuItem(value: a, child: Text(a.title, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (a) => setState(() => selectedAddress = a),
                ),
              const SizedBox(height: 10),

              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Yeni adres ekle', style: TextStyle(fontWeight: FontWeight.w800)),
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: city, decoration: const InputDecoration(labelText: 'İl'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: district, decoration: const InputDecoration(labelText: 'İlçe'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: neighborhood, decoration: const InputDecoration(labelText: 'Mahalle')),
                  const SizedBox(height: 10),
                  TextField(controller: line, decoration: const InputDecoration(labelText: 'Açık adres')),
                  const SizedBox(height: 10),
                  _ghostButton(
                    context,
                    label: 'Adresi Kaydet',
                    onTap: () {
                      if (city.text.trim().isEmpty ||
                          district.text.trim().isEmpty ||
                          neighborhood.text.trim().isEmpty ||
                          line.text.trim().isEmpty) {
                        _toast(context, 'Lütfen tüm adres alanlarını doldur.');
                        return;
                      }

                      final a = Address(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: 'Yeni Adres',
                        city: city.text.trim(),
                        district: district.text.trim(),
                        neighborhood: neighborhood.text.trim(),
                        line: line.text.trim(),
                        note: '',
                      );

                      app.addAddress(a);
                      setState(() => selectedAddress = a);

                      city.clear();
                      district.clear();
                      neighborhood.clear();
                      line.clear();

                      _toast(context, 'Adres eklendi.');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),
              _sectionTitle('Ödeme yöntemi'),
              const SizedBox(height: 8),
              _paymentPicker(
                value: pm,
                onChanged: (v) => setState(() => pm = v),
              ),

              const SizedBox(height: 10),
              SwitchListTile(
                value: cart.plasticCutlery,
                onChanged: cart.togglePlasticCutlery,
                contentPadding: EdgeInsets.zero,
                title: const Text('Plastik çatal-bıçak istiyorum', style: TextStyle(fontWeight: FontWeight.w700)),
              ),

              const SizedBox(height: 8),
              _totals(context, cart),

              const SizedBox(height: 12),
              _primaryButton(
                context,
                label: cart.canCheckout ? 'WhatsApp ile Sipariş Ver' : 'Minimum sepet tutarına ulaş',
                onTap: cart.canCheckout
                    ? () {
                        final addr = selectedAddress;
                        if (addr == null) {
                          _toast(context, 'Lütfen adres seç veya ekle.');
                          return;
                        }

                        final msg = cart.buildWhatsappMessage(address: addr, paymentMethod: pm);

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('WhatsApp Mesajı'),
                            content: SingleChildScrollView(child: Text(msg)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
                              TextButton(
                                onPressed: () {
                                  cart.clear();
                                  Navigator.pop(context);
                                  _toast(context, 'Sepet temizlendi (test).');
                                },
                                child: const Text('Test: Sepeti Temizle'),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _minOrderBanner(BuildContext context, CartStore cart) {
    final r = cart.restaurant;
    if (r == null) return const SizedBox.shrink();

    final remaining = (r.minOrderTl - cart.totalTl);
    if (remaining <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        'Min. sepet ${r.minOrderTl} TL • ${remaining} TL daha ekle',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _sectionTitle(String s) => Align(
        alignment: Alignment.centerLeft,
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w900)),
      );

  Widget _paymentPicker({
    required PaymentMethod value,
    required ValueChanged<PaymentMethod> onChanged,
  }) {
    return Column(
      children: [
        RadioListTile<PaymentMethod>(
          value: PaymentMethod.cash,
          groupValue: value,
          onChanged: (v) => onChanged(v!),
          title: const Text('Nakit', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        RadioListTile<PaymentMethod>(
          value: PaymentMethod.creditCard,
          groupValue: value,
          onChanged: (v) => onChanged(v!),
          title: const Text('Kredi Kartı', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _totals(BuildContext context, CartStore cart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
      ),
      child: Column(
        children: [
          _row('Ara toplam', '${cart.subtotalTl} TL'),
          const SizedBox(height: 6),
          _row('Teslimat', cart.deliveryFeeTl == 0 ? 'Ücretsiz' : '${cart.deliveryFeeTl} TL'),
          const SizedBox(height: 6),
          _row('İndirim', cart.discountTl == 0 ? '—' : '-${cart.discountTl} TL'),
          const Divider(height: 18),
          _row('Toplam', '${cart.totalTl} TL', bold: true),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool bold = false}) {
    return Row(
      children: [
        Expanded(child: Text(l, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700))),
        Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
      ],
    );
  }

  static Widget _primaryButton(BuildContext context, {required String label, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor.withOpacity(0.2),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  static Widget _ghostButton(BuildContext context, {required String label, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartStore>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.35),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              item.product.imageUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                color: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(item.selectionsSummary, style: TextStyle(color: Theme.of(context).hintColor)),
                const SizedBox(height: 6),
                Text('${item.unitPriceTl} TL (adet)', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => cart.removeItem(item.id),
                icon: const Icon(Icons.close),
              ),
              Row(
                children: [
                  _qtyBtn(context, icon: Icons.remove, onTap: () => cart.setQuantity(item.id, item.quantity - 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  _qtyBtn(context, icon: Icons.add, onTap: () => cart.setQuantity(item.id, item.quantity + 1)),
                ],
              ),
              const SizedBox(height: 6),
              Text('${item.lineTotalTl} TL', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
