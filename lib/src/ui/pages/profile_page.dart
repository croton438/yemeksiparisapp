import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_store.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'addresses_page.dart';
import 'my_orders_page.dart';

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).round()),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha((0.4 * 255).round()),
                    width: 2,
                  ),
                ),
                child: Icon(Icons.person_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Consumer<AuthStore>(
                  builder: (_, auth, __) {
                    if (auth.isLoggedIn && auth.profile != null) {
                      final p = auth.profile!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.fullName ?? p.email ?? 'Kullanıcı', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(p.email ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Misafir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Giriş yapmadınız', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())), child: const Text('Giriş yap')),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Sipariş vermek için Sprint 3'te üyelik zorunlu olacak.",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _tile(context, 'Siparişlerim', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersPage()))),
              const SizedBox(height: 10),
              _tile(context, 'Adreslerim', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesPage()))),
              const SizedBox(height: 10),
              _tile(context, 'Yardım', () => _open(context, 'Yardım')),
              const SizedBox(height: 10),
              Consumer<AuthStore>(builder: (_, auth, __) {
                if (!auth.isLoggedIn) return const SizedBox.shrink();
                return Column(
                  children: [
                    _tile(context, 'Çıkış Yap', () => auth.signOut()),
                    const SizedBox(height: 10),
                  ],
                );
              }),
            ],
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _tile(BuildContext context, String title, VoidCallback onTap) {
    IconData icon;
    switch (title) {
      case 'Siparişlerim':
        icon = Icons.receipt_long_rounded;
        break;
      case 'Adreslerim':
        icon = Icons.location_on_rounded;
        break;
      case 'Yardım':
        icon = Icons.help_outline_rounded;
        break;
      default:
        icon = Icons.chevron_right;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surface.withAlpha((0.25 * 255).round()),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 4),
                color: Colors.black.withAlpha((0.15 * 255).round()),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).round()),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
              Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }
}
