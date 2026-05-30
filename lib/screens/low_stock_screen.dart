import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_tile.dart';
import 'part_detail_screen.dart';

class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final items = [...inv.outOfStock, ...inv.lowStock];
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Alerts')),
      body: items.isEmpty
          ? const Center(child: Text('All stock levels are healthy 🎉'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.notifications_active,
                        color: AppTheme.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          '${inv.outOfStock.length} out of stock, ${inv.lowStock.length} running low. Reorder soon.'),
                    ),
                  ]),
                ),
                ...items.map((p) => PartTile(
                    part: p,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                PartDetailScreen(partId: p.id))))),
              ],
            ),
    );
  }
}
