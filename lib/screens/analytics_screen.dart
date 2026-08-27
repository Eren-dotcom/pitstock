import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/part.dart';
import '../providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'part_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _tabIndex = 0; // 0: Overview, 1: Dead/Slow Stock, 2: Reorder Plan

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final invoiceProv = context.watch<InvoiceProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            tooltip: 'Export PDF Report',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () =>
                ExportService.exportPdf(context, inv.parts, settings.shopName),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Segmented Tab bar
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Overview')),
              ButtonSegment(value: 1, label: Text('Dead / Slow Stock')),
              ButtonSegment(value: 2, label: Text('Reorder Plan')),
            ],
            selected: {_tabIndex},
            onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
          ),
          const SizedBox(height: 16),

          if (_tabIndex == 0) ..._buildOverviewTab(context, inv, invoiceProv),
          if (_tabIndex == 1) ..._buildDeadStockTab(context, inv),
          if (_tabIndex == 2) ..._buildReorderPlanTab(context, inv),
        ],
      ),
    );
  }

  List<Widget> _buildOverviewTab(BuildContext context, InventoryProvider inv,
      InvoiceProvider invoiceProv) {
    final valueByCat = inv.valueByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
      const Color(0xFF7C4DFF),
      const Color(0xFFE91E63),
      const Color(0xFF2E9E5B),
      const Color(0xFFFFC107),
    ];

    final total = inv.totalStockValue;
    final top = valueByCat.take(6).toList();

    return [
      // KPI Row 1
      Row(
        children: [
          Expanded(
            child: _kpi(
              context,
              'Total Stock Value',
              Fmt.money(inv.totalStockValue),
              Icons.account_balance_wallet,
              AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _kpi(
              context,
              'Potential Revenue',
              Fmt.money(inv.totalPotentialRevenue),
              Icons.trending_up,
              AppTheme.secondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // KPI Row 2
      Row(
        children: [
          Expanded(
            child: _kpi(
              context,
              'Expected Gross Profit',
              Fmt.money(inv.totalPotentialProfit),
              Icons.monetization_on,
              AppTheme.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _kpi(
              context,
              'Average Margin',
              '${inv.overallMarginPercent.toStringAsFixed(1)}%',
              Icons.percent,
              AppTheme.accent,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Valuation by Category Chart
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Inventory Value by Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          sections: [
                            for (int i = 0; i < top.length; i++)
                              PieChartSectionData(
                                value: top[i].value,
                                color: colors[i % colors.length],
                                radius: 46,
                                title: total == 0
                                    ? ''
                                    : '${(top[i].value / total * 100).toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < top.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              child: Row(children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: colors[i % colors.length],
                                        borderRadius:
                                            BorderRadius.circular(3))),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(top[i].key,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11.5)),
                                ),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),

      // Top Brands Chart
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Brands by SKU count',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 12),
              ...(inv.countByBrand.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .take(7)
                  .map((e) {
                final maxV = inv.countByBrand.values
                    .fold(0, (m, v) => v > m ? v : m);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    SizedBox(
                        width: 110,
                        child: Text(e.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: maxV == 0 ? 0 : e.value / maxV,
                          minHeight: 8,
                          backgroundColor: AppTheme.primary.withOpacity(.12),
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                );
              }),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDeadStockTab(
      BuildContext context, InventoryProvider inv) {
    // Parts with zero movements or excess stock over maxStock
    final overstocked = inv.overStock;
    final zeroStock = inv.outOfStock;

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.info, color: AppTheme.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Identifies capital locked in excess inventory (${overstocked.length} items over maximum threshold).',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text('Overstocked Parts (${overstocked.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 6),
      if (overstocked.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No overstocked inventory detected. Stock levels are balanced!'),
          ),
        )
      else
        ...overstocked.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PartDetailScreen(partId: p.id))),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Qty: ${p.quantity} (Max capacity: ${p.maxStock}) • Locked Value: ${Fmt.money(p.stockValue)}'),
                trailing: Text(p.binLocation, style: const TextStyle(fontSize: 12)),
              ),
            )),
    ];
  }

  List<Widget> _buildReorderPlanTab(
      BuildContext context, InventoryProvider inv) {
    final needReorder = [...inv.outOfStock, ...inv.lowStock];

    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.sunsetGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated Replenishment Budget',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(Fmt.money(inv.estimatedReorderBudget),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('Parts Below Reorder Point (${needReorder.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 8),
      if (needReorder.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('All parts have healthy inventory levels 🎉'),
          ),
        )
      else
        ...needReorder.map((p) {
          final neededQty = (p.reorderQty - p.quantity).clamp(1, 9999);
          final estCost = neededQty * p.costPrice;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PartDetailScreen(partId: p.id))),
              leading: CircleAvatar(
                backgroundColor: p.isOutOfStock
                    ? AppTheme.danger.withOpacity(.15)
                    : AppTheme.warning.withOpacity(.15),
                child: Icon(
                  p.isOutOfStock ? Icons.error_outline : Icons.warning_amber,
                  color: p.isOutOfStock ? AppTheme.danger : AppTheme.warning,
                ),
              ),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Current: ${p.quantity} • Target: ${p.reorderQty} • Reorder: +$neededQty ${p.unit}\nVendor: ${p.supplier ?? 'Unassigned'}'),
              isThreeLine: true,
              trailing: Text(Fmt.money(estCost),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ),
          );
        }),
    ];
  }

  Widget _kpi(BuildContext context, String label, String value, IconData ic,
      Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(.15),
              child: Icon(ic, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(.6))),
          ],
        ),
      ),
    );
  }
}
