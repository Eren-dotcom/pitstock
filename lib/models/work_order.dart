enum WorkOrderStatus { open, inProgress, completed, cancelled }

extension WorkOrderStatusX on WorkOrderStatus {
  String get label => switch (this) {
        WorkOrderStatus.open => 'Open',
        WorkOrderStatus.inProgress => 'In Progress',
        WorkOrderStatus.completed => 'Completed',
        WorkOrderStatus.cancelled => 'Cancelled',
      };
}

/// A line of parts/labour consumed on a job card.
class WorkOrderLine {
  final String partId; // empty for labour lines
  final String name;
  int quantity;
  double price;
  double gstPercent;
  double coreCharge;
  bool isLabour;
  bool coreReturned; // old core handed back by customer?

  WorkOrderLine({
    required this.partId,
    required this.name,
    this.quantity = 1,
    this.price = 0,
    this.gstPercent = 18,
    this.coreCharge = 0,
    this.isLabour = false,
    this.coreReturned = false,
  });

  double get lineSubtotal => quantity * price;
  double get lineGst => lineSubtotal * gstPercent / 100;
  // Core charge applies when an old core is NOT returned.
  double get lineCore => coreReturned ? 0 : coreCharge * quantity;
  double get lineTotal => lineSubtotal + lineGst + lineCore;

  Map<String, dynamic> toMap() => {
        'partId': partId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'gstPercent': gstPercent,
        'coreCharge': coreCharge,
        'isLabour': isLabour ? 1 : 0,
        'coreReturned': coreReturned ? 1 : 0,
      };

  factory WorkOrderLine.fromMap(Map<String, dynamic> m) => WorkOrderLine(
        partId: m['partId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        price: (m['price'] as num?)?.toDouble() ?? 0,
        gstPercent: (m['gstPercent'] as num?)?.toDouble() ?? 18,
        coreCharge: (m['coreCharge'] as num?)?.toDouble() ?? 0,
        isLabour: (m['isLabour'] as num?)?.toInt() == 1,
        coreReturned: (m['coreReturned'] as num?)?.toInt() == 1,
      );
}

/// A garage job card / work order. When completed, part lines are
/// auto-deducted from inventory.
class WorkOrder {
  final String id;
  String number; // human-friendly e.g. JOB-0001
  String customerName;
  String? customerPhone;
  String? vehicleReg;
  String? vehicleInfo;
  WorkOrderStatus status;
  List<WorkOrderLine> lines;
  bool stockDeducted; // guard so we deduct only once
  String? invoiceId;
  DateTime createdAt;
  DateTime updatedAt;

  WorkOrder({
    required this.id,
    required this.number,
    required this.customerName,
    this.customerPhone,
    this.vehicleReg,
    this.vehicleInfo,
    this.status = WorkOrderStatus.open,
    List<WorkOrderLine>? lines,
    this.stockDeducted = false,
    this.invoiceId,
    required this.createdAt,
    required this.updatedAt,
  }) : lines = lines ?? [];

  double get subtotal => lines.fold(0.0, (s, l) => s + l.lineSubtotal);
  double get gstTotal => lines.fold(0.0, (s, l) => s + l.lineGst);
  double get coreTotal => lines.fold(0.0, (s, l) => s + l.lineCore);
  double get grandTotal => lines.fold(0.0, (s, l) => s + l.lineTotal);
  int get partCount =>
      lines.where((l) => !l.isLabour).fold(0, (s, l) => s + l.quantity);

  Map<String, dynamic> toMap() => {
        'id': id,
        'number': number,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'vehicleReg': vehicleReg,
        'vehicleInfo': vehicleInfo,
        'status': status.name,
        'stockDeducted': stockDeducted ? 1 : 0,
        'invoiceId': invoiceId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WorkOrder.fromMap(
          Map<String, dynamic> m, List<WorkOrderLine> lines) =>
      WorkOrder(
        id: m['id'] as String,
        number: m['number'] as String,
        customerName: m['customerName'] as String? ?? '',
        customerPhone: m['customerPhone'] as String?,
        vehicleReg: m['vehicleReg'] as String?,
        vehicleInfo: m['vehicleInfo'] as String?,
        status: WorkOrderStatus.values.firstWhere(
            (e) => e.name == m['status'],
            orElse: () => WorkOrderStatus.open),
        lines: lines,
        stockDeducted: (m['stockDeducted'] as num?)?.toInt() == 1,
        invoiceId: m['invoiceId'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
}
