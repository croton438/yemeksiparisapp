import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../widgets/cached_image.dart';
import 'restaurant_page.dart';

enum HomeSort { rating, minOrder, etaFast }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  final _sb = Supabase.instance.client;

  String _selectedCuisine = 'Hepsi';
  HomeSort _sort = HomeSort.rating;

  late Future<List<Restaurant>> _future;

  // ✅ DB’den cuisine okuyacağız (artık hardcoded map yok)
  final Map<String, String> _cuisineByRestaurantId = {};

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
    _future = _loadRestaurants();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Restaurant>> _loadRestaurants() async {
    final res = await _sb
        .from('restaurants')
        .select(
            'id,name,hero_image_url,min_order_tl,min_delivery_min,max_delivery_min,rating,description,is_open,cuisine')
        .order('rating', ascending: false);

    final rows = (res as List).cast<Map<String, dynamic>>();

    _cuisineByRestaurantId.clear();

    final list = rows.map((m) {
      final id = m['id'].toString();

      // cuisine varsa map’e yaz (UI filter + pill için)
      final cuisine = (m['cuisine'] ?? '').toString().trim();
      if (cuisine.isNotEmpty) {
        _cuisineByRestaurantId[id] = cuisine;
      }

      final desc = (m['description'] ?? '').toString();

      return Restaurant(
        id: id,
        name: (m['name'] ?? '').toString(),
        heroImageUrl: (m['hero_image_url'] ?? '').toString(),
        minOrderTl: (m['min_order_tl'] ?? 0) as int,
        minDeliveryMin: (m['min_delivery_min'] ?? 0) as int,
        maxDeliveryMin: (m['max_delivery_min'] ?? 0) as int,
        rating: (m['rating'] is num) ? (m['rating'] as num).toDouble() : 0.0,
        description: desc,
      );
    }).toList();

    return list;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadRestaurants();
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
      final cuisine = _cuisineByRestaurantId[r.id] ?? '';
      final matchesCuisine =
          _selectedCuisine == 'Hepsi' || cuisine == _selectedCuisine;
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
                const Text(
                  'Merhaba ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _SoftCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bağlantı hatası',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snap.error.toString(),
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w600,
                        ),
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

          final allRestaurants = snap.data ?? <Restaurant>[];
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
                const Text(
                  'Merhaba ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ne yemeyi düşünüyorsun?',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _SearchBox(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // ✅ Cuisine pills artık DB’den doluyor
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
                    Text(
                      'Sırala',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                    Icon(Icons.cloud_done_rounded,
                        size: 18, color: cs.primary.withAlpha((0.9 * 255).round())),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w700,
                      ),
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
            color: Theme.of(context).colorScheme.surface.withAlpha((0.18 * 255).round()),
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
        _SoftCard(
          radius: 16,
          padding: const EdgeInsets.all(16),
          child: bar(double.infinity, 20),
        ),
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
        _SoftCard(
          radius: 22,
          child: SizedBox(height: 210, child: bar(double.infinity, 210)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _SoftCard(
                radius: 20,
                child: SizedBox(height: 162, child: bar(double.infinity, 162)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SoftCard(
                radius: 20,
                child: SizedBox(height: 162, child: bar(double.infinity, 162)),
              ),
            ),
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
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900));
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

  const _ChipPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Theme.of(context).colorScheme.primary.withAlpha((0.22 * 255).round())
        : Theme.of(context).colorScheme.surface.withAlpha((0.16 * 255).round());

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

  const _SortPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Theme.of(context).colorScheme.primary.withAlpha((0.18 * 255).round())
        : Theme.of(context).colorScheme.surface.withAlpha((0.14 * 255).round());

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
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).hintColor,
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
                    : Theme.of(context).colorScheme.surface.withAlpha((0.22 * 255).round()),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatefulWidget {
  final Restaurant restaurant;
  final String cuisine;
  final VoidCallback onTap;

  const _FeaturedCard(
      {required this.restaurant, required this.cuisine, required this.onTap});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _SoftCard(
          onTap: widget.onTap,
          radius: 22,
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedImg(
                  url: widget.restaurant.heroImageUrl,
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
                        Colors.black.withAlpha((0.05 * 255).round()),
                        Colors.black.withAlpha((0.45 * 255).round()),
                        Colors.black.withAlpha((0.78 * 255).round()),
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
                    if (widget.cuisine.isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Theme.of(context).colorScheme.primary.withAlpha((0.25 * 255).round()),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.black.withAlpha((0.3 * 255).round()),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_menu_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(widget.cuisine,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                )),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      widget.restaurant.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withAlpha((0.2 * 255).round()),
                          ),
                          child: Text('Min. ${widget.restaurant.minOrderTl} ₺',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withAlpha((0.2 * 255).round()),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14),
                              const SizedBox(width: 4),
                              Text(widget.restaurant.eta,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withAlpha((0.2 * 255).round()),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(widget.restaurant.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularCard extends StatefulWidget {
  final Restaurant restaurant;
  final String cuisine;
  final VoidCallback onTap;

  const _PopularCard(
      {required this.restaurant, required this.cuisine, required this.onTap});

  @override
  State<_PopularCard> createState() => _PopularCardState();
}

class _PopularCardState extends State<_PopularCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 176,
          child: _SoftCard(
            onTap: widget.onTap,
            radius: 20,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedImg(
                          url: widget.restaurant.heroImageUrl,
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
                                Colors.black.withAlpha((0.05 * 255).round()),
                                Colors.black.withAlpha((0.35 * 255).round()),
                                Colors.black.withAlpha((0.70 * 255).round()),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.cuisine.isNotEmpty)
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Theme.of(context).colorScheme.primary.withAlpha((0.25 * 255).round()),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 6,
                                  color: Colors.black.withAlpha((0.3 * 255).round()),
                                ),
                              ],
                            ),
                            child: Text(widget.cuisine,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 11,
                                )),
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
                          widget.restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.restaurant.eta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              widget.restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListRowCard extends StatefulWidget {
  final Restaurant restaurant;
  final String cuisine;
  final VoidCallback onTap;

  const _ListRowCard(
      {required this.restaurant, required this.cuisine, required this.onTap});

  @override
  State<_ListRowCard> createState() => _ListRowCardState();
}

class _ListRowCardState extends State<_ListRowCard> with SingleTickerProviderStateMixin {
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _SoftCard(
          onTap: widget.onTap,
          radius: 18,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'restaurant_${widget.restaurant.id}',
                child: CachedImg(
                  url: widget.restaurant.heroImageUrl,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  memCacheWidth: 320,
                  memCacheHeight: 320,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.restaurant.name,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (widget.cuisine.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).round()),
                            ),
                            child: Text(
                              widget.cuisine,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Theme.of(context).colorScheme.surface.withAlpha((0.2 * 255).round()),
                          ),
                          child: Text(
                            'Min. ${widget.restaurant.minOrderTl} ₺',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Theme.of(context).hintColor),
                        const SizedBox(width: 4),
                        Text(
                          widget.restaurant.eta,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          widget.restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
            ],
          ),
        ),
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
          color: Theme.of(context).colorScheme.surface.withAlpha((0.18 * 255).round()),
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              offset: const Offset(0, 12),
              color: Colors.black.withAlpha((0.26 * 255).round()),
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
