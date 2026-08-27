enum MovementType {
  stockIn,
  stockOut,
  adjust,
  billImport,
  scanImport,
  sale,
  purchaseReceive,
  damage,
  stockReturn,
  stockAudit,
  writeOff,
}

extension MovementTypeX on MovementType {
  String get label => switch (this) {
        MovementType.stockIn => 'Stock In',
        MovementType.stockOut => 'Stock Out',
        MovementType.adjust => 'Adjustment',
        MovementType.billImport => 'Bill Import',
        MovementType.scanImport => 'Scan Import',
        MovementType.sale => 'POS Sale',
        MovementType.purchaseReceive => 'PO Receive',
        MovementType.damage => 'Damaged / Broken',
        MovementType.stockReturn => 'Customer Return',
        MovementType.stockAudit => 'Audit Reconciliation',
        MovementType.writeOff => 'Inventory Write-off',
      };

  bool get isPositive => switch (this) {
        MovementType.stockIn ||
        MovementType.billImport ||
        MovementType.scanImport ||
        MovementType.purchaseReceive ||
        MovementType.stockReturn =>
          true,
        MovementType.stockOut ||
        MovementType.sale ||
        MovementType.damage ||
        MovementType.writeOff =>
          false,
        MovementType.adjust || MovementType.stockAudit => true, // depends on delta
      };
}

/// Audit-trail of every quantity change for a part.
class StockMovement {
  final String id;
  final String partId;
  final MovementType type;
  final int delta; // +ve in, -ve out
  final String? reference; // bill no, customer, reason
  final double? unitCost;
  final DateTime date;

  StockMovement({
    required this.id,
    required this.partId,
    required this.type,
    required this.delta,
    this.reference,
    this.unitCost,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'partId': partId,
        'type': type.name,
        'delta': delta,
        'reference': reference,
        'date': date.toIso8601String(),
      };

  factory StockMovement.fromMap(Map<String, dynamic> m) => StockMovement(
        id: m['id'] as String,
        partId: m['partId'] as String,
        type: MovementType.values.firstWhere((e) => e.name == m['type'],
            orElse: () => MovementType.adjust),
        delta: (m['delta'] as num).toInt(),
        reference: m['reference'] as String?,
        date: DateTime.parse(m['date'] as String),
      );
}
