import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui_tokens.dart';
import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../state/cart_store.dart';

class CartSheet {
  static Future<void> open(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent, // ✅ beyaz sheet arkasını öldürür
      builder: (_) => const CartSheetBody(isModal: true),
    );
  }
}

/// ✅ Hem Sepet sayfasında hem modal bottom-sheet’te kullanılabilir
class CartSheetBody extends StatefulWidget {
  final bool isModal;
  const CartSheetBody({super.key, required this.isModal});

  @override
  State<CartSheetBody> createState() => _CartSheetBodyState();
}

class _CartSheetBodyState extends State<CartSheetBody> {
  PaymentMethod pm = PaymentMethod.cash;
  Address? selectedAddress;

  final city = TextEditingController();
  final district = TextEditingController();
  final neighborhood = TextEditingController();
  final line = TextEditingController();
  final note = TextEditingController(); // ✅ hata buydu, şimdi var

  @override
  void dispose() {
    city.dispose();
    district.dispose();
    neighborhood.dispose();
    line.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final app = context.watch<AppStore>();
    final r = cart.restaurant;

    selectedAddress ??= app.defaultAddress;

    // ✅ Modal ise yüksekliği sabitleyip overflow riskini azaltıyoruz
    final maxH = MediaQuery.of(context).size.height * (widget.isModal ? 0.86 : 1.0);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Container(
            margin: widget.isModal ? const EdgeInsets.all(12) : EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.isModal ? 22 : 0),
              color: Theme.of(context).scaffoldBackgroundColor, // ✅ beyazlığı engeller
              border: widget.isModal ? Border.all(color: Theme.of(context).dividerColor) : null,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: UiTokens.padMd,
                right: UiTokens.padMd,
                bottom: (widget.isModal ? MediaQuery.of(context).viewInsets.bottom : 0) + UiTokens.padMd,
                top: UiTokens.pad,
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r?.name ?? 'Sepet',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${cart.totalTl} TL', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (cart.isEmpty) ...[
                    const SizedBox(height: 14),
                    const Icon(Icons.shopping_bag_outlined, size: 34),
                    const SizedBox(height: 10),
                    const Text('Sepetin boş', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    _primaryButton(
                      context,
                      label: widget.isModal ? 'Kapat' : 'Alışverişe Dön',
                      onTap: widget.isModal ? () => Navigator.pop(context) : null,
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    _minOrderBanner(context, cart),
                    const SizedBox(height: 10),

                    // ✅ Listeyi Flexible yaptık, overflow’u bitirir
                    Flexible(
                      child: ListView.separated(
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => CartLine(item: cart.items[i]),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Adres
                    _sectionTitle('Teslimat adresi'),
                    const SizedBox(height: 8),
                    if (app.addresses.isNotEmpty)
                      DropdownButtonFormField<Address>(
                        value: selectedAddress,
                        items: app.addresses
                            .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a.title, overflow: TextOverflow.ellipsis),
                                ))
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
                        TextField(controller: note, decoration: const InputDecoration(labelText: 'Not (opsiyonel)')),
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
                              note: note.text.trim(),
                            );

                            app.addAddress(a);
                            setState(() => selectedAddress = a);

                            city.clear();
                            district.clear();
                            neighborhood.clear();
                            line.clear();
                            note.clear();

                            _toast(context, 'Adres eklendi.');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Ödeme
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
                                        if (widget.isModal) Navigator.pop(context);
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
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
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
        color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
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

class CartLine extends StatelessWidget {
  final CartItem item;
  const CartLine({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartStore>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
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
