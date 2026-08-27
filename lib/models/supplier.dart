enum PurchaseOrderStatus { draft, ordered, partiallyReceived, received, cancelled }

extension PurchaseOrderStatusX on PurchaseOrderStatus {
  String get label => switch (this) {
        PurchaseOrderStatus.draft => 'Draft',
        PurchaseOrderStatus.ordered => 'Ordered',
        PurchaseOrderStatus.partiallyReceived => 'Partially Received',
        PurchaseOrderStatus.received => 'Received',
        PurchaseOrderStatus.cancelled => 'Cancelled',
      };
}

/// Vendor / Supplier providing spare parts.
class Supplier {
  final String id;
  String name;
  String? company;
  String phone;
  String? email;
  String? address;
  String? gstin;
  String? paymentTerms; // e.g. "Net 30", "Immediate", "Credit"
  String? notes;
  double rating; // 1 to 5 stars
  DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.company,
    required this.phone,
    this.email,
    this.address,
    this.gstin,
    this.paymentTerms = 'Credit 30 Days',
    this.notes,
    this.rating = 5.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'company': company,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
        'paymentTerms': paymentTerms,
        'notes': notes,
        'rating': rating,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
        id: m['id'] as String,
        name: m['name'] as String,
        company: m['company'] as String?,
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String?,
        address: m['address'] as String?,
        gstin: m['gstin'] as String?,
        paymentTerms: m['paymentTerms'] as String? ?? 'Credit 30 Days',
        notes: m['notes'] as String?,
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'] as String)
            : DateTime.now(),
      );

  Supplier copyWith({
    String? name,
    String? company,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    String? paymentTerms,
    String? notes,
    double? rating,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      createdAt: createdAt,
    );
  }
}

/// Line item on a Purchase Order.
class PurchaseOrderLine {
  final String partId;
  String name;
  String partNumber;
  int quantity;
  int receivedQuantity;
  double unitCost;
  double taxPercent;

  PurchaseOrderLine({
    required this.partId,
    required this.name,
    this.partNumber = '',
    required this.quantity,
    this.receivedQuantity = 0,
    required this.unitCost,
    this.taxPercent = 18.0,
  });

  double get subtotal => quantity * unitCost;
  double get taxAmount => subtotal * taxPercent / 100;
  double get total => subtotal + taxAmount;
  bool get isFullyReceived => receivedQuantity >= quantity;

  Map<String, dynamic> toMap() => {
        'partId': partId,
        'name': name,
        'partNumber': partNumber,
        'quantity': quantity,
        'receivedQuantity': receivedQuantity,
        'unitCost': unitCost,
        'taxPercent': taxPercent,
      };

  factory PurchaseOrderLine.fromMap(Map<String, dynamic> m) => PurchaseOrderLine(
        partId: m['partId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        partNumber: m['partNumber'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        receivedQuantity: (m['receivedQuantity'] as num?)?.toInt() ?? 0,
        unitCost: (m['unitCost'] as num?)?.toDouble() ?? 0,
        taxPercent: (m['taxPercent'] as num?)?.toDouble() ?? 18,
      );
}

/// A formal Purchase Order sent to a parts supplier.
class PurchaseOrder {
  final String id;
  String orderNumber; // e.g. PO-2026-0001
  String supplierId;
  String supplierName;
  PurchaseOrderStatus status;
  DateTime? expectedDate;
  DateTime? receivedDate;
  List<PurchaseOrderLine> lines;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  PurchaseOrder({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.supplierName,
    this.status = PurchaseOrderStatus.draft,
    this.expectedDate,
    this.receivedDate,
    List<PurchaseOrderLine>? lines,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  }) : lines = lines ?? [];

  double get subtotal => lines.fold(0.0, (s, l) => s + l.subtotal);
  double get taxTotal => lines.fold(0.0, (s, l) => s + l.taxAmount);
  double get grandTotal => lines.fold(0.0, (s, l) => s + l.total);
  int get totalItems => lines.fold(0, (s, l) => s + l.quantity);
  int get totalReceived => lines.fold(0, (s, l) => s + l.receivedQuantity);

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderNumber': orderNumber,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'status': status.name,
        'expectedDate': expectedDate?.toIso8601String(),
        'receivedDate': receivedDate?.toIso8601String(),
        'subtotal': subtotal,
        'taxTotal': taxTotal,
        'grandTotal': grandTotal,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PurchaseOrder.fromMap(
          Map<String, dynamic> m, List<PurchaseOrderLine> lines) =>
      PurchaseOrder(
        id: m['id'] as String,
        orderNumber: m['orderNumber'] as String,
        supplierId: m['supplierId'] as String? ?? '',
        supplierName: m['supplierName'] as String? ?? 'Unknown Supplier',
        status: PurchaseOrderStatus.values.firstWhere(
            (e) => e.name == m['status'],
            orElse: () => PurchaseOrderStatus.draft),
        expectedDate: m['expectedDate'] != null
            ? DateTime.parse(m['expectedDate'] as String)
            : null,
        receivedDate: m['receivedDate'] != null
            ? DateTime.parse(m['receivedDate'] as String)
            : null,
        lines: lines,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
}
