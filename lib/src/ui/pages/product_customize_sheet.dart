import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../state/cart_store.dart';

class ProductCustomizeSheet {
  static Future<void> addFromMenu({
    required BuildContext context,
    required Restaurant restaurant,
    required Product product,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _CustomizeBody(restaurant: restaurant, product: product),
    );
  }
}

class _CustomizeBody extends StatefulWidget {
  final Restaurant restaurant;
  final Product product;

  const _CustomizeBody({required this.restaurant, required this.product});

  @override
  State<_CustomizeBody> createState() => _CustomizeBodyState();
}

class _CustomizeBodyState extends State<_CustomizeBody> {
  int qty = 1;

  final Map<String, List<String>> selectedByGroup = {};
  final List<String> selectedOptionIds = [];
  final Map<String, int> optionPriceMap = {};
  final Map<String, String> optionTitleMap = {};
  final Map<String, String> groupTitleMap = {};

  int _deltaTotal() {
    int d = 0;
    for (final id in selectedOptionIds) {
      d += optionPriceMap[id] ?? 0;
    }
    return d;
  }

  int _unitPrice() => widget.product.priceTl + _deltaTotal();
  int _lineTotal() => _unitPrice() * qty;

  @override
  void initState() {
    super.initState();

    final groups = MockData.optionGroupsForProduct(widget.product.id);
    for (final g in groups) {
      groupTitleMap[g.id] = g.title;
      selectedByGroup[g.id] = <String>[];
      final items = MockData.optionItemsForGroup(g.id);
      for (final it in items) {
        optionPriceMap[it.id] = it.priceDeltaTl;
        optionTitleMap[it.id] = it.title;
      }
    }

    for (final g in groups) {
      if (g.type == OptionGroupType.requiredOne) {
        final items = MockData.optionItemsForGroup(g.id);
        if (items.isNotEmpty) _selectSingle(g.id, items.first.id);
      }
    }
  }

  void _selectSingle(String groupId, String optionId) {
    final current = selectedByGroup[groupId] ?? <String>[];
    for (final old in current) {
      selectedOptionIds.remove(old);
    }
    current
      ..clear()
      ..add(optionId);
    selectedByGroup[groupId] = current;

    if (!selectedOptionIds.contains(optionId)) selectedOptionIds.add(optionId);
  }

  void _toggleMulti(String groupId, String optionId, int maxSelect) {
    final current = selectedByGroup[groupId] ?? <String>[];
    if (current.contains(optionId)) {
      current.remove(optionId);
      selectedOptionIds.remove(optionId);
    } else {
      if (current.length >= maxSelect) return;
      current.add(optionId);
      if (!selectedOptionIds.contains(optionId)) selectedOptionIds.add(optionId);
    }
    selectedByGroup[groupId] = current;
  }

  @override
  Widget build(BuildContext context) {
    final groups = MockData.optionGroupsForProduct(widget.product.id);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, sc) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(widget.product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(widget.product.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 12),
                      Text(widget.product.description, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),

                      if (groups.isNotEmpty) ...[
                        const Text('Özelleştir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        ...groups.map((g) {
                          final items = MockData.optionItemsForGroup(g.id);
                          final current = selectedByGroup[g.id] ?? <String>[];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.black12),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                                    if (g.helperText != null)
                                      Text(g.helperText!, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...items.map((it) {
                                  final selected = current.contains(it.id);
                                  final price = it.priceDeltaTl == 0 ? '' : '+${it.priceDeltaTl} TL';

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (g.type == OptionGroupType.requiredOne) {
                                          _selectSingle(g.id, it.id);
                                        } else {
                                          _toggleMulti(g.id, it.id, g.maxSelect);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: selected ? Colors.black : Colors.black12),
                                        color: selected ? Colors.black.withOpacity(0.04) : Colors.white,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            g.type == OptionGroupType.requiredOne
                                                ? (selected ? Icons.radio_button_checked : Icons.radio_button_off)
                                                : (selected ? Icons.check_box : Icons.check_box_outline_blank),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(it.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                                          if (price.isNotEmpty)
                                            Text(price, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const Text('Adet', style: TextStyle(fontWeight: FontWeight.w900)),
                            const Spacer(),
                            IconButton(
                              onPressed: qty <= 1 ? null : () => setState(() => qty -= 1),
                              icon: const Icon(Icons.remove),
                            ),
                            Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)),
                            IconButton(
                              onPressed: () => setState(() => qty += 1),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final cart = context.read<CartStore>();

                        final selections = <String, dynamic>{
                          'selectedByGroup': selectedByGroup,
                          'selectedOptionIds': selectedOptionIds,
                          'optionPriceMap': optionPriceMap,
                          'optionTitleMap': optionTitleMap,
                          'groupTitleMap': groupTitleMap,
                        };

                        cart.addItem(
                          restaurant: widget.restaurant,
                          product: widget.product,
                          quantity: qty,
                          selections: selections,
                        );

                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text('Sepete ekle • ${_lineTotal()},00 TL', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
