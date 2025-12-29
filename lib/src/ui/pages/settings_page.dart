import 'package:flutter/material.dart';
import '../../data/restaurant_service.dart';
import '../../models/models.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<List<Restaurant>> _future;

  @override
  void initState() {
    super.initState();
    _future = RestaurantService.getRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar (Test)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Restaurant>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return _errorBox(context, snap.error.toString());
            }

            final list = snap.data ?? [];

            if (list.isEmpty) {
              return _emptyBox(context);
            }

            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _restaurantRow(context, list[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _restaurantRow(BuildContext context, Restaurant r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              if (r.description.trim().isNotEmpty)
                Text(
                  r.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _miniInfo(context, 'Min: ${r.minOrderTl}₺'),
                  _miniInfo(context, 'ETA: ${r.etaLabel}'),
                  _miniInfo(context, '⭐ ${r.rating.toStringAsFixed(1)}'),
                ],
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Icon(Icons.cloud_done_rounded, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _miniInfo(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.35),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }

  Widget _errorBox(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.4)),
        color: Theme.of(context).colorScheme.error.withOpacity(0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hata', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => setState(() => _future = RestaurantService.getRestaurants()),
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Restoran yok', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Supabase’de restaurants tablosunda kayıt yok gibi görünüyor.', style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => setState(() => _future = RestaurantService.getRestaurants()),
            child: const Text('Yenile'),
          ),
        ],
      ),
    );
  }
}
