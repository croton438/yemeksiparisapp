import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_store.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  void initState() {
    super.initState();
    final app = context.read<AppStore>();
    if (!app.ordersLoading) app.loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: app.ordersLoading
          ? const Center(child: CircularProgressIndicator())
          : app.orders.isEmpty
              ? const Center(child: Text('Henüz sipariş yok.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: app.orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final o = app.orders[i];
                    return Card(
                      child: ListTile(
                        title: Text('Sipariş ${o.id.substring(0, 8)}'),
                        subtitle: Text('${_statusLabel(o.status)} • ${o.createdAt.toLocal().toString().split('.').first}'),
                        trailing: Text('${o.total} TL', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    );
                  },
                ),
    );
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed:
        return 'Onaylandı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.on_the_way:
        return 'Yolda';
      case OrderStatus.delivered:
        return 'Teslim edildi';
      case OrderStatus.cancelled:
        return 'İptal edildi';
      case OrderStatus.pending:
      default:
        return 'Beklemede';
    }
  }
}
