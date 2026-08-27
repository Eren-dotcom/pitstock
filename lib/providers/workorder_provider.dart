import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/work_order.dart';
import '../models/stock_movement.dart';
import 'inventory_provider.dart';
import 'customer_provider.dart';

/// Manages garage job cards / work orders and the auto-deduct of parts
/// from inventory when a work order is completed.
class WorkOrderProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<WorkOrder> _orders = [];
  bool _loading = true;

  List<WorkOrder> get orders => _orders;
  bool get loading => _loading;

  List<WorkOrder> get openOrders => _orders
      .where((o) =>
          o.status != WorkOrderStatus.completed &&
          o.status != WorkOrderStatus.cancelled)
      .toList();

  List<WorkOrder> get completedOrders => _orders
      .where((o) => o.status == WorkOrderStatus.completed)
      .toList();

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    _orders = await _db.getWorkOrders();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => bootstrap();

  String _nextNumber() {
    final n = _orders.length + 1;
    return 'JOB-${n.toString().padLeft(4, '0')}';
  }

  WorkOrder? byId(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  List<WorkOrder> searchOrders(String query) {
    if (query.trim().isEmpty) return _orders;
    final q = query.toLowerCase().trim();
    return _orders.where((o) {
      return o.number.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          (o.customerPhone != null && o.customerPhone!.contains(q)) ||
          (o.vehicleReg != null && o.vehicleReg!.toLowerCase().contains(q)) ||
          (o.technician != null && o.technician!.toLowerCase().contains(q));
    }).toList();
  }

  Future<WorkOrder> create({
    String? customerId,
    required String customerName,
    String? customerPhone,
    String? vehicleReg,
    String? vehicleInfo,
    String? technician,
    int? odometer,
    String? fuelLevel,
    String? complaints,
    String? internalNotes,
    DateTime? estimatedCompletion,
    double discount = 0.0,
  }) async {
    final now = DateTime.now();
    final wo = WorkOrder(
      id: _uuid.v4(),
      number: _nextNumber(),
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      vehicleReg: vehicleReg,
      vehicleInfo: vehicleInfo,
      technician: technician,
      odometer: odometer,
      fuelLevel: fuelLevel,
      complaints: complaints,
      internalNotes: internalNotes,
      estimatedCompletion: estimatedCompletion,
      discount: discount,
      createdAt: now,
      updatedAt: now,
    );
    await _db.upsertWorkOrder(wo);
    _orders.insert(0, wo);
    notifyListeners();
    return wo;
  }

  Future<void> save(WorkOrder wo) async {
    wo.updatedAt = DateTime.now();
    await _db.upsertWorkOrder(wo);
    final i = _orders.indexWhere((o) => o.id == wo.id);
    if (i >= 0) _orders[i] = wo;
    notifyListeners();
  }

  Future<void> updateStatus(WorkOrder wo, WorkOrderStatus newStatus) async {
    wo.status = newStatus;
    await save(wo);
  }

  Future<void> delete(String id) async {
    await _db.deleteWorkOrder(id);
    _orders.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  /// Complete a work order → AUTO-DEDUCT part lines from inventory (once).
  /// Returns a list of warnings (e.g. insufficient stock).
  Future<List<String>> complete(
    WorkOrder wo,
    InventoryProvider inventory, {
    CustomerProvider? customerProvider,
  }) async {
    final warnings = <String>[];
    if (!wo.stockDeducted) {
      for (final line
          in wo.lines.where((l) => !l.isLabour && l.partId.isNotEmpty)) {
        final part = inventory.byId(line.partId);
        if (part == null) continue;
        if (part.quantity < line.quantity) {
          warnings.add(
              '${part.name}: only ${part.quantity} in stock, ${line.quantity} needed');
        }
        await inventory.adjustStock(line.partId, -line.quantity,
            type: MovementType.stockOut,
            reference: 'Job ${wo.number} • ${wo.customerName}');
      }
      wo.stockDeducted = true;
    }
    wo.status = WorkOrderStatus.completed;
    await save(wo);

    // Update customer stats
    if (wo.customerId != null && customerProvider != null) {
      await customerProvider.recordTransaction(wo.customerId!, wo.grandTotal);
    }

    return warnings;
  }
}
