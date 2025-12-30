import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui_tokens.dart';
import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../state/cart_store.dart';
import '../pages/login_page.dart';
import '../../state/auth_store.dart';

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
                        initialValue: selectedAddress,
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
                      label: cart.canCheckout ? 'Sipariş Ver' : 'Minimum sepet tutarına ulaş',
                      onTap: cart.canCheckout
                          ? () async {
                              final addr = selectedAddress;
                              if (addr == null) {
                                _toast(context, 'Lütfen adres seç veya ekle.');
                                return;
                              }

                              final auth = context.read<AuthStore>();
                              if (!auth.isLoggedIn) {
                                // Navigate to login
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                                return;
                              }

                              // confirm
                              final localContext = context;

                              final ok = await showDialog<bool>(
                                context: localContext,
                                builder: (_) => AlertDialog(
                                  title: const Text('Siparişi Onayla'),
                                  content: Text('Toplam: ${cart.totalTl} TL\nAdres: ${addr.title}'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(localContext, false), child: const Text('İptal')),
                                    TextButton(onPressed: () => Navigator.pop(localContext, true), child: const Text('Onayla')),
                                  ],
                                ),
                              );

                              if (ok != true) return;

                              try {
                                final created = await app.createOrderFromCart(
                                  cart: cart,
                                  address: addr,
                                  paymentMethod: pm,
                                  plasticCutlery: cart.plasticCutlery,
                                  note: note.text.trim().isEmpty ? null : note.text.trim(),
                                );

                                if (!mounted) return;

                                cart.clear();
                                if (widget.isModal) Navigator.pop(localContext);

                                if (!mounted) return;

                                showDialog(
                                  context: localContext,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Sipariş Alındı'),
                                    content: Text('Siparişiniz alındı (ID: ${created.id}).'),
                                    actions: [TextButton(onPressed: () => Navigator.pop(localContext), child: const Text('Tamam'))],
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                _toast(localContext, 'Sipariş oluşturulurken hata: ${e.toString()}');
                              }
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
        color: Theme.of(context).colorScheme.primary.withAlpha((0.10 * 255).round()),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface.withAlpha((0.25 * 255).round()),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withAlpha((0.2 * 255).round()),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Ara toplam', '${cart.subtotalTl} TL'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.delivery_dining_rounded, size: 16, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Expanded(child: Text('Teslimat', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).hintColor))),
              Text(
                cart.deliveryFeeTl == 0 ? 'Ücretsiz' : '${cart.deliveryFeeTl} TL',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: cart.deliveryFeeTl == 0 ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
          if (cart.discountTl > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_offer_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(child: Text('İndirim', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary))),
                Text('-${cart.discountTl} TL', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ],
          const Divider(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).round()),
            ),
            child: Row(
              children: [
                Expanded(child: Text('Toplam', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                Text('${cart.totalTl} TL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
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
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor.withAlpha((0.2 * 255).round()),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: enabled ? 8 : 0,
          shadowColor: enabled ? Theme.of(context).colorScheme.primary.withAlpha((0.4 * 255).round()) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (enabled) ...[
              const Icon(Icons.chat_rounded, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
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

class CartLine extends StatefulWidget {
  final CartItem item;
  const CartLine({super.key, required this.item});

  @override
  State<CartLine> createState() => _CartLineState();
}

class _CartLineState extends State<CartLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartStore>();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).colorScheme.surface.withAlpha((0.25 * 255).round()),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withAlpha((0.15 * 255).round()),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                widget.item.product.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Theme.of(context).colorScheme.surface,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.product.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  if (widget.item.selectionsSummary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
                      ),
                      child: Text(
                        widget.item.selectionsSummary,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context).colorScheme.surface.withAlpha((0.3 * 255).round()),
                        ),
                        child: Text('${widget.item.unitPriceTl} TL (adet)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).round()),
                        ),
                        child: Text('${widget.item.lineTotalTl} TL', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    _controller.forward().then((_) => _controller.reverse());
                    cart.removeItem(widget.item.id);
                  },
                  icon: const Icon(Icons.close_rounded),
                  color: Theme.of(context).hintColor,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface.withAlpha((0.3 * 255).round()),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _qtyBtn(context, icon: Icons.remove, onTap: () => cart.setQuantity(widget.item.id, widget.item.quantity - 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${widget.item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      _qtyBtn(context, icon: Icons.add, onTap: () => cart.setQuantity(widget.item.id, widget.item.quantity + 1)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).round()),
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
