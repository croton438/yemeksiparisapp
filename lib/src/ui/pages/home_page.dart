import 'package:flutter/material.dart';
import '../../data/restaurant_service.dart';
import '../../models/models.dart';
import '../widgets/cached_image.dart';
import 'restaurant_page.dart';

enum HomeSort { rating, minOrder, etaFast }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();

  String _selectedCuisine = 'Hepsi';
  HomeSort _sort = HomeSort.rating;

  late Future<List<Restaurant>> _future;

  // ✅ UI tarafında restoran -> yemek türü map’i.
  // Supabase'e cuisine alanını ekleyince bunu DB’den okuyacağız.
  final Map<String, String> _cuisineByRestaurantId = const {
    'r1': 'Burger',
    'r2': 'Pizza',
    'r3': 'Döner',
    'r4': 'Sağlıklı',
    'r5': 'Asya',
    'r6': 'Meksika',
    'r7': 'Kebap',
    'r8': 'Tatlı',
    'r9': 'Kahve',
    'r10': 'Tavuk',
  };

  List<String> get _cuisines {
    final set = <String>{'Hepsi', ..._cuisineByRestaurantId.values};
    final list = set.toList();
    list.remove('Hepsi');
    list.sort();
    return ['Hepsi', ...list];
  }

  @override
  void initState() {
    super.initState();
    _future = RestaurantService.getRestaurants();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = RestaurantService.getRestaurants();
    });
    await _future;
  }

  void _goRestaurant(Restaurant r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantPage(restaurantId: r.id)),
    );
  }

  List<Restaurant> _applyFilterSort(List<Restaurant> input) {
    final q = _search.text.trim().toLowerCase();

    var list = input.where((r) {
      final cuisine = _cuisineByRestaurantId[r.id] ?? 'Hepsi';
      final matchesCuisine = _selectedCuisine == 'Hepsi' || cuisine == _selectedCuisine;
      final matchesSearch = q.isEmpty || r.name.toLowerCase().contains(q);
      return matchesCuisine && matchesSearch;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case HomeSort.rating:
          return b.rating.compareTo(a.rating);
        case HomeSort.minOrder:
          return a.minOrderTl.compareTo(b.minOrderTl);
        case HomeSort.etaFast:
          return a.minDeliveryMin.compareTo(b.minDeliveryMin);
      }
    });

    return list;
  }

  List<Restaurant> _popular(List<Restaurant> all) {
    final sorted = [...all]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Restaurant>>(
        future: _future,
        builder: (context, snap) {
          final cs = Theme.of(context).colorScheme;

          if (snap.connectionState == ConnectionState.waiting) {
            return const _HomeSkeleton();
          }

          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                const SizedBox(height: 6),
                const Text('Merhaba 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _SoftCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bağlantı hatası', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        snap.error.toString(),
                        style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refresh,
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final allRestaurants = snap.data ?? [];
          final popularRestaurants = _popular(allRestaurants);

          final filteredAll = _applyFilterSort(allRestaurants);
          final filteredPopular = _applyFilterSort(popularRestaurants);
          final featured = filteredAll.take(5).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                const SizedBox(height: 6),
                const Text('Merhaba 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  'Ne yemeyi düşünüyorsun?',
                  style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),

                _SearchBox(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cuisines.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final c = _cuisines[i];
                      final selected = c == _selectedCuisine;
                      return _ChipPill(
                        label: c,
                        selected: selected,
                        onTap: () => setState(() => _selectedCuisine = c),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Text('Sırala', style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    _SortPill(
                      label: 'Puan',
                      selected: _sort == HomeSort.rating,
                      onTap: () => setState(() => _sort = HomeSort.rating),
                    ),
                    const SizedBox(width: 8),
                    _SortPill(
                      label: 'Min Sepet',
                      selected: _sort == HomeSort.minOrder,
                      onTap: () => setState(() => _sort = HomeSort.minOrder),
                    ),
                    const SizedBox(width: 8),
                    _SortPill(
                      label: 'Hızlı',
                      selected: _sort == HomeSort.etaFast,
                      onTap: () => setState(() => _sort = HomeSort.etaFast),
                    ),
                    const Spacer(),
                    Icon(Icons.cloud_done_rounded, size: 18, color: cs.primary.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Text('Live', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 16),

                const _SectionTitle(title: 'Öne çıkanlar'),
                const SizedBox(height: 10),
                _FeaturedCarousel(
                  restaurants: featured,
                  cuisineById: _cuisineByRestaurantId,
                  onTap: _goRestaurant,
                ),
                const SizedBox(height: 18),

                const _SectionTitle(title: 'Popüler'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 162,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredPopular.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final r = filteredPopular[i];
                      return _PopularCard(
                        restaurant: r,
                        cuisine: _cuisineByRestaurantId[r.id] ?? '',
                        onTap: () => _goRestaurant(r),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                const _SectionTitle(title: 'Tüm restoranlar'),
                const SizedBox(height: 10),

                if (filteredAll.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Sonuç bulunamadı.',
                      style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: filteredAll.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = filteredAll[i];
                      return _ListRowCard(
                        restaurant: r,
                        cuisine: _cuisineByRestaurantId[r.id] ?? '',
                        onTap: () => _goRestaurant(r),
                      );
                    },
                  ),

                const SizedBox(height: 18),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        const SizedBox(height: 6),
        bar(140, 26),
        const SizedBox(height: 10),
        bar(220, 16),
        const SizedBox(height: 18),
        _SoftCard(radius: 16, padding: const EdgeInsets.all(16), child: bar(double.infinity, 20)),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => bar(88, 38),
          ),
        ),
        const SizedBox(height: 18),
        _SoftCard(radius: 22, child: SizedBox(height: 210, child: bar(double.infinity, 210))),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _SoftCard(radius: 20, child: SizedBox(height: 162, child: bar(double.infinity, 162)))),
            const SizedBox(width: 12),
            Expanded(child: _SoftCard(radius: 20, child: SizedBox(height: 162, child: bar(double.infinity, 162)))),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900));
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Restoran ara (örn. pizza)',
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.22)
        : Theme.of(context).colorScheme.surface.withOpacity(0.16);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface.withOpacity(0.14);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCarousel extends StatefulWidget {
  final List<Restaurant> restaurants;
  final Map<String, String> cuisineById;
  final ValueChanged<Restaurant> onTap;

  const _FeaturedCarousel({
    required this.restaurants,
    required this.cuisineById,
    required this.onTap,
  });

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final _page = PageController(viewportFraction: 0.92);
  int _idx = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.restaurants.isEmpty) return const SizedBox(height: 1);

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _page,
            itemCount: widget.restaurants.length,
            onPageChanged: (i) => setState(() => _idx = i),
            itemBuilder: (_, i) {
              final r = widget.restaurants[i];
              final cuisine = widget.cuisineById[r.id] ?? '';
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _FeaturedCard(
                  restaurant: r,
                  cuisine: cuisine,
                  onTap: () => widget.onTap(r),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.restaurants.length, (i) {
            final active = i == _idx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface.withOpacity(0.22),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Restaurant restaurant;
  final String cuisine;
  final VoidCallback onTap;

  const _FeaturedCard({required this.restaurant, required this.cuisine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      onTap: onTap,
      radius: 22,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedImg(
              url: restaurant.heroImageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 1200,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cuisine.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withOpacity(0.35),
                    ),
                    child: Text(cuisine, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                const SizedBox(height: 10),
                Text(
                  restaurant.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Min. ${restaurant.minOrderTl} ₺', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Text(restaurant.eta, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    const Icon(Icons.star_rounded, size: 18),
                    const SizedBox(width: 4),
                    Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  final Restaurant restaurant;
  final String cuisine;
  final VoidCallback onTap;

  const _PopularCard({required this.restaurant, required this.cuisine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: _SoftCard(
        onTap: onTap,
        radius: 20,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedImg(
                      url: restaurant.heroImageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 700,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.35),
                            Colors.black.withOpacity(0.70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (cuisine.isNotEmpty)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withOpacity(0.35),
                        ),
                        child: Text(cuisine, style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 66,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.eta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.star_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListRowCard extends StatelessWidget {
  final Restaurant restaurant;
  final String cuisine;
  final VoidCallback onTap;

  const _ListRowCard({required this.restaurant, required this.cuisine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CachedImg(
            url: restaurant.heroImageUrl,
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            memCacheWidth: 320,
            memCacheHeight: 320,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (cuisine.isNotEmpty) ...[
                      Text(cuisine, style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      'Min. ${restaurant.minOrderTl} ₺',
                      style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(restaurant.eta,
                        style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    const Icon(Icons.star_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
        ],
      ),
    );
  }
}

/// ✅ Border’sız “soft/glass” kart (çizgileri azaltır)
class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  const _SoftCard({
    required this.child,
    this.padding,
    this.radius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              offset: const Offset(0, 12),
              color: Colors.black.withOpacity(0.26),
            ),
          ],
        ),
        child: child,
      ),
    );

    if (onTap == null) return box;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: box,
      ),
    );
  }
}
