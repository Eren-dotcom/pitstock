import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workorder_provider.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';

/// Full backup & restore of the entire PitStock database.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupService();
  bool _busy = false;
  String _status = '';
  List<FileSystemEntity> _localBackups = [];

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final list = await _service.listLocalBackups();
    if (mounted) setState(() => _localBackups = list);
  }

  Future<void> _shareBackup() async {
    setState(() {
      _busy = true;
      _status = 'Creating backup…';
    });
    try {
      await _service.createAndShare();
      await _service.saveLocalCopy();
      await _loadLocal();
      _toast('Backup created. Save it somewhere safe!');
    } catch (e) {
      _toast('Backup failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restorePicked() async {
    final confirmed = await _confirmRestore();
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _status = 'Restoring…';
    });
    final res = await _service.pickAndRestore();
    await _afterRestore(res);
  }

  Future<void> _restoreLocal(String path) async {
    final info = await _service.inspect(path);
    final confirmed = await _confirmRestore(info: info);
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _status = 'Restoring…';
    });
    final res = await _service.restoreFromPath(path);
    await _afterRestore(res);
  }

  Future<void> _afterRestore(RestoreResult res) async {
    if (res.ok && mounted) {
      // Reload every provider from the freshly restored DB.
      await context.read<InventoryProvider>().refresh();
      await context.read<WorkOrderProvider>().bootstrap();
      await context.read<InvoiceProvider>().bootstrap();
      await context.read<SettingsProvider>().load();
      await context.read<AuthProvider>().load();
    }
    if (mounted) {
      setState(() => _busy = false);
      _toast(res.message, error: !res.ok);
    }
  }

  Future<bool?> _confirmRestore({Map<String, dynamic>? info}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This will REPLACE all current data (parts, jobs, invoices, '
                'users & settings) with the backup contents.'),
            if (info != null) ...[
              const SizedBox(height: 12),
              Text('Backup date: ${_fmtDate(info['createdAt'])}',
                  style: const TextStyle(fontSize: 12.5)),
              Text('Records: ${info['rowCount'] ?? '—'}',
                  style: const TextStyle(fontSize: 12.5)),
            ],
            const SizedBox(height: 8),
            const Text('This cannot be undone.',
                style: TextStyle(color: AppTheme.danger, fontSize: 12.5)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.danger : AppTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inv = context.watch<InventoryProvider>();
    if (!auth.role.canBackup) {
      return Scaffold(
        appBar: AppBar(title: const Text('Backup & Restore')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Only the Owner can back up or restore data.',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.cloud_sync, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Keep your data safe',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        'Backs up all ${inv.totalSkus} parts plus jobs, invoices, '
                        'users & settings into one file.',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (_busy)
            Row(children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Text(_status),
            ])
          else ...[
            FilledButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text('Create backup & share'),
              onPressed: _shareBackup,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restore from a file'),
              onPressed: _restorePicked,
            ),
          ],
          const SizedBox(height: 24),
          Row(children: [
            Text('On-device backups',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.refresh), onPressed: _loadLocal),
          ]),
          const SizedBox(height: 4),
          if (_localBackups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No local backups yet. Create one above.'),
            )
          else
            ..._localBackups.map((f) {
              final stat = f.statSync();
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x331E5AF6),
                    child: Icon(Icons.insert_drive_file,
                        color: AppTheme.primary),
                  ),
                  title: Text(f.path.split('/').last,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${_fmtDate(stat.modified.toIso8601String())} • '
                      '${(stat.size / 1024).toStringAsFixed(1)} KB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore, color: AppTheme.primary),
                    onPressed: () => _restoreLocal(f.path),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(.12),
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: const [
              Icon(Icons.lightbulb, size: 18, color: AppTheme.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Tip: after a big day, create a backup and save it to Google '
                    'Drive or send it to yourself on WhatsApp. Restoring replaces '
                    'all current data.',
                    style: TextStyle(fontSize: 11.5)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(dynamic iso) {
    if (iso is! String) return '—';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
