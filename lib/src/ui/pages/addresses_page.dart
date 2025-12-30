import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_store.dart';
import '../../models/models.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  @override
  void initState() {
    super.initState();
    final app = context.read<AppStore>();
    app.loadAddresses();
  }

  void _showEdit(BuildContext context, {Address? a}) {
    final titleCtrl = TextEditingController(text: a?.title ?? 'Yeni Adres');
    final cityCtrl = TextEditingController(text: a?.city ?? '');
    final districtCtrl = TextEditingController(text: a?.district ?? '');
    final neighborhoodCtrl = TextEditingController(text: a?.neighborhood ?? '');
    final lineCtrl = TextEditingController(text: a?.line ?? '');
    final noteCtrl = TextEditingController(text: a?.note ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(a == null ? 'Yeni Adres' : 'Adresi Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Başlık')),
              const SizedBox(height: 8),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'İl')),
              const SizedBox(height: 8),
              TextField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'İlçe')),
              const SizedBox(height: 8),
              TextField(controller: neighborhoodCtrl, decoration: const InputDecoration(labelText: 'Mahalle')),
              const SizedBox(height: 8),
              TextField(controller: lineCtrl, decoration: const InputDecoration(labelText: 'Açık adres')),
              const SizedBox(height: 8),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Not (opsiyonel)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final newA = Address(
                id: a?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text.trim(),
                city: cityCtrl.text.trim(),
                district: districtCtrl.text.trim(),
                neighborhood: neighborhoodCtrl.text.trim(),
                line: lineCtrl.text.trim(),
                note: noteCtrl.text.trim(),
              );
              final app = context.read<AppStore>();
              if (a == null) {
                app.addAddress(newA);
              } else {
                app.updateAddress(newA);
              }
              Navigator.pop(context);
            },
            child: Text(a == null ? 'Kaydet' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adreslerim')),
      body: Consumer<AppStore>(
        builder: (_, app, __) {
          if (app.isLoading) return const Center(child: CircularProgressIndicator());
          if (app.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Henüz adres yok.'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => _showEdit(context), child: const Text('Yeni Adres Ekle')),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: app.addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = app.addresses[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      color: Theme.of(context).colorScheme.surface.withAlpha((0.2 * 255).round()),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text(a.full, style: TextStyle(color: Theme.of(context).hintColor)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(onPressed: () => _showEdit(context, a: a), icon: const Icon(Icons.edit_rounded)),
                            IconButton(onPressed: () => context.read<AppStore>().deleteAddress(a.id), icon: const Icon(Icons.delete_rounded)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEdit(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
