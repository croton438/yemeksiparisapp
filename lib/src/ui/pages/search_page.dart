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

  // ✅ Fallback (DB’de cuisine/is_open yoksa)
  final Map<String, String> _fallbackCuisineByRestaurantId = const {
    'r1': 'Burger',
    'r2': 'Pizza',
    'r3': 'Döner',
    'r4': 'Pilav',
    'r5': 'Çorba',
    'r6': 'Kebap',
    'r7': 'Tavuk',
    'r8': 'Tatlı',
    'r9': 'Kahve',
    'r10': 'Sağlıklı',
  };

  final Map<String, bool> _fallbackOpenByRestaurantId = const {
    'r1': true,
    'r2': true,
    'r3': false,
    'r4': true,
    'r5': false,
    'r6': true,
    'r7': true,
    'r8': false,
    'r9': true,
    'r10': true,
  };

  // ✅ DB’den geldiyse bunu kullanacağız
  final Map<String, String> _cuisineByRestaurantId = {};
  final Map<String, bool> _openByRestaurantId = {};

  List<String> get _cuisines {
    final set = <String>{'Hepsi', ..._cuisineByRestaurantId.values, ..._fallbackCuisineByRestaurantId.values};
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
    // restaurants tablosu kolon beklentileri:
    // id, name, hero_image_url, min_order_tl, min_delivery_min, max_delivery_min, rating
    // opsiyonel: description, is_open, cuisine
    final res = await _sb
        .from('restaurants')
        .select('id,name,hero_image_url,min_order_tl,min_delivery_min,max_delivery_min,rating,description,is_open,cuisine')
        .order('rating', ascending: false);

    final rows = (res as List).cast<Map<String, dynamic>>();

    _cuisineByRestaurantId.clear();
    _openByRestaurantId.clear();

    final list = rows.map((m) {
      final id = m['id'].toString();

      // DB’de varsa al, yoksa fallback’ten gelecek
      if (m['cuisine'] != null && m['cuisine'].toString().trim().isNotEmpty) {
        _cuisineByRestaurantId[id] = m['cuisine'].toString();
      }
      if (m['is_open'] != null) {
        final v = m['is_open'];
        _openByRestaurantId[id] = (v is bool) ? v : (v.toString().toLowerCase() == 'true');
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

    // slider max’ı DB’ye göre ayarla
    final maxVal = list.isEmpty
        ? 260
        : list.map((e) => e.minOrderTl).fold<int>(0, (p, v) => v > p ? v : p);

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
    return _cuisineByRestaurantId[r.id] ?? _fallbackCuisineByRestaurantId[r.id] ?? '';
  }

  bool _isOpen(Restaurant r) {
    return _openByRestaurantId[r.id] ?? _fallbackOpenByRestaurantId[r.id] ?? true;
  }

  List<Restaurant> _applyAll(List<Restaurant> input) {
    final q = _search.text.trim().toLowerCase();

    var list = input.where((r) {
      final cuisine = _cuisineOf(r);

      final matchesCuisine = _selectedCuisine == 'Hepsi' || cuisine == _selectedCuisine;
      final matchesSearch = q.isEmpty || r.name.toLowerCase().contains(q);

      final inMinOrder =
          r.minOrderTl.toDouble() >= _minOrderRange.start && r.minOrderTl.toDouble() <= _minOrderRange.end;

      final matchesRating = r.rating >= _minRating;
      final matchesOpen = !_onlyOpen || _isOpen(r);

      return matchesCuisine && matchesSearch && inMinOrder && matchesRating && matchesOpen;
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
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                        color: Colors.black.withOpacity(0.45),
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
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Filtrele',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
                                style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary),
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
                            minRating == 0 ? 'Hepsi' : minRating.toStringAsFixed(1),
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
                            divisions: (_maxMinOrder / 10).round().clamp(10, 60),
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
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
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

                // ✅ Search input (soft)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    radius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
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

                const SizedBox(height: 12),

                // cuisine chips
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

                      final bg = selected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.22)
                          : Theme.of(context).colorScheme.surface.withOpacity(0.20);

                      return Material(
                        color: bg,
                        borderRadius: BorderRadius.circular(999),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setState(() => _selectedCuisine = c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Text(
                              c,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: selected ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Filter + Sort row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: AppCard(
                          radius: BorderRadius.circular(18),
                          onTap: _openFilterSheet,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
                          child: Row(
                            children: [
                              const Icon(Icons.tune_rounded, size: 18),
                              const SizedBox(width: 10),
                              const Text('Filtrele', style: TextStyle(fontWeight: FontWeight.w900)),
                              if (activeFilters > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.22),
                                  ),
                                  child: Text(
                                    '$activeFilters',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _SmallPill(
                                label: 'Puan',
                                selected: _sort == SearchSort.rating,
                                onTap: () => setState(() => _sort = SearchSort.rating),
                              ),
                              const SizedBox(width: 8),
                              _SmallPill(
                                label: 'Min',
                                selected: _sort == SearchSort.minOrder,
                                onTap: () => setState(() => _sort = SearchSort.minOrder),
                              ),
                              const SizedBox(width: 8),
                              _SmallPill(
                                label: 'Hızlı',
                                selected: _sort == SearchSort.etaFast,
                                onTap: () => setState(() => _sort = SearchSort.etaFast),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => setState(() => _grid = !_grid),
                                icon: Icon(_grid ? Icons.view_agenda_outlined : Icons.grid_view_rounded),
                                tooltip: _grid ? 'Liste' : 'Grid',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Results header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} sonuç',
                        style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      if (activeFilters > 0)
                        TextButton(
                          onPressed: _resetFilters,
                          child: Text(
                            'Filtreleri sıfırla',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Text(
                            'Sonuç bulunamadı.',
                            style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                          ),
                        )
                      : _grid
                          ? GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.92,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final r = filtered[i];
                                final cuisine = _cuisineOf(r);
                                final isOpen = _isOpen(r);
                                return _RestaurantGridCard(
                                  restaurant: r,
                                  cuisine: cuisine,
                                  isOpen: isOpen,
                                  onTap: () => _goRestaurant(r),
                                );
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final r = filtered[i];
                                final cuisine = _cuisineOf(r);
                                final isOpen = _isOpen(r);
                                return _RestaurantListCard(
                                  restaurant: r,
                                  cuisine: cuisine,
                                  isOpen: isOpen,
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

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget pill(double w) => Container(
          width: w,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
          ),
        );

    return Column(
      children: [
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Topbar(title: 'Ara'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => pill(i == 0 ? 72 : 92),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SmallPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
        : Theme.of(context).colorScheme.surface.withOpacity(0.16);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

class _RestaurantGridCard extends StatelessWidget {
  final Restaurant restaurant;
  final String cuisine;
  final bool isOpen;
  final VoidCallback onTap;

  const _RestaurantGridCard({
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
      color: Theme.of(context).colorScheme.surface.withOpacity(0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CachedImg(
                    url: restaurant.heroImageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 520,
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
                          Colors.black.withOpacity(0.30),
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
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: isOpen ? Colors.black.withOpacity(0.35) : Colors.red.withOpacity(0.35),
                    ),
                    child: Text(
                      isOpen ? 'Açık' : 'Kapalı',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
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
                const SizedBox(height: 6),
                Text(
                  'Min. ${restaurant.minOrderTl} ₺',
                  style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantListCard extends StatelessWidget {
  final Restaurant restaurant;
  final String cuisine;
  final bool isOpen;
  final VoidCallback onTap;

  const _RestaurantListCard({
    required this.restaurant,
    required this.cuisine,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: BorderRadius.circular(18),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.22),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: isOpen ? Colors.white.withOpacity(0.06) : Colors.red.withOpacity(0.20),
                      ),
                      child: Text(
                        isOpen ? 'Açık' : 'Kapalı',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (cuisine.isNotEmpty) ...[
                      Text(
                        cuisine,
                        style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                      ),
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
                    Text(
                      restaurant.rating.toStringAsFixed(1),
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
    );
  }
}

// ---------- BottomSheet küçük UI parçaları ----------
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700)),
            ]),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w800)),
              const Spacer(),
              right,
            ],
          ),
          child,
        ],
      ),
    );
  }
}
