import 'dart:convert';
import 'work_order.dart';

enum PaymentMethod { cash, upi, card, netBanking, creditDue, cheque }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.upi => 'UPI / QR Code',
        PaymentMethod.card => 'Debit / Credit Card',
        PaymentMethod.netBanking => 'Net Banking',
        PaymentMethod.creditDue => 'Credit (Due)',
        PaymentMethod.cheque => 'Cheque',
      };
}

/// A line on an invoice.
class InvoiceLine {
  final String partId;
  final String name;
  final String partNumber;
  final int quantity;
  final double unitPrice;
  final double gstPercent;
  final double coreCharge;
  final bool isLabour;
  final bool coreReturned;

  InvoiceLine({
    required this.partId,
    required this.name,
    this.partNumber = '',
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.gstPercent = 18.0,
    this.coreCharge = 0.0,
    this.isLabour = false,
    this.coreReturned = false,
  });

  double get subtotal => quantity * unitPrice;
  double get gstAmount => subtotal * gstPercent / 100;
  double get coreAmount => coreReturned ? 0.0 : coreCharge * quantity;
  double get total => subtotal + gstAmount + coreAmount;

  Map<String, dynamic> toMap() => {
        'partId': partId,
        'name': name,
        'partNumber': partNumber,
        'quantity': quantity,
        'price': unitPrice,
        'gstPercent': gstPercent,
        'coreCharge': coreCharge,
        'isLabour': isLabour ? 1 : 0,
        'coreReturned': coreReturned ? 1 : 0,
      };

  factory InvoiceLine.fromMap(Map<String, dynamic> m) => InvoiceLine(
        partId: m['partId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        partNumber: m['partNumber'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (m['price'] as num?)?.toDouble() ?? 0.0,
        gstPercent: (m['gstPercent'] as num?)?.toDouble() ?? 18.0,
        coreCharge: (m['coreCharge'] as num?)?.toDouble() ?? 0.0,
        isLabour: (m['isLabour'] as num?)?.toInt() == 1,
        coreReturned: (m['coreReturned'] as num?)?.toInt() == 1,
      );

  factory InvoiceLine.fromWorkOrderLine(WorkOrderLine l) => InvoiceLine(
        partId: l.partId,
        name: l.name,
        quantity: l.quantity,
        unitPrice: l.price,
        gstPercent: l.gstPercent,
        coreCharge: l.coreCharge,
        isLabour: l.isLabour,
        coreReturned: l.coreReturned,
      );
}

/// A completed GST tax invoice / receipt.
class Invoice {
  final String id;
  final String number; // e.g. INV/26/0001
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerGstin;
  final String? vehicleReg;
  final String? vehicleInfo;
  final double subtotal;
  final double discountAmount;
  final double gstTotal;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double coreTotal;
  final double grandTotal;
  final PaymentMethod paymentMethod;
  final String? sourceOrderId;
  final List<InvoiceLine> lines;
  final String? notes;
  final bool isCancelled;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.number,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerGstin,
    this.vehicleReg,
    this.vehicleInfo,
    required this.subtotal,
    this.discountAmount = 0.0,
    required this.gstTotal,
    double? cgstTotal,
    double? sgstTotal,
    this.igstTotal = 0.0,
    required this.coreTotal,
    required this.grandTotal,
    this.paymentMethod = PaymentMethod.cash,
    this.sourceOrderId,
    required this.lines,
    this.notes,
    this.isCancelled = false,
    required this.createdAt,
  })  : cgstTotal = cgstTotal ?? (gstTotal / 2),
        sgstTotal = sgstTotal ?? (gstTotal / 2);

  int get totalItemCount => lines.fold(0, (s, l) => s + l.quantity);

  Map<String, dynamic> toMap() => {
        'id': id,
        'number': number,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerGstin': customerGstin,
        'vehicleReg': vehicleReg,
        'vehicleInfo': vehicleInfo,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'gstTotal': gstTotal,
        'cgstTotal': cgstTotal,
        'sgstTotal': sgstTotal,
        'igstTotal': igstTotal,
        'coreTotal': coreTotal,
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod.name,
        'linesJson': jsonEncode(lines.map((l) => l.toMap()).toList()),
        'sourceOrderId': sourceOrderId,
        'notes': notes,
        'isCancelled': isCancelled ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Invoice.fromMap(Map<String, dynamic> m) {
    List<InvoiceLine> parsedLines = [];
    if (m['linesJson'] != null && (m['linesJson'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(m['linesJson'] as String) as List;
        parsedLines = decoded
            .map((e) => InvoiceLine.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }
    return Invoice(
      id: m['id'] as String,
      number: m['number'] as String,
      customerId: m['customerId'] as String?,
      customerName: m['customerName'] as String? ?? 'Walk-in Customer',
      customerPhone: m['customerPhone'] as String?,
      customerGstin: m['customerGstin'] as String?,
      vehicleReg: m['vehicleReg'] as String?,
      vehicleInfo: m['vehicleInfo'] as String?,
      subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (m['discountAmount'] as num?)?.toDouble() ?? 0.0,
      gstTotal: (m['gstTotal'] as num?)?.toDouble() ?? 0.0,
      cgstTotal: (m['cgstTotal'] as num?)?.toDouble(),
      sgstTotal: (m['sgstTotal'] as num?)?.toDouble(),
      igstTotal: (m['igstTotal'] as num?)?.toDouble() ?? 0.0,
      coreTotal: (m['coreTotal'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (m['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.name == m['paymentMethod'],
          orElse: () => PaymentMethod.cash),
      sourceOrderId: m['sourceOrderId'] as String?,
      lines: parsedLines,
      notes: m['notes'] as String?,
      isCancelled: (m['isCancelled'] as num?)?.toInt() == 1,
      createdAt: m['createdAt'] != null
          ? DateTime.parse(m['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
