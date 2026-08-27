import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';
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
import 'pos_billing_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'purchase_orders_screen.dart';
import 'stock_movements_screen.dart';
import 'stock_audit_screen.dart';
import 'label_studio_screen.dart';
import 'shop_profile_screen.dart';
import 'low_stock_screen.dart';

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
            _navItem(3, Icons.grid_view_rounded, 'A to Z'),
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
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
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
            Text('AI Quick Actions & Tools',
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
              subtitle: 'On-device OCR extracts line items into stock',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BillScanScreen()));
              }),
          _tile(context,
              icon: Icons.camera_alt,
              gradient: AppTheme.sunsetGradient,
              title: 'Live Scan Shop / Garage',
              subtitle: 'Detect parts & barcodes with live camera',
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
              icon: Icons.point_of_sale,
              gradient: const LinearGradient(
                  colors: [Color(0xFF00C2A8), Color(0xFF2E9E5B)]),
              title: 'POS Quick Checkout',
              subtitle: 'Fast counter billing with GST & UPI QR',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PosBillingScreen()));
              }),
          _tile(context,
              icon: Icons.upload_file,
              gradient: const LinearGradient(
                  colors: [Color(0xFFF4B400), Color(0xFFFF7A00)]),
              title: 'Bulk Import (CSV / Excel)',
              subtitle: 'Import supplier catalog or price list',
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
              subtitle: 'Create a new SKU in inventory',
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

/// Comprehensive "A to Z" Hub of all PitStock modules.
class _MoreHub extends StatelessWidget {
  const _MoreHub();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text('PitStock A to Z Hub',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Complete suite of automotive inventory & garage tools',
            style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(.6),
                fontSize: 12)),
        const SizedBox(height: 16),

        // Section: Sales & Billing
        _hubSection(context, 'Point of Sale & Billing', [
          _HubTile('POS Quick Sale', Icons.point_of_sale, AppTheme.primary,
              () => const PosBillingScreen()),
          _HubTile('Invoices & Bills', Icons.receipt_long, AppTheme.secondary,
              () => const InvoicesScreen()),
        ]),
        const SizedBox(height: 16),

        // Section: Workshop & Garage
        _hubSection(context, 'Workshop & Garage Jobs', [
          _HubTile('Job Cards', Icons.build_circle, AppTheme.accent,
              () => const WorkOrdersScreen()),
          _HubTile('Customers & Vehicles', Icons.people, const Color(0xFFE91E63),
              () => const CustomersScreen()),
        ]),
        const SizedBox(height: 16),

        // Section: Inventory Operations
        _hubSection(context, 'Inventory & Stock Management', [
          _HubTile('Add Part', Icons.add_box, AppTheme.success,
              () => const PartEditScreen()),
          _HubTile('Stock Audit', Icons.fact_check, const Color(0xFF7C4DFF),
              () => const StockAuditScreen()),
          _HubTile('Stock Movements', Icons.history, const Color(0xFF00BCD4),
              () => const StockMovementsScreen()),
          _HubTile('Stock Alerts', Icons.warning_amber, AppTheme.warning,
              () => const LowStockScreen()),
          _HubTile('Label Studio', Icons.qr_code_2, const Color(0xFF3F51B5),
              () => const LabelStudioScreen()),
          _HubTile('Bulk Import', Icons.upload_file, const Color(0xFF9C27B0),
              () => const BulkImportScreen()),
        ]),
        const SizedBox(height: 16),

        // Section: Vendors & Buying
        _hubSection(context, 'Vendors & Purchasing', [
          _HubTile('Suppliers', Icons.business, const Color(0xFF455A64),
              () => const SuppliersScreen()),
          _HubTile('Purchase Orders', Icons.shopping_bag, const Color(0xFF009688),
              () => const PurchaseOrdersScreen()),
        ]),
        const SizedBox(height: 16),

        // Section: AI & Smart Tools
        _hubSection(context, 'AI & Recognition Tools', [
          _HubTile('Bill OCR Scanner', Icons.document_scanner, const Color(0xFFE91E63),
              () => const BillScanScreen()),
          _HubTile('Live Camera Scan', Icons.camera_alt, const Color(0xFF00BCD4),
              () => const LiveScanScreen()),
          _HubTile('Part Photo ID', Icons.center_focus_strong, const Color(0xFFFF5722),
              () => const PhotoRecognitionScreen()),
        ]),
        const SizedBox(height: 16),

        // Section: System & Analytics
        _hubSection(context, 'Reports & Administration', [
          if (auth.role.canViewReports)
            _HubTile('Analytics & Reports', Icons.insights, AppTheme.primary,
                () => const AnalyticsScreen()),
          _HubTile('Shop Profile & GST', Icons.storefront, AppTheme.secondary,
              () => const ShopProfileScreen()),
          if (auth.role.canBackup)
            _HubTile('Backup & Restore', Icons.cloud_sync, const Color(0xFF2E9E5B),
                () => const BackupScreen()),
          _HubTile('Settings', Icons.settings, Colors.blueGrey,
              () => const SettingsScreen()),
        ]),
      ],
    );
  }

  Widget _hubSection(
      BuildContext context, String sectionTitle, List<_HubTile> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sectionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: tiles
              .map((t) => InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => t.builder())),
                    child: Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: t.color.withOpacity(.14),
                                borderRadius: BorderRadius.circular(14)),
                            child: Icon(t.icon, color: t.color, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(t.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
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
