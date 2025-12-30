import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../widgets/cached_image.dart';
import '../widgets/topbar.dart';
import '../widgets/app_card.dart';
import 'restaurant_page.dart';

enum SearchSort { rating, minOrder, etaFast }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _search = TextEditingController();
  final _sb = Supabase.instance.client;

  // ✅ Kategori (Cuisine) filtreleri
  String _selectedCuisine = 'Hepsi';

  // ✅ Filtreler (BottomSheet içinden yönetilecek)
  bool _onlyOpen = false;
  double _minRating = 0; // 0-5
  double _maxMinOrder = 260;
  RangeValues _minOrderRange = const RangeValues(0, 260);

  // ✅ Sıralama + görünüm
  SearchSort _sort = SearchSort.rating;
  bool _grid = true;

  // ✅ DB’den data
  late Future<List<Restaurant>> _future;
  List<Restaurant> _restaurants = [];

  // ✅ DB’den geldiyse bunu kullanacağız
  final Map<String, String> _cuisineByRestaurantId = {};
  final Map<String, bool> _openByRestaurantId = {};

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
    _openByRestaurantId.clear();

    final list = rows.map((m) {
      final id = m['id'].toString();

      if (m['cuisine'] != null && m['cuisine'].toString().trim().isNotEmpty) {
        _cuisineByRestaurantId[id] = m['cuisine'].toString();
      }

      if (m['is_open'] != null) {
        final v = m['is_open'];
        _openByRestaurantId[id] =
            (v is bool) ? v : (v.toString().toLowerCase() == 'true');
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
        // ✅ Eğer Restaurant modelinde description yoksa compile’da patlar:
        // Bu satırı sil.
        description: desc,
      );
    }).toList();

    final maxVal = list.isEmpty
        ? 260
        : list
            .map((e) => e.minOrderTl)
            .fold(0, (p, v) => v > p ? v : p);

    _maxMinOrder = (maxVal + 20).toDouble();
    _minOrderRange = RangeValues(0, _maxMinOrder);

    _restaurants = list;
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

  String _cuisineOf(Restaurant r) {
    return _cuisineByRestaurantId[r.id] ?? '';
  }

  bool _isOpen(Restaurant r) {
    return _openByRestaurantId[r.id] ?? true;
  }

  List<Restaurant> _applyAll(List<Restaurant> input) {
    final q = _search.text.trim().toLowerCase();

    var list = input.where((r) {
      final cuisine = _cuisineOf(r);
      final matchesCuisine =
          _selectedCuisine == 'Hepsi' || cuisine == _selectedCuisine;
      final matchesSearch = q.isEmpty || r.name.toLowerCase().contains(q);

      final inMinOrder = r.minOrderTl.toDouble() >= _minOrderRange.start &&
          r.minOrderTl.toDouble() <= _minOrderRange.end;

      final matchesRating = r.rating >= _minRating;
      final matchesOpen = !_onlyOpen || _isOpen(r);

      return matchesCuisine &&
          matchesSearch &&
          inMinOrder &&
          matchesRating &&
          matchesOpen;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case SearchSort.rating:
          return b.rating.compareTo(a.rating);
        case SearchSort.minOrder:
          return a.minOrderTl.compareTo(b.minOrderTl);
        case SearchSort.etaFast:
          return a.minDeliveryMin.compareTo(b.minDeliveryMin);
      }
    });

    return list;
  }

  int _activeFilterCount() {
    var c = 0;
    if (_onlyOpen) c++;
    if (_minRating > 0) c++;
    if (!(_minOrderRange.start == 0 && _minOrderRange.end == _maxMinOrder)) c++;
    return c;
  }

  void _resetFilters() {
    setState(() {
      _onlyOpen = false;
      _minRating = 0;
      _minOrderRange = RangeValues(0, _maxMinOrder);
    });
  }

  Future<void> _openFilterSheet() async {
    bool onlyOpen = _onlyOpen;
    double minRating = _minRating;
    RangeValues minOrderRange = _minOrderRange;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;

        return StatefulBuilder(
          builder: (context, setLocal) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withAlpha((0.92 * 255).round()),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                        color: Colors.black.withAlpha((0.45 * 255).round()),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withAlpha((0.12 * 255).round()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Filtrele',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setLocal(() {
                                onlyOpen = false;
                                minRating = 0;
                                minOrderRange = RangeValues(0, _maxMinOrder);
                              }),
                              child: Text(
                                'Sıfırla',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _SheetTile(
                          title: 'Sadece açık restoranlar',
                          subtitle: 'Şu an sipariş alabilenleri göster',
                          trailing: Switch(
                            value: onlyOpen,
                            onChanged: (v) => setLocal(() => onlyOpen = v),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SheetBlock(
                          title: 'Minimum puan',
                          right: Text(
                            minRating == 0
                                ? 'Hepsi'
                                : minRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          child: Slider(
                            value: minRating,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            onChanged: (v) => setLocal(() => minRating = v),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SheetBlock(
                          title: 'Min sepet aralığı',
                          right: Text(
                            '${minOrderRange.start.round()} ₺ - ${minOrderRange.end.round()} ₺',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          child: RangeSlider(
                            values: minOrderRange,
                            min: 0,
                            max: _maxMinOrder,
                            divisions: (_maxMinOrder / 10)
                                .round()
                                .clamp(10, 60),
                            onChanged: (v) => setLocal(() => minOrderRange = v),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Vazgeç'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _onlyOpen = onlyOpen;
                                    _minRating = minRating;
                                    _minOrderRange = minOrderRange;
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Uygula'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Restaurant>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _SearchSkeleton();
          }

          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: Topbar(title: 'Ara'),
                ),
                const SizedBox(height: 12),
                AppCard(
                  radius: BorderRadius.circular(18),
                  padding: const EdgeInsets.all(14),
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withAlpha((0.18 * 255).round()),
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

          final data = snap.data ?? _restaurants;
          final filtered = _applyAll(data);
          final activeFilters = _activeFilterCount();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Topbar(title: 'Ara'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    radius: BorderRadius.circular(18),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withAlpha((0.18 * 255).round()),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Restoran ara (örn. pizza)',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _SortPill(
                        label: 'Puan',
                        selected: _sort == SearchSort.rating,
                        onTap: () => setState(() => _sort = SearchSort.rating),
                      ),
                      const SizedBox(width: 8),
                      _SortPill(
                        label: 'Min Sepet',
                        selected: _sort == SearchSort.minOrder,
                        onTap: () => setState(() => _sort = SearchSort.minOrder),
                      ),
                      const SizedBox(width: 8),
                      _SortPill(
                        label: 'Hızlı',
                        selected: _sort == SearchSort.etaFast,
                        onTap: () => setState(() => _sort = SearchSort.etaFast),
                      ),
                      const Spacer(),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: _openFilterSheet,
                            icon: const Icon(Icons.tune_rounded),
                          ),
                          if (activeFilters > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  activeFilters.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          children: [
                            Text(
                              'Sonuç bulunamadı.',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_activeFilterCount() > 0)
                              FilledButton(
                                onPressed: _resetFilters,
                                child: const Text('Filtreleri sıfırla'),
                              ),
                          ],
                        )
                      : _grid
                          ? GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 10, 16, 16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.88,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final r = filtered[i];
                                return _GridCard(
                                  restaurant: r,
                                  cuisine: _cuisineOf(r),
                                  isOpen: _isOpen(r),
                                  onTap: () => _goRestaurant(r),
                                );
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 10, 16, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final r = filtered[i];
                                return _ListRowCard(
                                  restaurant: r,
                                  cuisine: _cuisineOf(r),
                                  isOpen: _isOpen(r),
                                  onTap: () => _goRestaurant(r),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SheetTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Theme.of(context).colorScheme.surface.withAlpha((0.12 * 255).round()),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SheetBlock extends StatelessWidget {
  final String title;
  final Widget right;
  final Widget child;

  const _SheetBlock({
    required this.title,
    required this.right,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: BorderRadius.circular(18),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: Theme.of(context).colorScheme.surface.withAlpha((0.12 * 255).round()),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              right,
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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

  const _SortPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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

class _GridCard extends StatefulWidget {
  final Restaurant restaurant;
  final String cuisine;
  final bool isOpen;
  final VoidCallback onTap;

  const _GridCard({
    required this.restaurant,
    required this.cuisine,
    required this.isOpen,
    required this.onTap,
  });

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> with SingleTickerProviderStateMixin {
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
        child: AppCard(
          onTap: widget.onTap,
          radius: BorderRadius.circular(22),
          padding: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surface.withAlpha((0.14 * 255).round()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedImg(
                          url: widget.restaurant.heroImageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 900,
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
                                Colors.black.withAlpha((0.55 * 255).round()),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _StatusPill(isOpen: widget.isOpen),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.cuisine.isNotEmpty)
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
                    if (widget.cuisine.isNotEmpty) const SizedBox(height: 6),
                    Text(
                      widget.restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          widget.restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Theme.of(context).colorScheme.surface.withAlpha((0.3 * 255).round()),
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
                          '${widget.restaurant.minDeliveryMin}-${widget.restaurant.maxDeliveryMin} dk',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
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

class _ListRowCard extends StatelessWidget {
  final Restaurant restaurant;
  final String cuisine;
  final bool isOpen;
  final VoidCallback onTap;

  const _ListRowCard({
    required this.restaurant,
    required this.cuisine,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface.withAlpha((0.14 * 255).round()),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 74,
              height: 74,
              child: CachedImg(
                url: restaurant.heroImageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(isOpen: isOpen),
                  ],
                ),
                const SizedBox(height: 6),
                if (cuisine.isNotEmpty)
                  Text(
                    cuisine,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      restaurant.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${restaurant.minDeliveryMin}-${restaurant.maxDeliveryMin} dk',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Min. ${restaurant.minOrderTl} ₺',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
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

class _StatusPill extends StatelessWidget {
  final bool isOpen;

  const _StatusPill({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg =
        isOpen ? cs.primary.withAlpha((0.22 * 255).round()) : cs.surface.withAlpha((0.22 * 255).round());
    final fg = isOpen ? cs.primary : Theme.of(context).hintColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Açık' : 'Kapalı',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: fg,
        ),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

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
        bar(120, 18),
        const SizedBox(height: 12),
        bar(double.infinity, 48),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => bar(88, 38),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            bar(70, 30),
            const SizedBox(width: 8),
            bar(90, 30),
            const SizedBox(width: 8),
            bar(70, 30),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.88,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => AppCard(
            radius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface.withAlpha((0.14 * 255).round()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: bar(double.infinity, 120)),
                const SizedBox(height: 10),
                bar(120, 14),
                const SizedBox(height: 8),
                bar(80, 12),
                const SizedBox(height: 8),
                bar(140, 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
