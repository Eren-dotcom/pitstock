import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/supplier.dart';
import '../models/stock_movement.dart';
import 'inventory_provider.dart';

/// Manages vendors/suppliers and purchase orders.
class SupplierProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<Supplier> _suppliers = [];
  List<PurchaseOrder> _purchaseOrders = [];
  bool _loading = true;

  List<Supplier> get suppliers => _suppliers;
  List<PurchaseOrder> get purchaseOrders => _purchaseOrders;
  bool get loading => _loading;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    _suppliers = await _db.getSuppliers();
    _purchaseOrders = await _db.getPurchaseOrders();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => bootstrap();

  Supplier? byId(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---- Supplier CRUD ----
  Future<Supplier> addSupplier({
    required String name,
    String? company,
    required String phone,
    String? email,
    String? address,
    String? gstin,
    String? paymentTerms,
    String? notes,
    double rating = 5.0,
  }) async {
    final s = Supplier(
      id: _uuid.v4(),
      name: name,
      company: company,
      phone: phone,
      email: email,
      address: address,
      gstin: gstin,
      paymentTerms: paymentTerms,
      notes: notes,
      rating: rating,
      createdAt: DateTime.now(),
    );
    await _db.upsertSupplier(s);
    _suppliers.add(s);
    _suppliers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    return s;
  }

  Future<void> updateSupplier(Supplier s) async {
    await _db.upsertSupplier(s);
    final i = _suppliers.indexWhere((e) => e.id == s.id);
    if (i >= 0) _suppliers[i] = s;
    notifyListeners();
  }

  Future<void> deleteSupplier(String id) async {
    await _db.deleteSupplier(id);
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ---- Purchase Orders ----
  String _nextPoNumber() {
    final yy = DateTime.now().year;
    final count = _purchaseOrders.length + 1;
    return 'PO-$yy-${count.toString().padLeft(4, '0')}';
  }

  Future<PurchaseOrder> createPurchaseOrder({
    required String supplierId,
    required String supplierName,
    DateTime? expectedDate,
    List<PurchaseOrderLine>? lines,
    String? notes,
  }) async {
    final now = DateTime.now();
    final po = PurchaseOrder(
      id: _uuid.v4(),
      orderNumber: _nextPoNumber(),
      supplierId: supplierId,
      supplierName: supplierName,
      status: PurchaseOrderStatus.ordered,
      expectedDate: expectedDate,
      lines: lines ?? [],
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await _db.upsertPurchaseOrder(po);
    _purchaseOrders.insert(0, po);
    notifyListeners();
    return po;
  }

  Future<void> savePurchaseOrder(PurchaseOrder po) async {
    po.updatedAt = DateTime.now();
    await _db.upsertPurchaseOrder(po);
    final i = _purchaseOrders.indexWhere((p) => p.id == po.id);
    if (i >= 0) _purchaseOrders[i] = po;
    notifyListeners();
  }

  Future<void> deletePurchaseOrder(String id) async {
    await _db.deletePurchaseOrder(id);
    _purchaseOrders.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Receive items from a purchase order into inventory.
  /// Automatically updates part quantities and adds Stock In movement records.
  Future<int> receivePurchaseOrderItems({
    required PurchaseOrder po,
    required Map<String, int> receivedQtyMap, // partId -> newly received qty
    required InventoryProvider inventory,
  }) async {
    int totalReceivedNow = 0;
    for (final line in po.lines) {
      final additionalQty = receivedQtyMap[line.partId] ?? 0;
      if (additionalQty <= 0) continue;

      line.receivedQuantity = (line.receivedQuantity + additionalQty).clamp(0, line.quantity);
      totalReceivedNow += additionalQty;

      // Update inventory stock
      if (line.partId.isNotEmpty) {
        await inventory.adjustStock(
          line.partId,
          additionalQty,
          type: MovementType.purchaseReceive,
          reference: '${po.orderNumber} • ${po.supplierName}',
        );
      }
    }

    // Update PO status
    final allReceived = po.lines.every((l) => l.receivedQuantity >= l.quantity);
    po.status = allReceived
        ? PurchaseOrderStatus.received
        : (totalReceivedNow > 0
            ? PurchaseOrderStatus.partiallyReceived
            : po.status);
    po.receivedDate = DateTime.now();
    await savePurchaseOrder(po);
    return totalReceivedNow;
  }
}
