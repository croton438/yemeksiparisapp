import 'package:flutter/material.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _open(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('Bu ekranı Sprint 3’te detaylandıracağız.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text('Hesabım', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Misafir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Sipariş vermek için Sprint 3’te üyelik zorunlu olacak.', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _tile(context, 'Siparişlerim', () => _open(context, 'Siparişlerim')),
              const SizedBox(height: 10),
              _tile(context, 'Adreslerim', () => _open(context, 'Adreslerim')),
              const SizedBox(height: 10),
              _tile(context, 'Yardım', () => _open(context, 'Yardım')),
            ],
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _tile(BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.35),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
