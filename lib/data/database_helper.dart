import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/part.dart';
import '../models/stock_movement.dart';
import '../models/work_order.dart';
import '../models/app_user.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/invoice.dart';

/// SQLite, offline-first persistence for PitStock.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'pitstock.db';
  static const _dbVersion = 3;

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
      final addsV2 = {
        'partType': "TEXT DEFAULT 'aftermarket'",
        'yearFrom': 'INTEGER',
        'yearTo': 'INTEGER',
        'coreCharge': 'REAL DEFAULT 0',
        'hasCore': 'INTEGER DEFAULT 0',
        'shelf': 'TEXT',
        'bin': 'TEXT',
      };
      for (final e in addsV2.entries) {
        try {
          await db.execute('ALTER TABLE parts ADD COLUMN ${e.key} ${e.value}');
        } catch (_) {}
      }
      await _createV2Tables(db);
    }
    if (oldV < 3) {
      final addsV3Parts = {
        'minStock': 'INTEGER DEFAULT 2',
        'maxStock': 'INTEGER DEFAULT 50',
        'reorderQty': 'INTEGER DEFAULT 10',
        'warrantyMonths': 'INTEGER DEFAULT 0',
      };
      for (final e in addsV3Parts.entries) {
        try {
          await db.execute('ALTER TABLE parts ADD COLUMN ${e.key} ${e.value}');
        } catch (_) {}
      }
      final addsV3WorkOrders = {
        'customerId': 'TEXT',
        'technician': 'TEXT',
        'odometer': 'INTEGER',
        'fuelLevel': 'TEXT',
        'complaints': 'TEXT',
        'internalNotes': 'TEXT',
        'estimatedCompletion': 'TEXT',
        'discount': 'REAL DEFAULT 0',
      };
      for (final e in addsV3WorkOrders.entries) {
        try {
          await db.execute('ALTER TABLE work_orders ADD COLUMN ${e.key} ${e.value}');
        } catch (_) {}
      }
      final addsV3Invoices = {
        'customerId': 'TEXT',
        'customerGstin': 'TEXT',
        'vehicleInfo': 'TEXT',
        'discountAmount': 'REAL DEFAULT 0',
        'cgstTotal': 'REAL',
        'sgstTotal': 'REAL',
        'igstTotal': 'REAL DEFAULT 0',
        'paymentMethod': "TEXT DEFAULT 'cash'",
        'notes': 'TEXT',
        'isCancelled': 'INTEGER DEFAULT 0',
      };
      for (final e in addsV3Invoices.entries) {
        try {
          await db.execute('ALTER TABLE invoices ADD COLUMN ${e.key} ${e.value}');
        } catch (_) {}
      }
      await _createV3Tables(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS work_orders (
        id TEXT PRIMARY KEY,
        number TEXT,
        customerId TEXT,
        customerName TEXT,
        customerPhone TEXT,
        vehicleReg TEXT,
        vehicleInfo TEXT,
        technician TEXT,
        odometer INTEGER,
        fuelLevel TEXT,
        complaints TEXT,
        internalNotes TEXT,
        estimatedCompletion TEXT,
        discount REAL,
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
        partNumber TEXT,
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
        customerId TEXT,
        customerName TEXT,
        customerPhone TEXT,
        customerGstin TEXT,
        vehicleReg TEXT,
        vehicleInfo TEXT,
        subtotal REAL,
        discountAmount REAL,
        gstTotal REAL,
        cgstTotal REAL,
        sgstTotal REAL,
        igstTotal REAL,
        coreTotal REAL,
        grandTotal REAL,
        paymentMethod TEXT,
        linesJson TEXT,
        sourceOrderId TEXT,
        notes TEXT,
        isCancelled INTEGER,
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_images (
        id TEXT PRIMARY KEY,
        path TEXT,
        relatedRef TEXT,
        createdAt TEXT
      )
    ''');
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        company TEXT,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        gstin TEXT,
        paymentTerms TEXT,
        notes TEXT,
        rating REAL,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_orders (
        id TEXT PRIMARY KEY,
        orderNumber TEXT,
        supplierId TEXT,
        supplierName TEXT,
        status TEXT,
        expectedDate TEXT,
        receivedDate TEXT,
        subtotal REAL,
        taxTotal REAL,
        grandTotal REAL,
        notes TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_order_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId TEXT,
        partId TEXT,
        name TEXT,
        partNumber TEXT,
        quantity INTEGER,
        receivedQuantity INTEGER,
        unitCost REAL,
        taxPercent REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        gstin TEXT,
        notes TEXT,
        totalSpent REAL,
        visitCount INTEGER,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_vehicles (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER,
        regNumber TEXT NOT NULL,
        vin TEXT,
        engineNo TEXT,
        fuelType TEXT,
        odometer INTEGER,
        color TEXT,
        notes TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_reg ON customer_vehicles(regNumber)');
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
        minStock INTEGER,
        maxStock INTEGER,
        reorderQty INTEGER,
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
        warrantyMonths INTEGER,
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
    await db.execute('CREATE INDEX idx_parts_barcode ON parts(barcode)');
    await db.execute('CREATE TABLE meta (k TEXT PRIMARY KEY, v TEXT)');
    await _createV2Tables(db);
    await _createV3Tables(db);
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

  Future<List<StockMovement>> getMovements({String? partId, int limit = 200}) async {
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
  Future<void> insertInvoice(Invoice inv) async {
    final db = await database;
    await db.insert('invoices', inv.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final rows = await db.query('invoices', orderBy: 'createdAt DESC');
    return rows.map(Invoice.fromMap).toList();
  }

  Future<void> cancelInvoice(String id) async {
    final db = await database;
    await db.update('invoices', {'isCancelled': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Suppliers ----
  Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    final rows = await db.query('suppliers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<void> upsertSupplier(Supplier s) async {
    final db = await database;
    await db.insert('suppliers', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertSuppliersBatch(List<Supplier> suppliers) async {
    final db = await database;
    final batch = db.batch();
    for (final s in suppliers) {
      batch.insert('suppliers', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteSupplier(String id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Purchase Orders ----
  Future<void> upsertPurchaseOrder(PurchaseOrder po) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('purchase_orders', po.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('purchase_order_lines',
          where: 'orderId = ?', whereArgs: [po.id]);
      for (final l in po.lines) {
        final m = l.toMap()..['orderId'] = po.id;
        await txn.insert('purchase_order_lines', m);
      }
    });
  }

  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final db = await database;
    final rows = await db.query('purchase_orders', orderBy: 'createdAt DESC');
    final result = <PurchaseOrder>[];
    for (final r in rows) {
      final lineRows = await db.query('purchase_order_lines',
          where: 'orderId = ?', whereArgs: [r['id']]);
      final lines = lineRows.map(PurchaseOrderLine.fromMap).toList();
      result.add(PurchaseOrder.fromMap(r, lines));
    }
    return result;
  }

  Future<void> deletePurchaseOrder(String id) async {
    final db = await database;
    await db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    await db.delete('purchase_order_lines', where: 'orderId = ?', whereArgs: [id]);
  }

  // ---- Customers & Vehicles ----
  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final cRows = await db.query('customers', orderBy: 'name COLLATE NOCASE');
    final result = <Customer>[];
    for (final cr in cRows) {
      final vRows = await db.query('customer_vehicles',
          where: 'customerId = ?', whereArgs: [cr['id']]);
      final vehicles = vRows.map(CustomerVehicle.fromMap).toList();
      result.add(Customer.fromMap(cr, vehicles));
    }
    return result;
  }

  Future<void> upsertCustomer(Customer c) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('customers', c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('customer_vehicles',
          where: 'customerId = ?', whereArgs: [c.id]);
      for (final v in c.vehicles) {
        await txn.insert('customer_vehicles', v.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> insertCustomersBatch(List<Customer> customers) async {
    final db = await database;
    final batch = db.batch();
    for (final c in customers) {
      batch.insert('customers', c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final v in c.vehicles) {
        batch.insert('customer_vehicles', v.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await db.delete('customer_vehicles', where: 'customerId = ?', whereArgs: [id]);
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

  static const backupTables = <String>[
    'parts',
    'movements',
    'meta',
    'work_orders',
    'work_order_lines',
    'invoices',
    'users',
    'invoice_images',
    'suppliers',
    'purchase_orders',
    'purchase_order_lines',
    'customers',
    'customer_vehicles',
  ];

  int get schemaVersion => _dbVersion;

  Future<Map<String, List<Map<String, dynamic>>>> exportAllTables() async {
    final db = await database;
    final out = <String, List<Map<String, dynamic>>>{};
    for (final t in backupTables) {
      try {
        out[t] = await db.query(t);
      } catch (_) {
        out[t] = const [];
      }
    }
    return out;
  }

  Future<void> importAllTables(
      Map<String, List<Map<String, dynamic>>> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in backupTables) {
        try {
          await txn.delete(t);
        } catch (_) {}
      }
      for (final t in backupTables) {
        final rows = data[t];
        if (rows == null) continue;
        for (final row in rows) {
          try {
            await txn.insert(t, Map<String, dynamic>.from(row),
                conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (_) {}
        }
      }
    });
  }
}
