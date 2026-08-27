import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/invoice.dart';
import '../models/work_order.dart';
import '../models/stock_movement.dart';
import 'inventory_provider.dart';
import 'customer_provider.dart';

/// Stores and manages generated GST invoices (POS sales & Job bills).
class InvoiceProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<Invoice> _invoices = [];
  bool _loading = true;

  List<Invoice> get invoices => _invoices;
  bool get loading => _loading;

  // Active (non-cancelled) invoices
  List<Invoice> get activeInvoices => _invoices.where((i) => !i.isCancelled).toList();

  double get totalSalesRevenue =>
      activeInvoices.fold(0.0, (s, i) => s + i.grandTotal);
  double get totalGstCollected =>
      activeInvoices.fold(0.0, (s, i) => s + i.gstTotal);
  int get totalInvoicesCount => activeInvoices.length;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    _invoices = await _db.getInvoices();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => bootstrap();

  String _nextNumber() {
    final count = _invoices.length + 1;
    final yy = DateTime.now().year % 100;
    return 'INV/$yy/${count.toString().padLeft(4, '0')}';
  }

  Invoice? byId(String id) {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Invoice> searchInvoices(String query) {
    if (query.trim().isEmpty) return _invoices;
    final q = query.toLowerCase().trim();
    return _invoices.where((i) {
      return i.number.toLowerCase().contains(q) ||
          i.customerName.toLowerCase().contains(q) ||
          (i.customerPhone != null && i.customerPhone!.contains(q)) ||
          (i.vehicleReg != null && i.vehicleReg!.toLowerCase().contains(q));
    }).toList();
  }

  Future<Invoice> createFromWorkOrder(WorkOrder wo) async {
    final lines = wo.lines.map(InvoiceLine.fromWorkOrderLine).toList();
    final subtotal = lines.fold(0.0, (s, l) => s + l.subtotal);
    final gst = lines.fold(0.0, (s, l) => s + l.gstAmount);
    final core = lines.fold(0.0, (s, l) => s + l.coreAmount);
    final grand = (subtotal + gst + core - wo.discount).clamp(0.0, double.infinity);

    final inv = Invoice(
      id: _uuid.v4(),
      number: _nextNumber(),
      customerId: wo.customerId,
      customerName: wo.customerName,
      customerPhone: wo.customerPhone,
      vehicleReg: wo.vehicleReg,
      vehicleInfo: wo.vehicleInfo,
      subtotal: subtotal,
      discountAmount: wo.discount,
      gstTotal: gst,
      cgstTotal: gst / 2,
      sgstTotal: gst / 2,
      coreTotal: core,
      grandTotal: grand,
      paymentMethod: PaymentMethod.cash,
      sourceOrderId: wo.id,
      lines: lines,
      notes: 'Generated from Job ${wo.number}',
      createdAt: DateTime.now(),
    );

    await _db.insertInvoice(inv);
    _invoices.insert(0, inv);
    notifyListeners();
    return inv;
  }

  /// Create a direct counter POS sale, auto-deducts stock and updates customer ledger.
  Future<Invoice> createDirectSale({
    String? customerId,
    required String customerName,
    String? customerPhone,
    String? customerGstin,
    String? vehicleReg,
    String? vehicleInfo,
    required List<InvoiceLine> lines,
    double discountAmount = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? notes,
    required InventoryProvider inventory,
    CustomerProvider? customerProvider,
  }) async {
    final subtotal = lines.fold(0.0, (s, l) => s + l.subtotal);
    final gst = lines.fold(0.0, (s, l) => s + l.gstAmount);
    final core = lines.fold(0.0, (s, l) => s + l.coreAmount);
    final grand = (subtotal + gst + core - discountAmount).clamp(0.0, double.infinity);
    final number = _nextNumber();

    final inv = Invoice(
      id: _uuid.v4(),
      number: number,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerGstin: customerGstin,
      vehicleReg: vehicleReg,
      vehicleInfo: vehicleInfo,
      subtotal: subtotal,
      discountAmount: discountAmount,
      gstTotal: gst,
      cgstTotal: gst / 2,
      sgstTotal: gst / 2,
      coreTotal: core,
      grandTotal: grand,
      paymentMethod: paymentMethod,
      sourceOrderId: null,
      lines: lines,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Auto-deduct inventory stock for non-labour parts
    for (final line in lines.where((l) => !l.isLabour && l.partId.isNotEmpty)) {
      await inventory.adjustStock(
        line.partId,
        -line.quantity,
        type: MovementType.sale,
        reference: '$number • $customerName',
      );
    }

    // Update customer stats if customer is linked
    if (customerId != null && customerProvider != null) {
      await customerProvider.recordTransaction(customerId, grand);
    }

    await _db.insertInvoice(inv);
    _invoices.insert(0, inv);
    notifyListeners();
    return inv;
  }

  /// Cancel an invoice and restore stock.
  Future<void> cancelAndRefundInvoice(
    String id, {
    required InventoryProvider inventory,
  }) async {
    final inv = byId(id);
    if (inv == null || inv.isCancelled) return;

    // Restore stock if it was deducted
    for (final line in inv.lines.where((l) => !l.isLabour && l.partId.isNotEmpty)) {
      await inventory.adjustStock(
        line.partId,
        line.quantity,
        type: MovementType.stockReturn,
        reference: 'Refund / Cancelled ${inv.number}',
      );
    }

    await _db.cancelInvoice(id);
    final idx = _invoices.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _invoices[idx] = Invoice(
        id: inv.id,
        number: inv.number,
        customerId: inv.customerId,
        customerName: inv.customerName,
        customerPhone: inv.customerPhone,
        customerGstin: inv.customerGstin,
        vehicleReg: inv.vehicleReg,
        vehicleInfo: inv.vehicleInfo,
        subtotal: inv.subtotal,
        discountAmount: inv.discountAmount,
        gstTotal: inv.gstTotal,
        cgstTotal: inv.cgstTotal,
        sgstTotal: inv.sgstTotal,
        igstTotal: inv.igstTotal,
        coreTotal: inv.coreTotal,
        grandTotal: inv.grandTotal,
        paymentMethod: inv.paymentMethod,
        sourceOrderId: inv.sourceOrderId,
        lines: inv.lines,
        notes: '${inv.notes ?? ''} [CANCELLED / REFUNDED]'.trim(),
        isCancelled: true,
        createdAt: inv.createdAt,
      );
    }
    notifyListeners();
  }
}
