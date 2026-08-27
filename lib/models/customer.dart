/// A vehicle owned by a customer registered in the workshop system.
class CustomerVehicle {
  final String id;
  final String customerId;
  String make; // e.g. Maruti Suzuki
  String model; // e.g. Swift Dzire
  int? year; // e.g. 2020
  String regNumber; // e.g. MH-12-AB-1234
  String? vin; // Chassis / VIN number
  String? engineNo;
  String fuelType; // Petrol, Diesel, CNG, EV, Hybrid
  int odometer; // Current km reading
  String? color;
  String? notes;

  CustomerVehicle({
    required this.id,
    required this.customerId,
    required this.make,
    required this.model,
    this.year,
    required this.regNumber,
    this.vin,
    this.engineNo,
    this.fuelType = 'Petrol',
    this.odometer = 0,
    this.color,
    this.notes,
  });

  String get displayName => '$make $model ${year != null ? '($year)' : ''} • $regNumber'.trim();

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'make': make,
        'model': model,
        'year': year,
        'regNumber': regNumber,
        'vin': vin,
        'engineNo': engineNo,
        'fuelType': fuelType,
        'odometer': odometer,
        'color': color,
        'notes': notes,
      };

  factory CustomerVehicle.fromMap(Map<String, dynamic> m) => CustomerVehicle(
        id: m['id'] as String,
        customerId: m['customerId'] as String,
        make: m['make'] as String? ?? '',
        model: m['model'] as String? ?? '',
        year: (m['year'] as num?)?.toInt(),
        regNumber: m['regNumber'] as String? ?? '',
        vin: m['vin'] as String?,
        engineNo: m['engineNo'] as String?,
        fuelType: m['fuelType'] as String? ?? 'Petrol',
        odometer: (m['odometer'] as num?)?.toInt() ?? 0,
        color: m['color'] as String?,
        notes: m['notes'] as String?,
      );

  CustomerVehicle copyWith({
    String? make,
    String? model,
    int? year,
    String? regNumber,
    String? vin,
    String? engineNo,
    String? fuelType,
    int? odometer,
    String? color,
    String? notes,
  }) {
    return CustomerVehicle(
      id: id,
      customerId: customerId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      regNumber: regNumber ?? this.regNumber,
      vin: vin ?? this.vin,
      engineNo: engineNo ?? this.engineNo,
      fuelType: fuelType ?? this.fuelType,
      odometer: odometer ?? this.odometer,
      color: color ?? this.color,
      notes: notes ?? this.notes,
    );
  }
}

/// A garage or shop customer.
class Customer {
  final String id;
  String name;
  String phone;
  String? email;
  String? address;
  String? gstin;
  String? notes;
  double totalSpent;
  int visitCount;
  DateTime createdAt;
  List<CustomerVehicle> vehicles;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.gstin,
    this.notes,
    this.totalSpent = 0.0,
    this.visitCount = 0,
    required this.createdAt,
    List<CustomerVehicle>? vehicles,
  }) : vehicles = vehicles ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
        'notes': notes,
        'totalSpent': totalSpent,
        'visitCount': visitCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(
          Map<String, dynamic> m, [List<CustomerVehicle>? vehicles]) =>
      Customer(
        id: m['id'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String?,
        address: m['address'] as String?,
        gstin: m['gstin'] as String?,
        notes: m['notes'] as String?,
        totalSpent: (m['totalSpent'] as num?)?.toDouble() ?? 0.0,
        visitCount: (m['visitCount'] as num?)?.toInt() ?? 0,
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'] as String)
            : DateTime.now(),
        vehicles: vehicles ?? [],
      );

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    String? notes,
    double? totalSpent,
    int? visitCount,
    List<CustomerVehicle>? vehicles,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      notes: notes ?? this.notes,
      totalSpent: totalSpent ?? this.totalSpent,
      visitCount: visitCount ?? this.visitCount,
      createdAt: createdAt,
      vehicles: vehicles ?? this.vehicles,
    );
  }
}
