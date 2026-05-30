import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/work_order.dart';

/// Stores generated GST invoices (POS) for history.
class InvoiceProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> get invoices => _invoices;

  Future<void> bootstrap() async {
    _invoices = await _db.getInvoices();
    notifyListeners();
  }

  String _nextNumber() {
    final n = _invoices.length + 1;
    final yy = DateTime.now().year % 100;
    return 'INV/$yy/${n.toString().padLeft(4, '0')}';
  }

  Future<Map<String, dynamic>> createFromWorkOrder(WorkOrder wo) async {
    final row = {
      'id': _uuid.v4(),
      'number': _nextNumber(),
      'customerName': wo.customerName,
      'customerPhone': wo.customerPhone,
      'vehicleReg': wo.vehicleReg,
      'subtotal': wo.subtotal,
      'gstTotal': wo.gstTotal,
      'coreTotal': wo.coreTotal,
      'grandTotal': wo.grandTotal,
      'linesJson': jsonEncode(wo.lines.map((l) => l.toMap()).toList()),
      'sourceOrderId': wo.id,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _db.insertInvoice(row);
    _invoices.insert(0, row);
    notifyListeners();
    return row;
  }

  Future<Map<String, dynamic>> createDirect({
    required String customerName,
    String? customerPhone,
    String? vehicleReg,
    required List<WorkOrderLine> lines,
  }) async {
    final subtotal = lines.fold(0.0, (s, l) => s + l.lineSubtotal);
    final gst = lines.fold(0.0, (s, l) => s + l.lineGst);
    final core = lines.fold(0.0, (s, l) => s + l.lineCore);
    final grand = lines.fold(0.0, (s, l) => s + l.lineTotal);
    final row = {
      'id': _uuid.v4(),
      'number': _nextNumber(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vehicleReg': vehicleReg,
      'subtotal': subtotal,
      'gstTotal': gst,
      'coreTotal': core,
      'grandTotal': grand,
      'linesJson': jsonEncode(lines.map((l) => l.toMap()).toList()),
      'sourceOrderId': null,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _db.insertInvoice(row);
    _invoices.insert(0, row);
    notifyListeners();
    return row;
  }
}
