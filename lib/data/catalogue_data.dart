/// A single catalogue template entry for the Indian car spare-parts market.
class CatalogueEntry {
  final String name;
  final String partNumber;
  final String brand; // maker company
  final String category;
  final String? vehicleMake;
  final String? vehicleModel;
  final String unit;
  final int sampleQty;
  final int lowStock;
  final double cost;
  final double mrp;
  final double gst;
  final String? barcode;
  final String? location;

  const CatalogueEntry({
    required this.name,
    required this.partNumber,
    required this.brand,
    required this.category,
    this.vehicleMake,
    this.vehicleModel,
    this.unit = 'pcs',
    this.sampleQty = 10,
    this.lowStock = 4,
    this.cost = 0,
    this.mrp = 0,
    this.gst = 28,
    this.barcode,
    this.location,
  });
}

/// Curated starter catalogue of common Indian car spare parts &
/// the maker companies (brands) that supply them.
///
/// NOTE: Part numbers, prices & barcodes here are realistic SAMPLES for
/// demo/seed purposes — verify against supplier invoices before selling.
class CatalogueData {
  static const List<String> categories = [
    'Engine',
    'Brakes',
    'Suspension',
    'Filters',
    'Electrical',
    'Battery',
    'Tyres',
    'Belts & Hoses',
    'Clutch & Transmission',
    'Cooling',
    'Lighting',
    'Body & Exterior',
    'Lubricants & Fluids',
    'Ignition',
    'Steering',
    'Wipers',
    'Bearings',
    'Exhaust',
  ];

  /// Common spare-part maker companies active in India.
  static const List<String> brands = [
    'Bosch',
    'MRF',
    'Apollo Tyres',
    'CEAT',
    'JK Tyre',
    'Exide',
    'Amaron',
    'Lucas TVS',
    'Sundaram (TVS)',
    'Brakes India',
    'Rane',
    'Gabriel',
    'Endurance',
    'Minda',
    'Spark Minda',
    'Mahle',
    'Mann Filter',
    'Purolator',
    'Elofic',
    'Castrol',
    'Servo (IOCL)',
    'Mobil',
    'Valeo',
    'NGK',
    'Denso',
    'Fenner',
    'Gates',
    'SKF',
    'FAG',
    'Wipro (Maruti Genuine)',
    'Tata Genuine Parts',
    'Mahindra Genuine',
    'Hyundai Mobis',
  ];

  static const List<String> vehicleMakes = [
    'Maruti Suzuki',
    'Tata Motors',
    'Mahindra',
    'Hyundai',
    'Toyota',
    'Honda',
    'Kia',
    'Renault',
    'Nissan',
    'Volkswagen',
    'Skoda',
    'Universal',
  ];

  static const List<CatalogueEntry> items = [
    // ---------- Brakes ----------
    CatalogueEntry(name: 'Front Brake Pad Set', partNumber: 'BP-SWFT-FR01', brand: 'Brakes India', category: 'Brakes', vehicleMake: 'Maruti Suzuki', vehicleModel: 'Swift', unit: 'set', sampleQty: 12, lowStock: 4, cost: 620, mrp: 980, gst: 28, barcode: '8901234500011', location: 'A1-01'),
    CatalogueEntry(name: 'Rear Brake Shoe Set', partNumber: 'BS-ALTO-RR02', brand: 'Brakes India', category: 'Brakes', vehicleMake: 'Maruti Suzuki', vehicleModel: 'Alto', unit: 'set', sampleQty: 9, lowStock: 4, cost: 540, mrp: 860, gst: 28, barcode: '8901234500028', location: 'A1-02'),
    CatalogueEntry(name: 'Brake Disc Rotor (Front)', partNumber: 'BD-I20-FR03', brand: 'Bosch', category: 'Brakes', vehicleMake: 'Hyundai', vehicleModel: 'i20', unit: 'pcs', sampleQty: 6, lowStock: 2, cost: 1850, mrp: 2650, gst: 28, barcode: '8901234500035', location: 'A1-03'),
    CatalogueEntry(name: 'Brake Fluid DOT 4 (500ml)', partNumber: 'BF-DOT4-500', brand: 'Bosch', category: 'Lubricants & Fluids', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 20, lowStock: 6, cost: 180, mrp: 290, gst: 18, barcode: '8901234500042', location: 'F2-01'),

    // ---------- Filters ----------
    CatalogueEntry(name: 'Air Filter', partNumber: 'AF-SWFT-04', brand: 'Mann Filter', category: 'Filters', vehicleMake: 'Maruti Suzuki', vehicleModel: 'Swift', unit: 'pcs', sampleQty: 25, lowStock: 8, cost: 220, mrp: 420, gst: 18, barcode: '8901234500059', location: 'B1-01'),
    CatalogueEntry(name: 'Oil Filter', partNumber: 'OF-NEXON-05', brand: 'Purolator', category: 'Filters', vehicleMake: 'Tata Motors', vehicleModel: 'Nexon', unit: 'pcs', sampleQty: 30, lowStock: 10, cost: 160, mrp: 310, gst: 18, barcode: '8901234500066', location: 'B1-02'),
    CatalogueEntry(name: 'Cabin / AC Filter', partNumber: 'CF-CRETA-06', brand: 'Elofic', category: 'Filters', vehicleMake: 'Hyundai', vehicleModel: 'Creta', unit: 'pcs', sampleQty: 18, lowStock: 6, cost: 240, mrp: 460, gst: 18, barcode: '8901234500073', location: 'B1-03'),
    CatalogueEntry(name: 'Diesel Fuel Filter', partNumber: 'FF-XUV-07', brand: 'Mahle', category: 'Filters', vehicleMake: 'Mahindra', vehicleModel: 'XUV500', unit: 'pcs', sampleQty: 14, lowStock: 5, cost: 540, mrp: 880, gst: 18, barcode: '8901234500080', location: 'B1-04'),

    // ---------- Battery ----------
    CatalogueEntry(name: 'Battery 35Ah (DIN44)', partNumber: 'BAT-EX-35AH', brand: 'Exide', category: 'Battery', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 8, lowStock: 3, cost: 3800, mrp: 4900, gst: 28, barcode: '8901234500097', location: 'C1-01'),
    CatalogueEntry(name: 'Battery 45Ah', partNumber: 'BAT-AM-45AH', brand: 'Amaron', category: 'Battery', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 6, lowStock: 2, cost: 4500, mrp: 5800, gst: 28, barcode: '8901234500103', location: 'C1-02'),
    CatalogueEntry(name: 'Battery 65Ah', partNumber: 'BAT-EX-65AH', brand: 'Exide', category: 'Battery', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 5, lowStock: 2, cost: 6200, mrp: 7800, gst: 28, barcode: '8901234500110', location: 'C1-03'),

    // ---------- Tyres ----------
    CatalogueEntry(name: 'Tyre 165/80 R14', partNumber: 'TY-MRF-16580', brand: 'MRF', category: 'Tyres', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 16, lowStock: 4, cost: 3600, mrp: 4500, gst: 28, barcode: '8901234500127', location: 'D1-01'),
    CatalogueEntry(name: 'Tyre 185/65 R15', partNumber: 'TY-APL-18565', brand: 'Apollo Tyres', category: 'Tyres', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 12, lowStock: 4, cost: 4800, mrp: 6100, gst: 28, barcode: '8901234500134', location: 'D1-02'),
    CatalogueEntry(name: 'Tyre 205/55 R16', partNumber: 'TY-CEAT-20555', brand: 'CEAT', category: 'Tyres', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 10, lowStock: 4, cost: 6400, mrp: 8200, gst: 28, barcode: '8901234500141', location: 'D1-03'),

    // ---------- Lubricants & Fluids ----------
    CatalogueEntry(name: 'Engine Oil 5W-30 (3.5L)', partNumber: 'EO-CAS-5W30', brand: 'Castrol', category: 'Lubricants & Fluids', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 22, lowStock: 8, cost: 1450, mrp: 2100, gst: 18, barcode: '8901234500158', location: 'F1-01'),
    CatalogueEntry(name: 'Engine Oil 10W-40 (1L)', partNumber: 'EO-SRV-10W40', brand: 'Servo (IOCL)', category: 'Lubricants & Fluids', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 40, lowStock: 12, cost: 340, mrp: 520, gst: 18, barcode: '8901234500165', location: 'F1-02'),
    CatalogueEntry(name: 'Coolant Ready-Mix (1L)', partNumber: 'CL-MOB-1L', brand: 'Mobil', category: 'Cooling', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 26, lowStock: 8, cost: 210, mrp: 360, gst: 18, barcode: '8901234500172', location: 'F1-03'),
    CatalogueEntry(name: 'Gear Oil 80W-90 (1L)', partNumber: 'GO-CAS-8090', brand: 'Castrol', category: 'Lubricants & Fluids', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 18, lowStock: 6, cost: 260, mrp: 420, gst: 18, barcode: '8901234500189', location: 'F1-04'),

    // ---------- Ignition ----------
    CatalogueEntry(name: 'Spark Plug (Iridium)', partNumber: 'SP-NGK-IR08', brand: 'NGK', category: 'Ignition', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 60, lowStock: 16, cost: 320, mrp: 520, gst: 28, barcode: '8901234500196', location: 'E1-01'),
    CatalogueEntry(name: 'Spark Plug (Standard)', partNumber: 'SP-DNS-ST09', brand: 'Denso', category: 'Ignition', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 80, lowStock: 20, cost: 110, mrp: 190, gst: 28, barcode: '8901234500202', location: 'E1-02'),
    CatalogueEntry(name: 'Ignition Coil', partNumber: 'IC-CRETA-10', brand: 'Bosch', category: 'Ignition', vehicleMake: 'Hyundai', vehicleModel: 'Creta', unit: 'pcs', sampleQty: 8, lowStock: 3, cost: 1850, mrp: 2700, gst: 28, barcode: '8901234500219', location: 'E1-03'),

    // ---------- Electrical & Lighting ----------
    CatalogueEntry(name: 'Headlight Bulb H4 (12V 60/55W)', partNumber: 'HL-PH-H4', brand: 'Lucas TVS', category: 'Lighting', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 50, lowStock: 14, cost: 90, mrp: 160, gst: 28, barcode: '8901234500226', location: 'G1-01'),
    CatalogueEntry(name: 'LED Headlight Kit', partNumber: 'HL-LED-KIT', brand: 'Minda', category: 'Lighting', vehicleMake: 'Universal', unit: 'set', sampleQty: 14, lowStock: 4, cost: 1100, mrp: 1850, gst: 28, barcode: '8901234500233', location: 'G1-02'),
    CatalogueEntry(name: 'Horn (Twin Tone)', partNumber: 'HN-MINDA-TT', brand: 'Spark Minda', category: 'Electrical', vehicleMake: 'Universal', unit: 'set', sampleQty: 16, lowStock: 5, cost: 380, mrp: 640, gst: 28, barcode: '8901234500240', location: 'G1-03'),
    CatalogueEntry(name: 'Self Starter Motor', partNumber: 'ST-WAGONR-11', brand: 'Lucas TVS', category: 'Electrical', vehicleMake: 'Maruti Suzuki', vehicleModel: 'WagonR', unit: 'pcs', sampleQty: 4, lowStock: 2, cost: 3200, mrp: 4600, gst: 28, barcode: '8901234500257', location: 'G1-04'),
    CatalogueEntry(name: 'Alternator', partNumber: 'AL-DZIRE-12', brand: 'Valeo', category: 'Electrical', vehicleMake: 'Maruti Suzuki', vehicleModel: 'Dzire', unit: 'pcs', sampleQty: 3, lowStock: 1, cost: 5200, mrp: 7400, gst: 28, barcode: '8901234500264', location: 'G1-05'),

    // ---------- Suspension & Steering ----------
    CatalogueEntry(name: 'Shock Absorber (Front)', partNumber: 'SA-SWFT-FR13', brand: 'Gabriel', category: 'Suspension', vehicleMake: 'Maruti Suzuki', vehicleModel: 'Swift', unit: 'pcs', sampleQty: 10, lowStock: 4, cost: 1250, mrp: 1950, gst: 28, barcode: '8901234500271', location: 'H1-01'),
    CatalogueEntry(name: 'Tie Rod End', partNumber: 'TR-I10-14', brand: 'Rane', category: 'Steering', vehicleMake: 'Hyundai', vehicleModel: 'i10', unit: 'pcs', sampleQty: 14, lowStock: 5, cost: 380, mrp: 620, gst: 28, barcode: '8901234500288', location: 'H1-02'),
    CatalogueEntry(name: 'Ball Joint (Lower)', partNumber: 'BJ-NEXON-15', brand: 'Rane', category: 'Suspension', vehicleMake: 'Tata Motors', vehicleModel: 'Nexon', unit: 'pcs', sampleQty: 12, lowStock: 4, cost: 460, mrp: 740, gst: 28, barcode: '8901234500295', location: 'H1-03'),

    // ---------- Belts, Bearings, Clutch ----------
    CatalogueEntry(name: 'Timing Belt', partNumber: 'TB-GATES-16', brand: 'Gates', category: 'Belts & Hoses', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 16, lowStock: 5, cost: 720, mrp: 1180, gst: 28, barcode: '8901234500301', location: 'I1-01'),
    CatalogueEntry(name: 'Fan / Drive Belt', partNumber: 'DB-FEN-17', brand: 'Fenner', category: 'Belts & Hoses', vehicleMake: 'Universal', unit: 'pcs', sampleQty: 22, lowStock: 6, cost: 240, mrp: 420, gst: 28, barcode: '8901234500318', location: 'I1-02'),
    CatalogueEntry(name: 'Wheel Bearing Kit', partNumber: 'WB-SKF-18', brand: 'SKF', category: 'Bearings', vehicleMake: 'Universal', unit: 'set', sampleQty: 12, lowStock: 4, cost: 880, mrp: 1380, gst: 18, barcode: '8901234500325', location: 'I1-03'),
    CatalogueEntry(name: 'Clutch Plate Kit', partNumber: 'CP-SWFT-19', brand: 'Sundaram (TVS)', category: 'Clutch & Transmission', vehicleMake: 'Maruti Suzuki', vehicleModel: 'Swift', unit: 'set', sampleQty: 7, lowStock: 3, cost: 2400, mrp: 3600, gst: 28, barcode: '8901234500332', location: 'I1-04'),

    // ---------- Cooling / Wipers / Body ----------
    CatalogueEntry(name: 'Radiator Assembly', partNumber: 'RD-ALTO-20', brand: 'Tata Genuine Parts', category: 'Cooling', vehicleMake: 'Maruti Suzuki', vehicleModel: 'Alto', unit: 'pcs', sampleQty: 4, lowStock: 2, cost: 2800, mrp: 4100, gst: 28, barcode: '8901234500349', location: 'J1-01'),
    CatalogueEntry(name: 'Wiper Blade (Pair)', partNumber: 'WP-UNI-21', brand: 'Bosch', category: 'Wipers', vehicleMake: 'Universal', unit: 'set', sampleQty: 30, lowStock: 8, cost: 280, mrp: 480, gst: 18, barcode: '8901234500356', location: 'J1-02'),
    CatalogueEntry(name: 'Side Mirror (RHS)', partNumber: 'SM-WAGONR-22', brand: 'Wipro (Maruti Genuine)', category: 'Body & Exterior', vehicleMake: 'Maruti Suzuki', vehicleModel: 'WagonR', unit: 'pcs', sampleQty: 6, lowStock: 2, cost: 920, mrp: 1450, gst: 28, barcode: '8901234500363', location: 'J1-03'),
    CatalogueEntry(name: 'Front Bumper Grille', partNumber: 'BG-SELTOS-23', brand: 'Kia', category: 'Body & Exterior', vehicleMake: 'Kia', vehicleModel: 'Seltos', unit: 'pcs', sampleQty: 3, lowStock: 1, cost: 2100, mrp: 3200, gst: 28, barcode: '8901234500370', location: 'J1-04'),
    CatalogueEntry(name: 'Exhaust Silencer', partNumber: 'EX-NEXON-24', brand: 'Tata Genuine Parts', category: 'Exhaust', vehicleMake: 'Tata Motors', vehicleModel: 'Nexon', unit: 'pcs', sampleQty: 4, lowStock: 2, cost: 2600, mrp: 3900, gst: 28, barcode: '8901234500387', location: 'K1-01'),
  ];
}
