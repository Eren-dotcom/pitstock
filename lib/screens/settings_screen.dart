import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/export_service.dart';
import '../services/label_service.dart';
import '../theme/app_theme.dart';
import 'users_screen.dart';
import 'backup_screen.dart';
import 'login_screen.dart';

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
        Text('Settings',
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
                title: Text('Signed in as ${auth.current?.name ?? '—'}'),
                subtitle: Text('Role: ${auth.role.label}'),
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
                  leading:
                      const Icon(Icons.group, color: AppTheme.secondary),
                  title: const Text('Manage users & roles'),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UsersScreen())),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.store, color: AppTheme.primary),
                title: const Text('Shop name'),
                subtitle: Text(settings.shopName),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _editShopName(context, settings),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.numbers, color: AppTheme.primary),
                title: const Text('GSTIN'),
                subtitle: Text(settings.gstin ?? 'Not set'),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _editGstin(context, settings),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dark_mode, color: AppTheme.primary),
                title: const Text('Theme'),
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
        Card(
          child: Column(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.table_chart, color: AppTheme.secondary),
                title: const Text('Export inventory to CSV'),
                subtitle: const Text('Share / backup all parts'),
                onTap: () => ExportService.exportCsv(context, inv.parts),
              ),
              const Divider(height: 1),
              ListTile(
                leading:
                    const Icon(Icons.picture_as_pdf, color: AppTheme.accent),
                title: const Text('Export PDF report'),
                subtitle: const Text('Stock & value summary'),
                onTap: () => ExportService.exportPdf(
                    context, inv.parts, settings.shopName),
              ),
              const Divider(height: 1),
              ListTile(
                leading:
                    const Icon(Icons.qr_code_2, color: AppTheme.primary),
                title: const Text('Print barcode labels'),
                subtitle: const Text('Code-128 labels for all parts'),
                onTap: () => LabelService.printPartLabels(inv.parts),
              ),
              if (auth.role.canBackup) ...[
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.cloud_sync, color: AppTheme.success),
                  title: const Text('Backup & Restore'),
                  subtitle:
                      const Text('Save or restore all data (one file)'),
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
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome,
                    color: AppTheme.primary),
                title: const Text('AI engine'),
                subtitle: const Text(
                    'Google ML Kit • on-device • free • works offline'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('PitStock'),
                subtitle: Text('Version 1.0.0 • Indian car parts catalogue'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editGstin(BuildContext context, SettingsProvider s) {
    final c = TextEditingController(text: s.gstin ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('GSTIN'),
        content: TextField(
            controller: c,
            decoration: const InputDecoration(hintText: '22AAAAA0000A1Z5')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              s.setGstin(c.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editShopName(BuildContext context, SettingsProvider s) {
    final c = TextEditingController(text: s.shopName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Shop name'),
        content: TextField(controller: c),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              s.setShopName(c.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
