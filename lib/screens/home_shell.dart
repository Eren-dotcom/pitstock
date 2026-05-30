import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'search_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'bill_scan_screen.dart';
import 'live_scan_screen.dart';
import 'photo_recognition_screen.dart';
import 'part_edit_screen.dart';
import 'workorders_screen.dart';
import 'bulk_import_screen.dart';
import 'invoices_screen.dart';
import 'backup_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    InventoryScreen(),
    SearchScreen(),
    _MoreHub(),
  ];

  void _openAiMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withOpacity(.4),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: IconButton(
          iconSize: 30,
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          tooltip: 'AI Actions',
          onPressed: _openAiMenu,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 64,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.dashboard_rounded, 'Home'),
            _navItem(1, Icons.inventory_2_rounded, 'Stock'),
            const SizedBox(width: 40),
            _navItem(2, Icons.search_rounded, 'Search'),
            _navItem(3, Icons.grid_view_rounded, 'More'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final selected = _index == i;
    final color =
        selected ? AppTheme.primary : Theme.of(context).disabledColor;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _index = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AiActionSheet extends StatelessWidget {
  const _AiActionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.4),
                borderRadius: BorderRadius.circular(4)),
          ),
          Row(children: [
            const Icon(Icons.auto_awesome, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('AI Quick Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          _tile(context,
              icon: Icons.receipt_long,
              gradient: AppTheme.brandGradient,
              title: 'Scan a Bill / Invoice',
              subtitle: 'OCR auto-extracts items into inventory',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BillScanScreen()));
              }),
          _tile(context,
              icon: Icons.camera_alt,
              gradient: AppTheme.sunsetGradient,
              title: 'Live Scan Shop / Garage',
              subtitle: 'Detect parts & barcodes with the camera',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LiveScanScreen()));
              }),
          _tile(context,
              icon: Icons.center_focus_strong,
              gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF7A00)]),
              title: 'Identify Part by Photo',
              subtitle: 'AI recognises the part & finds matching stock',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PhotoRecognitionScreen()));
              }),
          _tile(context,
              icon: Icons.build_circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF00C2A8), Color(0xFF2E9E5B)]),
              title: 'New Work Order / Job',
              subtitle: 'Auto-deducts parts on completion',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WorkOrdersScreen()));
              }),
          _tile(context,
              icon: Icons.upload_file,
              gradient: const LinearGradient(
                  colors: [Color(0xFFF4B400), Color(0xFFFF7A00)]),
              title: 'Bulk Import (CSV / Excel)',
              subtitle: 'Import a supplier price list',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BulkImportScreen()));
              }),
          _tile(context,
              icon: Icons.add_box,
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)]),
              title: 'Add Part Manually',
              subtitle: 'Create a new SKU',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PartEditScreen()));
              }),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required Gradient gradient,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(.3))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(.6))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}

/// "More" hub: grid of all secondary features, role-aware.
class _MoreHub extends StatelessWidget {
  const _MoreHub();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tiles = <_HubTile>[
      _HubTile('Work Orders', Icons.build_circle, AppTheme.secondary,
          () => const WorkOrdersScreen()),
      _HubTile('Invoices', Icons.receipt_long, AppTheme.primary,
          () => const InvoicesScreen()),
      if (auth.role.canViewReports)
        _HubTile('Reports', Icons.insights, AppTheme.accent,
            () => const AnalyticsScreen()),
      _HubTile('Bulk Import', Icons.upload_file, const Color(0xFF7C4DFF),
          () => const BulkImportScreen()),
      _HubTile('Bill Scanner', Icons.document_scanner, const Color(0xFFE91E63),
          () => const BillScanScreen()),
      _HubTile('Live Scan', Icons.camera_alt, const Color(0xFF00BCD4),
          () => const LiveScanScreen()),
      _HubTile('Photo ID', Icons.center_focus_strong, const Color(0xFFE91E63),
          () => const PhotoRecognitionScreen()),
      _HubTile('Add Part', Icons.add_box, AppTheme.success,
          () => const PartEditScreen()),
      if (auth.role.canBackup)
        _HubTile('Backup', Icons.cloud_sync, const Color(0xFF2E9E5B),
            () => const BackupScreen()),
      _HubTile('Settings', Icons.settings, Colors.blueGrey,
          () => const SettingsScreen()),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text('More',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: tiles
              .map((t) => InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => t.builder())),
                    child: Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: t.color.withOpacity(.15),
                                borderRadius: BorderRadius.circular(16)),
                            child: Icon(t.icon, color: t.color, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(t.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _HubTile {
  final String label;
  final IconData icon;
  final Color color;
  final Widget Function() builder;
  _HubTile(this.label, this.icon, this.color, this.builder);
}
