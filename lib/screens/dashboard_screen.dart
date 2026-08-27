import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';
import '../widgets/part_tile.dart';
import 'part_detail_screen.dart';
import 'low_stock_screen.dart';
import 'pos_billing_screen.dart';
import 'workorders_screen.dart';
import 'bill_scan_screen.dart';
import 'stock_audit_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final settings = context.watch<SettingsProvider>();

    if (inv.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: inv.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back 👋',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.6))),
                    Text(settings.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withOpacity(.15),
                child: const Icon(Icons.store, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Action Hub Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _actionBtn(
                  context,
                  label: 'POS Sale',
                  icon: Icons.point_of_sale,
                  gradient: AppTheme.brandGradient,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PosBillingScreen())),
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  context,
                  label: 'Job Card',
                  icon: Icons.build_circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00C2A8), Color(0xFF2E9E5B)]),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WorkOrdersScreen())),
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  context,
                  label: 'Scan Bill',
                  icon: Icons.receipt_long,
                  gradient: AppTheme.sunsetGradient,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BillScanScreen())),
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  context,
                  label: 'Stock Audit',
                  icon: Icons.fact_check,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)]),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StockAuditScreen())),
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  context,
                  label: 'Customers',
                  icon: Icons.people,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFFFF7A00)]),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomersScreen())),
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  context,
                  label: 'Suppliers',
                  icon: Icons.business,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF455A64), Color(0xFF607D8B)]),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SuppliersScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stat Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatCard(
                  label: 'Total SKUs',
                  value: Fmt.num0(inv.totalSkus),
                  icon: Icons.qr_code_2,
                  gradient: AppTheme.brandGradient),
              StatCard(
                  label: 'Total Units',
                  value: Fmt.num0(inv.totalUnits),
                  icon: Icons.inventory_2,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)])),
              StatCard(
                  label: 'Stock Value',
                  value: Fmt.compactMoney(inv.totalStockValue),
                  icon: Icons.account_balance_wallet,
                  gradient: AppTheme.sunsetGradient),
              StatCard(
                  label: 'Potential Sales',
                  value: Fmt.compactMoney(inv.totalPotentialRevenue),
                  icon: Icons.trending_up,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00C2A8), Color(0xFF2E9E5B)])),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: .1, end: 0),
          const SizedBox(height: 16),

          // Alerts Banner
          if (inv.lowStock.isNotEmpty || inv.outOfStock.isNotEmpty)
            _alertBanner(context, inv),

          const SizedBox(height: 8),
          _sectionHeader(context, 'Stock by Category'),
          const SizedBox(height: 8),
          _CategoryChart(data: inv.countByCategory),
          const SizedBox(height: 20),

          _sectionHeader(context, 'Recently Updated Parts'),
          const SizedBox(height: 8),
          ...(inv.parts.toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
              .take(5)
              .map((p) => PartTile(
                  part: p,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PartDetailScreen(partId: p.id))))),
        ],
      ),
    );
  }

  Widget _actionBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _alertBanner(BuildContext context, InventoryProvider inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.warning.withOpacity(.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${inv.lowStock.length} low-stock • ${inv.outOfStock.length} out-of-stock items',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LowStockScreen())),
            child: const Text('View Alerts'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Text(title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700));
}

class _CategoryChart extends StatelessWidget {
  final Map<String, int> data;
  const _CategoryChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    final maxV = top.first.value.toDouble();
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
      const Color(0xFF7C4DFF),
      const Color(0xFFE91E63),
      const Color(0xFF2E9E5B),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxV + 2,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= top.length) {
                        return const SizedBox.shrink();
                      }
                      final name = top[i].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            name.length > 6 ? '${name.substring(0, 6)}…' : name,
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < top.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: top[i].value.toDouble(),
                      width: 22,
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          colors[i % colors.length],
                          colors[i % colors.length].withOpacity(.5)
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
