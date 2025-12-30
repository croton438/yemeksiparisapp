import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui_tokens.dart';
import '../../models/models.dart';
import '../../state/cart_store.dart';
import '../widgets/cached_image.dart';

class ProductCustomizeSheet {
  static Future<void> open({
    required BuildContext context,
    required Restaurant restaurant,
    required Product product,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Body(restaurant: restaurant, product: product),
    );
  }
}

class _Body extends StatefulWidget {
  final Restaurant restaurant;
  final Product product;

  const _Body({required this.restaurant, required this.product});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final Map<String, String> selectedOptions = {};
  final Set<String> selectedAddOns = {};
  final Set<String> removedIngredients = {};

  int qty = 1;

  @override
  void initState() {
    super.initState();

    // requiredOne olan gruplarda default ilk seçeneği seç
    for (final g in widget.product.optionGroups) {
      if (g.requiredOne && g.items.isNotEmpty) {
        selectedOptions[g.id] = g.items.first.id;
      }
    }
  }

  bool get _isSelectionValid {
    for (final g in widget.product.optionGroups) {
      if (g.requiredOne) {
        final sel = selectedOptions[g.id];
        if (sel == null || sel.isEmpty) return false;
      }
    }
    return true;
  }

  int get _unitTotalTl {
    int sum = widget.product.priceTl;

    for (final g in widget.product.optionGroups) {
      final sel = selectedOptions[g.id];
      if (sel != null) {
        final opt = g.items.firstWhere((e) => e.id == sel);
        sum += opt.extraPriceTl;
      }
    }

    for (final id in selectedAddOns) {
      final a = widget.product.addOns.firstWhere((x) => x.id == id);
      sum += a.priceTl;
    }

    return sum;
  }

  int get _totalTl => _unitTotalTl * qty;

  List<String> get _ingredientCandidates {
    // Açıklamadan otomatik çıkarılabilir liste üret
    // Örn: "Dana köfte, cheddar, marul, domates, özel sos."
    final raw = widget.product.description
        .replaceAll('\n', ' ')
        .replaceAll('.', '')
        .replaceAll('•', ',')
        .trim();

    if (raw.isEmpty) return const [];

    final parts = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // Çok genel/boş şeyleri filtrele
    const banned = {
      'özel sos',
      'imza sos',
      'sos',
      'taze malzeme',
      'günlük taze',
      'bol et',
      'sıcak servis',
    };

    final cleaned = <String>[];
    for (final p in parts) {
      final low = p.toLowerCase();
      if (low.length < 3) continue;
      if (banned.contains(low)) continue;
      // "Dana köfte" gibi kalsın ama "dana" tek başına olursa alma
      cleaned.add(_capitalize(p));
    }

    // duplicate temizle
    final set = <String>{};
    final out = <String>[];
    for (final x in cleaned) {
      final key = x.toLowerCase();
      if (set.add(key)) out.add(x);
    }

    // Çok azsa hiç gösterme
    if (out.length < 2) return const [];
    return out.take(10).toList(); // aşırı uzamasın
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.55,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              left: UiTokens.padMd,
              right: UiTokens.padMd,
              bottom: MediaQuery.of(context).viewInsets.bottom + UiTokens.padMd,
              top: UiTokens.pad,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    // HEADER
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                          Expanded(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _Pill(
                            text: '${p.priceTl},99 TL',
                            bg: Theme.of(context).colorScheme.surface.withAlpha((0.22 * 255).round()),
                          ),
                        ],
                      ),
                    ),

                    // BODY
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                        children: [
                          // HERO (border yok)
                          _SoftCard(
                            radius: 18,
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: CachedImg(
                                url: p.imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 1200,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (p.description.trim().isNotEmpty) ...[
                            Text(
                              p.description,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ✅ ÇIKARILACAKLAR (otomatik)
                          if (_ingredientCandidates.isNotEmpty) ...[
                            Row(
                              children: [
                                const Text('Çıkarılacaklar', style: TextStyle(fontWeight: FontWeight.w900)),
                                const Spacer(),
                                Text(
                                  removedIngredients.isEmpty ? 'İsteğe bağlı' : '${removedIngredients.length} seçildi',
                                  style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _SoftCard(
                              radius: 18,
                              padding: const EdgeInsets.all(10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _ingredientCandidates.map((ing) {
                                  final selected = removedIngredients.contains(ing);
                                  return _ChipToggle(
                                    label: ing,
                                    selected: selected,
                                    onTap: () => setState(() {
                                      if (selected) {
                                        removedIngredients.remove(ing);
                                      } else {
                                        removedIngredients.add(ing);
                                      }
                                    }),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // OPTION GROUPS
                          if (p.optionGroups.isNotEmpty) ...[
                            Row(
                              children: [
                                const Text('Özelleştir', style: TextStyle(fontWeight: FontWeight.w900)),
                                const Spacer(),
                                Text(
                                  'Zorunlu seçimler varsa tamamlamalısın.',
                                  style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final g in p.optionGroups) ...[
                              _SoftCard(
                                radius: 18,
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(g.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                                        const Spacer(),
                                        if (g.requiredOne) _Pill(text: 'Zorunlu', bg: Theme.of(context).colorScheme.primary.withAlpha((0.14 * 255).round()), primary: true),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...g.items.map((it) {
                                      final selected = selectedOptions[g.id] == it.id;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: () => setState(() => selectedOptions[g.id] = it.id),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              color: selected
                                                  ? Theme.of(context).colorScheme.primary.withAlpha((0.18 * 255).round())
                                                  : Theme.of(context).colorScheme.surface.withAlpha((0.16 * 255).round()),
                                              border: selected
                                                  ? Border.all(
                                                      color: Theme.of(context).colorScheme.primary.withAlpha((0.4 * 255).round()),
                                                      width: 1.5,
                                                    )
                                                  : null,
                                              boxShadow: selected
                                                  ? [
                                                      BoxShadow(
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                        color: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).round()),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: selected
                                                          ? Theme.of(context).colorScheme.primary
                                                          : Theme.of(context).hintColor.withAlpha((0.3 * 255).round()),
                                                      width: 2,
                                                    ),
                                                    color: selected
                                                        ? Theme.of(context).colorScheme.primary
                                                        : Colors.transparent,
                                                  ),
                                                  child: selected
                                                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                                                      : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(it.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                                ),
                                                if (it.extraPriceTl > 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      color: Theme.of(context).colorScheme.surface.withAlpha((0.3 * 255).round()),
                                                    ),
                                                    child: Text('+${it.extraPriceTl} TL', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],

                          // ADD-ONS
                          if (p.addOns.isNotEmpty) ...[
                            Row(
                              children: [
                                const Text('Ekstra', style: TextStyle(fontWeight: FontWeight.w900)),
                                const Spacer(),
                                Text(
                                  p.maxAddOn > 0 ? 'En fazla ${p.maxAddOn} seçim' : '',
                                  style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildAddOns(context),
                            const SizedBox(height: 14),
                          ],

                          const SizedBox(height: 92), // bottom bar space
                        ],
                      ),
                    ),

                    // BOTTOM BAR (soft)
                    _BottomBar(
                      qty: qty,
                      onDec: () => setState(() => qty = (qty - 1).clamp(1, 99)),
                      onInc: () => setState(() => qty = (qty + 1).clamp(1, 99)),
                      unitTl: _unitTotalTl,
                      totalTl: _totalTl,
                      enabled: _isSelectionValid,
                      buttonText: removedIngredients.isEmpty ? 'Sepete ekle' : 'Sepete ekle • not var',
                      onAddToCart: () {
                        if (!_isSelectionValid) return;

                        // CartStore beklediği tipe çevir
                        final Map<String, List<ProductOptionItem>> selected = {};
                        for (final g in widget.product.optionGroups) {
                          final chosenId = selectedOptions[g.id];
                          if (chosenId == null) continue;
                          final chosen = g.items.firstWhere((x) => x.id == chosenId);
                          selected[g.id] = [chosen];
                        }

                        // ✅ Çıkarılacaklar notunu, CartStore’a dokunmadan ürün description’a ekle
                        final Product productForCart = removedIngredients.isEmpty
                            ? widget.product
                            : Product(
                                id: widget.product.id,
                                restaurantId: widget.product.restaurantId,
                                categoryId: widget.product.categoryId,
                                name: widget.product.name,
                                description: '${widget.product.description}\nÇıkarma: ${removedIngredients.join(", ")}',
                                imageUrl: widget.product.imageUrl,
                                priceTl: widget.product.priceTl,
                                isPopular: widget.product.isPopular,
                                optionGroups: widget.product.optionGroups,
                                addOns: widget.product.addOns,
                                maxAddOn: widget.product.maxAddOn,
                              );

                        context.read<CartStore>().addItem(
                              restaurant: widget.restaurant,
                              product: productForCart,
                              quantity: qty,
                              selectedOptions: selected,
                              selectedAddOnIds: selectedAddOns.toList(),
                            );

                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddOns(BuildContext context) {
    final p = widget.product;
    final maxed = p.maxAddOn > 0 && selectedAddOns.length >= p.maxAddOn;

    return _SoftCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Text('Seçenekler', style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (p.maxAddOn > 0) Text('${selectedAddOns.length}/${p.maxAddOn}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ...p.addOns.map((a) {
            final checked = selectedAddOns.contains(a.id);
            final disabled = !checked && maxed;

            return Opacity(
              opacity: disabled ? 0.45 : 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: disabled
                      ? null
                      : () {
                          setState(() {
                            if (checked) {
                              selectedAddOns.remove(a.id);
                            } else {
                              if (p.maxAddOn > 0 && selectedAddOns.length >= p.maxAddOn) return;
                              selectedAddOns.add(a.id);
                            }
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: checked
                          ? Theme.of(context).colorScheme.primary.withAlpha((0.18 * 255).round())
                          : Theme.of(context).colorScheme.surface.withAlpha((0.16 * 255).round()),
                      border: checked
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary.withAlpha((0.4 * 255).round()),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: checked
                          ? [
                              BoxShadow(
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                                color: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).round()),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: checked
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).hintColor.withAlpha((0.3 * 255).round()),
                              width: 2,
                            ),
                            color: checked
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                          child: checked
                              ? const Icon(Icons.check, size: 16, color: Colors.black)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.surface.withAlpha((0.3 * 255).round()),
                          ),
                          child: Text('+${a.priceTl} TL', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const _SoftCard({
    required this.child,
    this.padding,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // ✅ Border yok, sadece soft yüzey + hafif gölge
        color: Theme.of(context).colorScheme.surface.withAlpha((0.18 * 255).round()),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 12),
            color: Colors.black.withAlpha((0.28 * 255).round()),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final bool primary;

  const _Pill({required this.text, required this.bg, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: primary ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
  }
}

class _ChipToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipToggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Theme.of(context).colorScheme.primary.withAlpha((0.18 * 255).round())
        : Theme.of(context).colorScheme.surface.withAlpha((0.18 * 255).round());

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final int unitTl;
  final int totalTl;
  final bool enabled;
  final String buttonText;
  final VoidCallback onAddToCart;

  const _BottomBar({
    required this.qty,
    required this.onDec,
    required this.onInc,
    required this.unitTl,
    required this.totalTl,
    required this.enabled,
    required this.buttonText,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withAlpha((0.98 * 255).round()),
          // ✅ İnce border yerine çok hafif üst gölge
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              offset: const Offset(0, -8),
              color: Colors.black.withAlpha((0.30 * 255).round()),
            ),
          ],
        ),
        child: Row(
          children: [
            _SoftCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  _qtyBtn(context, Icons.remove, onDec),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  _qtyBtn(context, Icons.add, onInc),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birim: $unitTl TL',
                    style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text('Toplam: $totalTl TL', style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: enabled ? onAddToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor.withAlpha((0.2 * 255).round()),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: enabled ? 8 : 0,
                  shadowColor: enabled ? Theme.of(context).colorScheme.primary.withAlpha((0.4 * 255).round()) : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (enabled) ...[
                      const Icon(Icons.shopping_cart_rounded, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withAlpha((0.18 * 255).round()),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

String _capitalize(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1);
}
