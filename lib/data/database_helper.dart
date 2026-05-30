import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/part.dart';
import '../models/stock_movement.dart';
import '../models/work_order.dart';
import '../models/app_user.dart';

/// SQLite, offline-first persistence for PitStock.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'pitstock.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      // Add new part columns
      final adds = {
        'partType': "TEXT DEFAULT 'aftermarket'",
        'yearFrom': 'INTEGER',
        'yearTo': 'INTEGER',
        'coreCharge': 'REAL DEFAULT 0',
        'hasCore': 'INTEGER DEFAULT 0',
        'shelf': 'TEXT',
        'bin': 'TEXT',
      };
      for (final e in adds.entries) {
        try {
          await db.execute('ALTER TABLE parts ADD COLUMN ${e.key} ${e.value}');
        } catch (_) {}
      }
      await _createV2Tables(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS work_orders (
        id TEXT PRIMARY KEY,
        number TEXT,
        customerName TEXT,
        customerPhone TEXT,
        vehicleReg TEXT,
        vehicleInfo TEXT,
        status TEXT,
        stockDeducted INTEGER,
        invoiceId TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS work_order_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId TEXT,
        partId TEXT,
        name TEXT,
        quantity INTEGER,
        price REAL,
        gstPercent REAL,
        coreCharge REAL,
        isLabour INTEGER,
        coreReturned INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        number TEXT,
        customerName TEXT,
        customerPhone TEXT,
        vehicleReg TEXT,
        subtotal REAL,
        gstTotal REAL,
        coreTotal REAL,
        grandTotal REAL,
        linesJson TEXT,
        sourceOrderId TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT,
        pin TEXT,
        role TEXT
      )
    ''');
    // Secured invoice images (RBAC) — only path metadata stored.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_images (
        id TEXT PRIMARY KEY,
        path TEXT,
        relatedRef TEXT,
        createdAt TEXT
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        partNumber TEXT,
        brand TEXT,
        category TEXT,
        partType TEXT,
        vehicleMake TEXT,
        vehicleModel TEXT,
        yearFrom INTEGER,
        yearTo INTEGER,
        unit TEXT,
        quantity INTEGER,
        lowStockThreshold INTEGER,
        costPrice REAL,
        sellingPrice REAL,
        gstPercent REAL,
        coreCharge REAL,
        hasCore INTEGER,
        shelf TEXT,
        bin TEXT,
        barcode TEXT,
        location TEXT,
        supplier TEXT,
        imagePath TEXT,
        notes TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE movements (
        id TEXT PRIMARY KEY,
        partId TEXT,
        type TEXT,
        delta INTEGER,
        reference TEXT,
        date TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_parts_name ON parts(name)');
    await db.execute('CREATE INDEX idx_parts_brand ON parts(brand)');
    await db.execute('CREATE INDEX idx_parts_category ON parts(category)');
    await db.execute('CREATE TABLE meta (k TEXT PRIMARY KEY, v TEXT)');
    await _createV2Tables(db);
  }

  // ---- Parts CRUD ----
  Future<List<Part>> getAllParts() async {
    final db = await database;
    final rows = await db.query('parts', orderBy: 'name COLLATE NOCASE');
    return rows.map(Part.fromMap).toList();
  }

  Future<void> insertPart(Part p) async {
    final db = await database;
    await db.insert('parts', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertPartsBatch(List<Part> parts) async {
    final db = await database;
    final batch = db.batch();
    for (final p in parts) {
      batch.insert('parts', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updatePart(Part p) async {
    final db = await database;
    await db.update('parts', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deletePart(String id) async {
    final db = await database;
    await db.delete('parts', where: 'id = ?', whereArgs: [id]);
    await db.delete('movements', where: 'partId = ?', whereArgs: [id]);
  }

  // ---- Movements ----
  Future<void> insertMovement(StockMovement m) async {
    final db = await database;
    await db.insert('movements', m.toMap());
  }

  Future<List<StockMovement>> getMovements({String? partId, int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'movements',
      where: partId != null ? 'partId = ?' : null,
      whereArgs: partId != null ? [partId] : null,
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(StockMovement.fromMap).toList();
  }

  // ---- Meta (seed flags etc.) ----
  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query('meta', where: 'k = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['v'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert('meta', {'k': key, 'v': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---- Work orders ----
  Future<void> upsertWorkOrder(WorkOrder wo) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('work_orders', wo.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn
          .delete('work_order_lines', where: 'orderId = ?', whereArgs: [wo.id]);
      for (final l in wo.lines) {
        final m = l.toMap()..['orderId'] = wo.id;
        await txn.insert('work_order_lines', m);
      }
    });
  }

  Future<List<WorkOrder>> getWorkOrders() async {
    final db = await database;
    final rows = await db.query('work_orders', orderBy: 'createdAt DESC');
    final result = <WorkOrder>[];
    for (final r in rows) {
      final lineRows = await db.query('work_order_lines',
          where: 'orderId = ?', whereArgs: [r['id']]);
      final lines = lineRows.map(WorkOrderLine.fromMap).toList();
      result.add(WorkOrder.fromMap(r, lines));
    }
    return result;
  }

  Future<void> deleteWorkOrder(String id) async {
    final db = await database;
    await db.delete('work_orders', where: 'id = ?', whereArgs: [id]);
    await db.delete('work_order_lines', where: 'orderId = ?', whereArgs: [id]);
  }

  // ---- Invoices ----
  Future<void> insertInvoice(Map<String, dynamic> invoiceRow) async {
    final db = await database;
    await db.insert('invoices', invoiceRow,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await database;
    return db.query('invoices', orderBy: 'createdAt DESC');
  }

  // ---- Users (RBAC) ----
  Future<List<AppUser>> getUsers() async {
    final db = await database;
    final rows = await db.query('users');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<void> upsertUser(AppUser u) async {
    final db = await database;
    await db.insert('users', u.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Secured invoice images (RBAC restricted) ----
  Future<void> saveInvoiceImage(
      String id, String path, String? ref) async {
    final db = await database;
    await db.insert('invoice_images', {
      'id': id,
      'path': path,
      'relatedRef': ref,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getInvoiceImages() async {
    final db = await database;
    return db.query('invoice_images', orderBy: 'createdAt DESC');
  }

  // ---- Full backup / restore (all tables) ----

  /// Every user-data table we back up. (Order matters for restore: parents
  /// before children where relevant, though we wipe+reinsert all anyway.)
  static const backupTables = <String>[
    'parts',
    'movements',
    'meta',
    'work_orders',
    'work_order_lines',
    'invoices',
    'users',
    'invoice_images',
  ];

  int get schemaVersion => _dbVersion;

  /// Dump every row of every table into a plain map (JSON-serialisable).
  Future<Map<String, List<Map<String, dynamic>>>> exportAllTables() async {
    final db = await database;
    final out = <String, List<Map<String, dynamic>>>{};
    for (final t in backupTables) {
      try {
        out[t] = await db.query(t);
      } catch (_) {
        out[t] = const []; // table may not exist on very old installs
      }
    }
    return out;
  }

  /// Wipe all tables and reinsert from a backup snapshot, atomically.
  Future<void> importAllTables(
      Map<String, List<Map<String, dynamic>>> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in backupTables) {
        try {
          await txn.delete(t);
        } catch (_) {/* ignore missing table */}
      }
      for (final t in backupTables) {
        final rows = data[t];
        if (rows == null) continue;
        for (final row in rows) {
          try {
            await txn.insert(t, Map<String, dynamic>.from(row),
                conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (_) {/* skip incompatible row */}
        }
      }
    });
  }
}
