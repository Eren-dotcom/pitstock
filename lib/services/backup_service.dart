import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database_helper.dart';

/// Outcome of a restore attempt, with a friendly summary.
class RestoreResult {
  final bool ok;
  final String message;
  final int totalRows;
  RestoreResult(this.ok, this.message, {this.totalRows = 0});
}

/// Full offline backup & restore of the entire PitStock database to a single
/// portable `.pitstock` JSON file. The file can be shared to Drive / WhatsApp /
/// email / local storage and re-imported on any device.
class BackupService {
  static const _magic = 'PitStockBackup';
  static const _format = 1;

  final _db = DatabaseHelper.instance;

  /// Build the backup JSON string (also used for an automatic local copy).
  Future<String> _buildJson() async {
    final tables = await _db.exportAllTables();
    final rowCount =
        tables.values.fold<int>(0, (s, list) => s + list.length);
    final payload = {
      'magic': _magic,
      'format': _format,
      'schemaVersion': _db.schemaVersion,
      'app': 'PitStock',
      'createdAt': DateTime.now().toIso8601String(),
      'rowCount': rowCount,
      'tables': tables,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _fileName() {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'pitstock_backup_$stamp.pitstock';
  }

  /// Create a backup file and open the share sheet so the user can save it
  /// anywhere (Drive, email, WhatsApp, Files…). Returns the temp file path.
  Future<String> createAndShare() async {
    final json = await _buildJson();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName()}');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)],
        text: 'PitStock inventory backup');
    return file.path;
  }

  /// Save a backup copy into the app's documents directory (no share sheet).
  /// Useful for a quick on-device snapshot.
  Future<String> saveLocalCopy() async {
    final json = await _buildJson();
    final dir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${dir.path}/backups');
    if (!backupsDir.existsSync()) backupsDir.createSync(recursive: true);
    final file = File('${backupsDir.path}/${_fileName()}');
    await file.writeAsString(json);
    return file.path;
  }

  /// List previously saved local backups (newest first).
  Future<List<FileSystemEntity>> listLocalBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${dir.path}/backups');
    if (!backupsDir.existsSync()) return [];
    final files = backupsDir
        .listSync()
        .where((f) => f.path.endsWith('.pitstock'))
        .toList();
    files.sort((a, b) =>
        b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  /// Let the user pick a `.pitstock` file and restore from it.
  Future<RestoreResult> pickAndRestore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) {
      return RestoreResult(false, 'No file selected.');
    }
    return restoreFromPath(result.files.single.path!);
  }

  /// Restore from a specific file path.
  Future<RestoreResult> restoreFromPath(String path) async {
    try {
      final raw = await File(path).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['magic'] != _magic) {
        return RestoreResult(
            false, 'This is not a valid PitStock backup file.');
      }
      final tablesRaw = decoded['tables'];
      if (tablesRaw is! Map) {
        return RestoreResult(false, 'Backup file is corrupt (no tables).');
      }

      final tables = <String, List<Map<String, dynamic>>>{};
      tablesRaw.forEach((key, value) {
        if (value is List) {
          tables[key as String] = value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      });

      await _db.importAllTables(tables);
      final total =
          tables.values.fold<int>(0, (s, list) => s + list.length);
      return RestoreResult(true, 'Restored $total records successfully.',
          totalRows: total);
    } catch (e) {
      return RestoreResult(false, 'Restore failed: $e');
    }
  }

  /// Summarise a backup file for the confirm dialog without importing it.
  Future<Map<String, dynamic>?> inspect(String path) async {
    try {
      final raw = await File(path).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['magic'] != _magic) return null;
      return {
        'createdAt': decoded['createdAt'],
        'rowCount': decoded['rowCount'],
        'schemaVersion': decoded['schemaVersion'],
      };
    } catch (_) {
      return null;
    }
  }
}
