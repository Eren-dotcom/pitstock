import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/part.dart';
import '../models/stock_movement.dart';
import '../models/scanned_item.dart';
import '../services/search_service.dart';

class InventoryProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<Part> _parts = [];
  bool _loading = true;

  List<Part> get parts => _parts;
  bool get loading => _loading;

  // ---- derived analytics ----
  int get totalSkus => _parts.length;
  int get totalUnits => _parts.fold(0, (s, p) => s + p.quantity);
  double get totalStockValue => _parts.fold(0.0, (s, p) => s + p.stockValue);
  double get totalPotentialRevenue =>
      _parts.fold(0.0, (s, p) => s + p.potentialRevenue);
  double get totalPotentialProfit => totalPotentialRevenue - totalStockValue;
  double get overallMarginPercent =>
      totalPotentialRevenue == 0 ? 0 : (totalPotentialProfit / totalPotentialRevenue) * 100;

  List<Part> get lowStock => _parts.where((p) => p.isLowStock).toList();
  List<Part> get outOfStock => _parts.where((p) => p.isOutOfStock).toList();
  List<Part> get overStock => _parts.where((p) => p.isOverstocked).toList();

  /// Estimated budget needed to bring all low & out of stock parts back to their reorderQty.
  double get estimatedReorderBudget =>
      [...outOfStock, ...lowStock].fold(0.0, (s, p) {
        final needed = (p.reorderQty - p.quantity).clamp(0, 1000);
        return s + (needed * p.costPrice);
      });

  Map<String, int> get countByCategory {
    final m = <String, int>{};
    for (final p in _parts) {
      m[p.category] = (m[p.category] ?? 0) + 1;
    }
    return m;
  }

  Map<String, double> get valueByCategory {
    final m = <String, double>{};
    for (final p in _parts) {
      m[p.category] = (m[p.category] ?? 0) + p.stockValue;
    }
    return m;
  }

  Map<String, int> get countByBrand {
    final m = <String, int>{};
    for (final p in _parts) {
      m[p.brand] = (m[p.brand] ?? 0) + 1;
    }
    return m;
  }

  Map<String, double> get valueByBrand {
    final m = <String, double>{};
    for (final p in _parts) {
      m[p.brand] = (m[p.brand] ?? 0) + p.stockValue;
    }
    return m;
  }

  List<String> get allCategories =>
      (_parts.map((p) => p.category).toSet().toList()..sort());
  List<String> get allBrands =>
      (_parts.map((p) => p.brand).toSet().toList()..sort());
  List<String> get allVehicleMakes =>
      (_parts.map((p) => p.vehicleMake).whereType<String>().toSet().toList()
        ..sort());

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    _parts = await _db.getAllParts();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => bootstrap();

  // ---- search ----
  List<Part> search(SearchFilters f) => SearchService.search(_parts, f);
  List<String> suggestions(String q) => SearchService.suggestions(_parts, q);

  Part? byId(String id) {
    try {
      return _parts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Part? byBarcode(String code) {
    try {
      return _parts.firstWhere((p) => p.barcode == code);
    } catch (_) {
      return null;
    }
  }

  Part? byPartNumber(String partNo) {
    if (partNo.trim().isEmpty) return null;
    try {
      return _parts.firstWhere(
          (p) => p.partNumber.toLowerCase() == partNo.toLowerCase().trim());
    } catch (_) {
      return null;
    }
  }

  // ---- CRUD ----
  Future<Part> addPart({
    required String name,
    String partNumber = '',
    String brand = '',
    String category = 'General',
    PartType partType = PartType.aftermarket,
    String? vehicleMake,
    String? vehicleModel,
    int? yearFrom,
    int? yearTo,
    String unit = 'pcs',
    int quantity = 0,
    int lowStockThreshold = 5,
    int minStock = 2,
    int maxStock = 50,
    int reorderQty = 10,
    double costPrice = 0,
    double sellingPrice = 0,
    double gstPercent = 18,
    double coreCharge = 0,
    bool hasCore = false,
    String? shelf,
    String? bin,
    String? barcode,
    String? location,
    String? supplier,
    String? imagePath,
    String? notes,
    int warrantyMonths = 0,
  }) async {
    final now = DateTime.now();
    final p = Part(
      id: _uuid.v4(),
      name: name,
      partNumber: partNumber,
      brand: brand,
      category: category,
      partType: partType,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      yearFrom: yearFrom,
      yearTo: yearTo,
      unit: unit,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold,
      minStock: minStock,
      maxStock: maxStock,
      reorderQty: reorderQty,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      gstPercent: gstPercent,
      coreCharge: coreCharge,
      hasCore: hasCore,
      shelf: shelf,
      bin: bin,
      barcode: barcode,
      location: location,
      supplier: supplier,
      imagePath: imagePath,
      notes: notes,
      warrantyMonths: warrantyMonths,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertPart(p);
    _parts.add(p);
    _parts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (quantity != 0) {
      await _db.insertMovement(StockMovement(
        id: _uuid.v4(),
        partId: p.id,
        type: MovementType.stockIn,
        delta: quantity,
        reference: 'Initial stock',
        unitCost: costPrice,
        date: now,
      ));
    }
    notifyListeners();
    return p;
  }

  Future<void> updatePart(Part updated) async {
    await _db.updatePart(updated);
    final i = _parts.indexWhere((p) => p.id == updated.id);
    if (i >= 0) _parts[i] = updated;
    notifyListeners();
  }

  Future<void> deletePart(String id) async {
    await _db.deletePart(id);
    _parts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<Part> clonePart(Part original) async {
    final cloned = original.copyWith(
      name: '${original.name} (Copy)',
      partNumber: original.partNumber.isNotEmpty ? '${original.partNumber}-COPY' : '',
      barcode: null,
      quantity: 0,
    );
    final now = DateTime.now();
    final p = Part(
      id: _uuid.v4(),
      name: cloned.name,
      partNumber: cloned.partNumber,
      brand: cloned.brand,
      category: cloned.category,
      partType: cloned.partType,
      vehicleMake: cloned.vehicleMake,
      vehicleModel: cloned.vehicleModel,
      yearFrom: cloned.yearFrom,
      yearTo: cloned.yearTo,
      unit: cloned.unit,
      quantity: 0,
      lowStockThreshold: cloned.lowStockThreshold,
      minStock: cloned.minStock,
      maxStock: cloned.maxStock,
      reorderQty: cloned.reorderQty,
      costPrice: cloned.costPrice,
      sellingPrice: cloned.sellingPrice,
      gstPercent: cloned.gstPercent,
      coreCharge: cloned.coreCharge,
      hasCore: cloned.hasCore,
      shelf: cloned.shelf,
      bin: cloned.bin,
      barcode: null,
      location: cloned.location,
      supplier: cloned.supplier,
      imagePath: cloned.imagePath,
      notes: cloned.notes,
      warrantyMonths: cloned.warrantyMonths,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertPart(p);
    _parts.add(p);
    notifyListeners();
    return p;
  }

  Future<void> adjustStock(
    String id,
    int delta, {
    MovementType type = MovementType.adjust,
    String? reference,
    double? unitCost,
  }) async {
    final p = byId(id);
    if (p == null) return;
    p.quantity = (p.quantity + delta).clamp(0, 1 << 31);
    p.updatedAt = DateTime.now();
    await _db.updatePart(p);
    await _db.insertMovement(StockMovement(
      id: _uuid.v4(),
      partId: id,
      type: type,
      delta: delta,
      reference: reference,
      unitCost: unitCost ?? p.costPrice,
      date: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Batch stock take / reconciliation for Physical Inventory Audit.
  Future<int> reconcilePhysicalAudit(
      Map<String, int> physicalCounts, String auditRef) async {
    int adjustedCount = 0;
    for (final entry in physicalCounts.entries) {
      final partId = entry.key;
      final countedQty = entry.value;
      final p = byId(partId);
      if (p == null) continue;
      final diff = countedQty - p.quantity;
      if (diff != 0) {
        await adjustStock(
          partId,
          diff,
          type: MovementType.stockAudit,
          reference: '$auditRef: was ${p.quantity}, counted $countedQty',
        );
        adjustedCount++;
      }
    }
    return adjustedCount;
  }

  /// Commit reviewed scanned/billed items into inventory.
  Future<int> commitScannedItems(List<ScannedItem> items,
      {required MovementType source, String? reference}) async {
    int affected = 0;
    for (final s in items.where((e) => e.selected)) {
      if (s.matchedPartId != null) {
        await adjustStock(s.matchedPartId!, s.quantity,
            type: source, reference: reference);
      } else {
        await addPart(
          name: s.name,
          partNumber: s.partNumber ?? '',
          quantity: s.quantity,
          sellingPrice: s.price,
          gstPercent: s.gstPercent ?? 18,
          notes: 'Imported via ${source.label}'
              '${reference != null ? ' • $reference' : ''}',
        );
      }
      affected++;
    }
    await refresh();
    return affected;
  }

  /// Auto-match a scanned line to an existing part.
  void autoMatch(List<ScannedItem> items) {
    for (final s in items) {
      Part? hit;
      if (s.partNumber != null && s.partNumber!.isNotEmpty) {
        try {
          hit = _parts.firstWhere((p) =>
              p.partNumber.toLowerCase() == s.partNumber!.toLowerCase());
        } catch (_) {}
      }
      hit ??= _bestNameMatch(s.name);
      if (hit != null) s.matchedPartId = hit.id;
    }
  }

  Part? _bestNameMatch(String name) {
    final f = SearchFilters(query: name, sort: SearchSort.relevance);
    final res = SearchService.search(_parts, f);
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<StockMovement>> movements({String? partId, int limit = 200}) =>
      _db.getMovements(partId: partId, limit: limit);
}
