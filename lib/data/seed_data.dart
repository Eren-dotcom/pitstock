import 'package:uuid/uuid.dart';
import '../models/part.dart';
import '../models/app_user.dart';
import 'database_helper.dart';
import 'catalogue_data.dart';

/// Seeds the Indian car spare-parts catalogue on first launch only.
class SeedData {
  static const _seedKey = 'catalogue_seeded_v1';
  static const _usersKey = 'users_seeded_v1';
  static const _uuid = Uuid();

  static Future<void> ensureSeeded(DatabaseHelper db) async {
    await _seedUsers(db);
    final done = await db.getMeta(_seedKey);
    if (done == 'true') return;

    final now = DateTime.now();
    final parts = <Part>[];
    for (final c in CatalogueData.items) {
      // OEM if brand is a genuine/OEM supplier.
      final isOem = c.brand.toLowerCase().contains('genuine') ||
          c.brand.toLowerCase().contains('mobis') ||
          c.brand == 'Kia';
      // Core charge for rebuildable/returnable units.
      final coreParts = c.category == 'Battery' ||
          c.name.toLowerCase().contains('alternator') ||
          c.name.toLowerCase().contains('starter') ||
          c.name.toLowerCase().contains('radiator');
      final core = coreParts ? (c.category == 'Battery' ? 300.0 : 500.0) : 0.0;

      // Split legacy location like "A1-01" into shelf "A1" / bin "01".
      String? shelf;
      String? bin;
      if (c.location != null && c.location!.contains('-')) {
        final parts = c.location!.split('-');
        shelf = parts.first;
        bin = parts.length > 1 ? parts[1] : null;
      }

      parts.add(Part(
        id: _uuid.v4(),
        name: c.name,
        partNumber: c.partNumber,
        brand: c.brand,
        category: c.category,
        partType: isOem ? PartType.oem : PartType.aftermarket,
        vehicleMake: c.vehicleMake,
        vehicleModel: c.vehicleModel,
        yearFrom: c.vehicleModel != null ? 2014 : null,
        yearTo: c.vehicleModel != null ? 2024 : null,
        unit: c.unit,
        quantity: c.sampleQty,
        lowStockThreshold: c.lowStock,
        costPrice: c.cost,
        sellingPrice: c.mrp,
        gstPercent: c.gst,
        coreCharge: core,
        hasCore: core > 0,
        shelf: shelf,
        bin: bin,
        barcode: c.barcode,
        location: c.location,
        supplier: c.brand,
        createdAt: now,
        updatedAt: now,
      ));
    }
    await db.insertPartsBatch(parts);
    await db.setMeta(_seedKey, 'true');
  }

  static Future<void> _seedUsers(DatabaseHelper db) async {
    final done = await db.getMeta(_usersKey);
    if (done == 'true') return;
    await db.upsertUser(AppUser(
        id: _uuid.v4(), name: 'Owner', pin: '1111', role: UserRole.owner));
    await db.upsertUser(AppUser(
        id: _uuid.v4(), name: 'Manager', pin: '2222', role: UserRole.manager));
    await db.upsertUser(AppUser(
        id: _uuid.v4(), name: 'Staff', pin: '3333', role: UserRole.staff));
    await db.setMeta(_usersKey, 'true');
  }
}
