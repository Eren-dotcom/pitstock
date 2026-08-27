import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_user.dart';
import '../services/export_service.dart';
import '../services/label_service.dart';
import '../theme/app_theme.dart';
import 'users_screen.dart';
import 'backup_screen.dart';
import 'login_screen.dart';
import 'shop_profile_screen.dart';
import 'label_studio_screen.dart';
import 'stock_movements_screen.dart';
import 'stock_audit_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final inv = context.watch<InventoryProvider>();
    final auth = context.watch<AuthProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text('Settings & Configuration',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),

        // Signed-in user / RBAC
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge, color: AppTheme.primary),
                title: Text(auth.current?.name ?? 'Staff User'),
                subtitle: Text('Role: ${auth.role.label} • Active Session'),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  onPressed: () {
                    auth.logout();
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                ),
              ),
              if (auth.role.canManageUsers) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.group, color: AppTheme.secondary),
                  title: const Text('Manage users & staff PINs'),
                  subtitle: const Text('Owner-only RBAC configuration'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UsersScreen())),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Business Profile & GST Settings
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storefront, color: AppTheme.primary),
                title: const Text('Shop Profile & GSTIN'),
                subtitle: Text('${settings.shopName} • ${settings.shopPhone}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ShopProfileScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dark_mode, color: AppTheme.primary),
                title: const Text('Theme Mode'),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (m) =>
                      settings.setThemeMode(m ?? ThemeMode.system),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tools & Inventory Utilities
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_2, color: AppTheme.primary),
                title: const Text('Barcode & Label Studio'),
                subtitle: const Text('Custom barcodes, shelf & price tags'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LabelStudioScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.fact_check, color: AppTheme.secondary),
                title: const Text('Physical Stock Audit'),
                subtitle: const Text('Reconcile physical inventory counts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StockAuditScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history, color: AppTheme.accent),
                title: const Text('Stock Movements Audit Log'),
                subtitle: const Text('Complete log of all inventory changes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StockMovementsScreen())),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Exports & Data Backup
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart, color: AppTheme.secondary),
                title: const Text('Export inventory to CSV'),
                subtitle: const Text('Export all parts, prices & stock'),
                onTap: () => ExportService.exportCsv(context, inv.parts),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppTheme.accent),
                title: const Text('Export Valuation PDF report'),
                subtitle: const Text('Printable stock valuation sheet'),
                onTap: () => ExportService.exportPdf(
                    context, inv.parts, settings.shopName),
              ),
              if (auth.role.canBackup) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_sync, color: AppTheme.success),
                  title: const Text('Full Backup & Restore'),
                  subtitle: const Text('Single-file SQLite snapshot of all data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BackupScreen())),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.auto_awesome, color: AppTheme.primary),
                title: Text('AI Engine & OCR'),
                subtitle: Text(
                    'Google ML Kit • 100% On-Device • Free & Offline'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('PitStock'),
                subtitle: Text('v1.0.0 • Automotive Spares & Garage Management'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
