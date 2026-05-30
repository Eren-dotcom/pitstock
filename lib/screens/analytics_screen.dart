import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text('Reports & Insights',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Inventory Value by Category',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 44,
                            sections: [
                              for (int i = 0; i < top.length; i++)
                                PieChartSectionData(
                                  value: top[i].value,
                                  color: colors[i % colors.length],
                                  radius: 52,
                                  title: total == 0
                                      ? ''
                                      : '${(top[i].value / total * 100).toStringAsFixed(0)}%',
                                  titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
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
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(children: [
                                  Container(
                                      width: 12,
                                      height: 12,
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
        _kpiRow(context, inv),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Brands by SKU count',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...(inv.countByBrand.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(8)
                    .map((e) {
                  final maxV = inv.countByBrand.values
                      .fold(0, (m, v) => v > m ? v : m);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(
                          width: 110,
                          child: Text(e.key,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: maxV == 0 ? 0 : e.value / maxV,
                            minHeight: 10,
                            backgroundColor:
                                AppTheme.primary.withOpacity(.12),
                            valueColor: const AlwaysStoppedAnimation(
                                AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiRow(BuildContext context, InventoryProvider inv) {
    final avgMargin = inv.parts.isEmpty
        ? 0.0
        : inv.parts.map((p) => p.marginPercent).reduce((a, b) => a + b) /
            inv.parts.length;
    return Row(
      children: [
        Expanded(
            child: _kpi(context, 'Stock Value',
                Fmt.money(inv.totalStockValue), Icons.savings)),
        const SizedBox(width: 12),
        Expanded(
            child: _kpi(context, 'Avg. Margin',
                '${avgMargin.toStringAsFixed(1)}%', Icons.percent)),
      ],
    );
  }

  Widget _kpi(BuildContext context, String label, String value, IconData ic) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ic, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
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
