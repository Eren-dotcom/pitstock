/// Source type of a part: genuine OEM vs aftermarket.
enum PartType { oem, aftermarket }

extension PartTypeX on PartType {
  String get label => this == PartType.oem ? 'OEM (Genuine)' : 'Aftermarket';
  String get short => this == PartType.oem ? 'OEM' : 'AFTMKT';
}

/// Core inventory entity: a spare part / SKU.
class Part {
  final String id;
  String name;
  String partNumber; // OEM / aftermarket part number
  String brand; // maker company e.g. Bosch, MRF, Exide
  String category; // e.g. Brakes, Filters, Electrical
  PartType partType; // OEM vs aftermarket
  String? vehicleMake; // e.g. Maruti Suzuki
  String? vehicleModel; // e.g. Swift
  int? yearFrom; // fitment year range start
  int? yearTo; // fitment year range end
  String unit; // pcs, set, litre, pair, box
  int quantity;
  int lowStockThreshold;
  int minStock; // safety stock minimum
  int maxStock; // rack capacity ceiling
  int reorderQty; // recommended replenishment quantity
  double costPrice;
  double sellingPrice;
  double gstPercent;
  double coreCharge; // refundable deposit for old returnable core
  bool hasCore; // does this part carry a core charge?
  String? shelf; // shelf identifier e.g. A
  String? bin; // bin identifier e.g. 01
  String? barcode;
  String? location; // legacy combined rack location
  String? supplier;
  String? imagePath;
  String? notes;
  int warrantyMonths; // warranty in months (0 = none)
  DateTime createdAt;
  DateTime updatedAt;

  Part({
    required this.id,
    required this.name,
    required this.partNumber,
    required this.brand,
    required this.category,
    this.partType = PartType.aftermarket,
    this.vehicleMake,
    this.vehicleModel,
    this.yearFrom,
    this.yearTo,
    this.unit = 'pcs',
    this.quantity = 0,
    this.lowStockThreshold = 5,
    this.minStock = 2,
    this.maxStock = 50,
    this.reorderQty = 10,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.gstPercent = 18,
    this.coreCharge = 0,
    this.hasCore = false,
    this.shelf,
    this.bin,
    this.barcode,
    this.location,
    this.supplier,
    this.imagePath,
    this.notes,
    this.warrantyMonths = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Combined shelf-bin display, falling back to legacy location.
  String get binLocation {
    if (shelf != null && bin != null) return '$shelf-$bin';
    if (shelf != null) return shelf!;
    return location ?? '—';
  }

  String get fitment {
    final v = [vehicleMake, vehicleModel].where((e) => e != null).join(' ');
    if (v.isEmpty) return 'Universal';
    if (yearFrom != null && yearTo != null) return '$v ($yearFrom–$yearTo)';
    if (yearFrom != null) return '$v ($yearFrom+)';
    return v;
  }

  bool get isLowStock => quantity <= lowStockThreshold && quantity > 0;
  bool get isOutOfStock => quantity <= 0;
  bool get isOverstocked => quantity > maxStock;
  double get stockValue => quantity * costPrice;
  double get potentialRevenue => quantity * sellingPrice;
  double get marginPercent =>
      sellingPrice == 0 ? 0 : ((sellingPrice - costPrice) / sellingPrice) * 100;
  double get grossProfitPerUnit => sellingPrice - costPrice;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'partNumber': partNumber,
        'brand': brand,
        'category': category,
        'partType': partType.name,
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'yearFrom': yearFrom,
        'yearTo': yearTo,
        'unit': unit,
        'quantity': quantity,
        'lowStockThreshold': lowStockThreshold,
        'minStock': minStock,
        'maxStock': maxStock,
        'reorderQty': reorderQty,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'gstPercent': gstPercent,
        'coreCharge': coreCharge,
        'hasCore': hasCore ? 1 : 0,
        'shelf': shelf,
        'bin': bin,
        'barcode': barcode,
        'location': location,
        'supplier': supplier,
        'imagePath': imagePath,
        'notes': notes,
        'warrantyMonths': warrantyMonths,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Part.fromMap(Map<String, dynamic> m) => Part(
        id: m['id'] as String,
        name: m['name'] as String,
        partNumber: m['partNumber'] as String? ?? '',
        brand: m['brand'] as String? ?? '',
        category: m['category'] as String? ?? 'General',
        partType: PartType.values.firstWhere(
            (e) => e.name == m['partType'],
            orElse: () => PartType.aftermarket),
        vehicleMake: m['vehicleMake'] as String?,
        vehicleModel: m['vehicleModel'] as String?,
        yearFrom: (m['yearFrom'] as num?)?.toInt(),
        yearTo: (m['yearTo'] as num?)?.toInt(),
        unit: m['unit'] as String? ?? 'pcs',
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        lowStockThreshold: (m['lowStockThreshold'] as num?)?.toInt() ?? 5,
        minStock: (m['minStock'] as num?)?.toInt() ?? 2,
        maxStock: (m['maxStock'] as num?)?.toInt() ?? 50,
        reorderQty: (m['reorderQty'] as num?)?.toInt() ?? 10,
        costPrice: (m['costPrice'] as num?)?.toDouble() ?? 0,
        sellingPrice: (m['sellingPrice'] as num?)?.toDouble() ?? 0,
        gstPercent: (m['gstPercent'] as num?)?.toDouble() ?? 18,
        coreCharge: (m['coreCharge'] as num?)?.toDouble() ?? 0,
        hasCore: (m['hasCore'] as num?)?.toInt() == 1,
        shelf: m['shelf'] as String?,
        bin: m['bin'] as String?,
        barcode: m['barcode'] as String?,
        location: m['location'] as String?,
        supplier: m['supplier'] as String?,
        imagePath: m['imagePath'] as String?,
        notes: m['notes'] as String?,
        warrantyMonths: (m['warrantyMonths'] as num?)?.toInt() ?? 0,
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'] as String)
            : DateTime.now(),
        updatedAt: m['updatedAt'] != null
            ? DateTime.parse(m['updatedAt'] as String)
            : DateTime.now(),
      );

  Part copyWith({
    String? name,
    String? partNumber,
    String? brand,
    String? category,
    PartType? partType,
    String? vehicleMake,
    String? vehicleModel,
    int? yearFrom,
    int? yearTo,
    String? unit,
    int? quantity,
    int? lowStockThreshold,
    int? minStock,
    int? maxStock,
    int? reorderQty,
    double? costPrice,
    double? sellingPrice,
    double? gstPercent,
    double? coreCharge,
    bool? hasCore,
    String? shelf,
    String? bin,
    String? barcode,
    String? location,
    String? supplier,
    String? imagePath,
    String? notes,
    int? warrantyMonths,
  }) {
    return Part(
      id: id,
      name: name ?? this.name,
      partNumber: partNumber ?? this.partNumber,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      partType: partType ?? this.partType,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      reorderQty: reorderQty ?? this.reorderQty,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      gstPercent: gstPercent ?? this.gstPercent,
      coreCharge: coreCharge ?? this.coreCharge,
      hasCore: hasCore ?? this.hasCore,
      shelf: shelf ?? this.shelf,
      bin: bin ?? this.bin,
      barcode: barcode ?? this.barcode,
      location: location ?? this.location,
      supplier: supplier ?? this.supplier,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
