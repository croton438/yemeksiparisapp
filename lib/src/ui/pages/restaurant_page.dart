import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../state/cart_store.dart';
import '../sheets/product_customize_sheet.dart';
import '../widgets/cart_sheet.dart';
import '../widgets/topbar.dart';
import '../widgets/cached_image.dart';
import '../widgets/app_card.dart';

class RestaurantPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantPage({super.key, required this.restaurantId});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  late Restaurant restaurant;
  late List<Category> cats;

  final _menuSearch = TextEditingController();
  final _scrollController = ScrollController();

  // Anchors
  final _popularKey = GlobalKey();
  late final Map<String, GlobalKey> _categoryKeys;

  // Active highlight
  String _activeSectionId = '__popular__';
  Timer? _scrollDebounce;

  // ✅ Cache
  late final List<Product> _allProducts;
  late final List<Product> _popularProducts;
  late final Map<String, List<Product>> _productsByCategory;

  @override
  void initState() {
    super.initState();
    restaurant = MockData.restaurantById(widget.restaurantId);
    cats = MockData.categoriesForRestaurant(restaurant.id);

    _categoryKeys = {for (final c in cats) c.id: GlobalKey()};

    _allProducts = MockData.productsForRestaurant(restaurant.id);
    _popularProducts = _allProducts.where((p) => p.isPopular).toList();
    _productsByCategory = {
      for (final c in cats) c.id: _allProducts.where((p) => p.categoryId == c.id).toList(),
    };

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _menuSearch.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 80), _updateActiveSection);
  }

  void _updateActiveSection() {
    if (!mounted) return;

    final candidates = <_SectionCandidate>[
      _SectionCandidate(id: '__popular__', key: _popularKey),
      ...cats.map((c) => _SectionCandidate(id: c.id, key: _categoryKeys[c.id]!)),
    ];

    final topDy = 110.0;
    String bestId = _activeSectionId;
    double bestScore = double.infinity;

    for (final s in candidates) {
      final ctx = s.key.currentContext;
      if (ctx == null) continue;
      final ro = ctx.findRenderObject();
      if (ro is! RenderBox) continue;

      final dy = ro.localToGlobal(Offset.zero).dy;
      final score = (dy - topDy).abs();

      if (score < bestScore) {
        bestScore = score;
        bestId = s.id;
      }
    }

    if (bestId != _activeSectionId) {
      setState(() => _activeSectionId = bestId);
    }
  }

  void _jumpToSection(String id) {
    if (id == '__popular__') {
      final ctx = _popularKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
      return;
    }

    final ctx = _categoryKeys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  // ✅ 1) önce name  2) name sonuç yoksa description
  List<Product> _filterPreferNameThenDesc(List<Product> items, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return items;

    final byName = items.where((p) => p.name.toLowerCase().contains(query)).toList();
    if (byName.isNotEmpty) return byName;

    return items.where((p) => p.description.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final showCartBar = !cart.isEmpty && cart.restaurant?.id == restaurant.id;

    final q = _menuSearch.text;
    final hasQuery = q.trim().isNotEmpty;

    final popularFiltered = _filterPreferNameThenDesc(_popularProducts, q);
    final allMatchedCount = hasQuery ? _filterPreferNameThenDesc(_allProducts, q).length : _allProducts.length;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Topbar(
            title: restaurant.name,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            trailing: IconButton(
              onPressed: () => CartSheet.open(context),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_outlined),
                  if (!cart.isEmpty && cart.restaurant?.id == restaurant.id)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: Text(
                          '${cart.items.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppCard(
            radius: BorderRadius.circular(22),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
            onTap: null,
            child: AspectRatio(
              aspectRatio: 16 / 8.5,
              child: CachedImg(
                url: restaurant.heroImageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
              ),
            ),
          ),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Min. ${restaurant.minOrderTl} ₺ • ${restaurant.eta} • ${restaurant.rating.toStringAsFixed(1)}',
            style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 8)),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _menuSearch,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Menüde ara (örn. cheddar, pizza...)',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(
            hasQuery ? '$allMatchedCount sonuç' : ' ',
            style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
          ),
        ),
      ),

      SliverPersistentHeader(
        pinned: true,
        delegate: _StickyHeaderDelegate(
          height: 56,
          child: _CategoryStickyBar(
            categories: cats,
            activeId: _activeSectionId,
            onTap: _jumpToSection,
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 12)),

      SliverToBoxAdapter(
        child: Padding(
          key: _popularKey,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Popüler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              if (hasQuery)
                Text(
                  'Arama açık',
                  style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),

      if (popularFiltered.isEmpty)
        const SliverToBoxAdapter(child: SizedBox(height: 1))
      else
        SliverToBoxAdapter(
          child: SizedBox(
            height: 132,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: popularFiltered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = popularFiltered[i];
                return _PopularProductCard(
                  product: p,
                  onTap: () async {
                    await ProductCustomizeSheet.open(
                      context: context,
                      restaurant: restaurant,
                      product: p,
                    );
                  },
                );
              },
            ),
          ),
        ),

      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];

    for (final c in cats) {
      final base = _productsByCategory[c.id] ?? const <Product>[];
      final items = _filterPreferNameThenDesc(base, q);

      if (hasQuery && items.isEmpty) continue;

      slivers.addAll([
        SliverToBoxAdapter(
          child: Padding(
            key: _categoryKeys[c.id],
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CategoryHeader(title: c.title),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final p = items[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MenuCard(
                restaurant: restaurant,
                product: p,
                onAdd: () async {
                  await ProductCustomizeSheet.open(
                    context: context,
                    restaurant: restaurant,
                    product: p,
                  );
                },
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ]);
    }

    slivers.add(
      SliverToBoxAdapter(
        child: SizedBox(height: showCartBar ? 90 : 18),
      ),
    );

    return Scaffold(
      bottomNavigationBar: showCartBar
          ? _RestaurantCartBar(
              restaurant: restaurant,
              onTap: () => CartSheet.open(context),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: slivers,
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.infinity,
          color: Theme.of(context).dividerColor.withOpacity(0.75),
        ),
      ],
    );
  }
}

class _CategoryStickyBar extends StatelessWidget {
  final List<Category> categories;
  final String activeId;
  final void Function(String id) onTap;

  const _CategoryStickyBar({
    required this.categories,
    required this.activeId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_StickyItem>[
      const _StickyItem(id: '__popular__', title: 'Popüler', icon: Icons.local_fire_department_rounded),
      ...categories.map((c) => _StickyItem(id: c.id, title: c.title, icon: Icons.restaurant_menu_rounded)),
    ];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(top: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final it = items[i];
          final selected = it.id == activeId;

          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onTap(it.id),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(it.icon, size: 16),
                const SizedBox(width: 6),
                Text(it.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StickyItem {
  final String id;
  final String title;
  final IconData icon;
  const _StickyItem({required this.id, required this.title, required this.icon});
}

class _PopularProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _PopularProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: AppCard(
        onTap: onTap,
        radius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.20),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CachedImg(
              url: product.imageUrl,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              memCacheWidth: 260,
              memCacheHeight: 260,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text('${product.priceTl},99 TL', style: const TextStyle(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        alignment: Alignment.center,
                        child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCartBar extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCartBar({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();

    final remaining = restaurant.minOrderTl - cart.totalTl;
    final canCheckout = cart.canCheckout;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: AppCard(
          onTap: onTap,
          radius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                ),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.items.length} ürün • ${cart.totalTl} TL',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canCheckout ? 'Sepeti görüntüle' : 'Min. sepet için ${remaining > 0 ? remaining : 0} TL daha ekle',
                      style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.primary,
                ),
                alignment: Alignment.center,
                child: Text(
                  canCheckout ? 'Sepet' : 'Ekle',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Restaurant restaurant;
  final Product product;
  final VoidCallback onAdd;

  const _MenuCard({
    required this.restaurant,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onAdd,
      radius: BorderRadius.circular(22),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.22),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), bottomLeft: Radius.circular(22)),
            child: CachedImg(
              url: product.imageUrl,
              width: 92,
              height: 92,
              fit: BoxFit.cover,
              memCacheWidth: 300,
              memCacheHeight: 300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('${product.priceTl},99 TL', style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: onAdd,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.55)),
                ),
                child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => false;
}

class _SectionCandidate {
  final String id;
  final GlobalKey key;
  const _SectionCandidate({required this.id, required this.key});
}
