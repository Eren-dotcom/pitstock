import 'package:uuid/uuid.dart';
import '../models/part.dart';
import '../models/app_user.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import '../models/work_order.dart';
import '../models/invoice.dart';
import 'database_helper.dart';
import 'catalogue_data.dart';

/// Seeds the Indian car spare-parts catalogue, suppliers, customers, and users on first launch.
class SeedData {
  static const _seedKey = 'catalogue_seeded_v2';
  static const _usersKey = 'users_seeded_v1';
  static const _suppliersKey = 'suppliers_seeded_v1';
  static const _customersKey = 'customers_seeded_v1';
  static const _samplesKey = 'samples_seeded_v1';
  static const _uuid = Uuid();

  static Future<void> ensureSeeded(DatabaseHelper db) async {
    await _seedUsers(db);
    await _seedSuppliers(db);
    await _seedCustomers(db);

    final done = await db.getMeta(_seedKey);
    if (done != 'true') {
      final now = DateTime.now();
      final parts = <Part>[];
      for (final c in CatalogueData.items) {
        final isOem = c.brand.toLowerCase().contains('genuine') ||
            c.brand.toLowerCase().contains('mobis') ||
            c.brand == 'Kia';
        final coreParts = c.category == 'Battery' ||
            c.name.toLowerCase().contains('alternator') ||
            c.name.toLowerCase().contains('starter') ||
            c.name.toLowerCase().contains('radiator');
        final core = coreParts ? (c.category == 'Battery' ? 300.0 : 500.0) : 0.0;

        String? shelf;
        String? bin;
        if (c.location != null && c.location!.contains('-')) {
          final partsLoc = c.location!.split('-');
          shelf = partsLoc.first;
          bin = partsLoc.length > 1 ? partsLoc[1] : null;
        }

        parts.add(Part(
          id: _uuid.v4(),
          name: c.name,
          partNumber: c.partNumber,
          brand: c.brand,
          category: c.category,
          partType: isOem ? PartType.oem : PartType.aftermarket,
          vehicleMake: c.vehicleMake,
          vehicleModel: c.vehicleModel,
          yearFrom: c.vehicleModel != null ? 2014 : null,
          yearTo: c.vehicleModel != null ? 2024 : null,
          unit: c.unit,
          quantity: c.sampleQty,
          lowStockThreshold: c.lowStock,
          minStock: 2,
          maxStock: c.sampleQty * 3,
          reorderQty: c.lowStock * 3,
          costPrice: c.cost,
          sellingPrice: c.mrp,
          gstPercent: c.gst,
          coreCharge: core,
          hasCore: core > 0,
          shelf: shelf,
          bin: bin,
          barcode: c.barcode,
          location: c.location,
          supplier: c.brand,
          warrantyMonths: c.category == 'Battery' ? 24 : (c.category == 'Tyres' ? 36 : 6),
          createdAt: now,
          updatedAt: now,
        ));
      }
      await db.insertPartsBatch(parts);
      await db.setMeta(_seedKey, 'true');
    }

    await _seedSampleTransactions(db);
  }

  static Future<void> _seedUsers(DatabaseHelper db) async {
    final done = await db.getMeta(_usersKey);
    if (done == 'true') return;
    await db.upsertUser(AppUser(
        id: _uuid.v4(), name: 'Rajesh Sharma (Owner)', pin: '1111', role: UserRole.owner));
    await db.upsertUser(AppUser(
        id: _uuid.v4(), name: 'Amit Verma (Manager)', pin: '2222', role: UserRole.manager));
    await db.upsertUser(AppUser(
        id: _uuid.v4(), name: 'Suresh Kumar (Staff)', pin: '3333', role: UserRole.staff));
    await db.setMeta(_usersKey, 'true');
  }

  static Future<void> _seedSuppliers(DatabaseHelper db) async {
    final done = await db.getMeta(_suppliersKey);
    if (done == 'true') return;

    final now = DateTime.now();
    final suppliers = [
      Supplier(
        id: _uuid.v4(),
        name: 'AutoParts Wholesale India',
        company: 'Bosch & Brakes India Authorised Distributor',
        phone: '+91 98201 12345',
        email: 'sales@autopartsdist.in',
        address: 'Gala 14, Motor Market, Kashmere Gate, Delhi',
        gstin: '07AAAAA0000A1Z5',
        paymentTerms: 'Credit 30 Days',
        rating: 4.8,
        createdAt: now,
      ),
      Supplier(
        id: _uuid.v4(),
        name: 'Supreme Lubricants & Filters Co',
        company: 'Castrol & Mann Filters Official Dealer',
        phone: '+91 98450 67890',
        email: 'orders@supremelubes.com',
        address: 'Plot 45, Industrial Area Phase 2, Pune',
        gstin: '27BBBBB1111B2Z6',
        paymentTerms: 'Immediate',
        rating: 4.9,
        createdAt: now,
      ),
      Supplier(
        id: _uuid.v4(),
        name: 'Exide & Amaron Power Point',
        company: 'Automotive Batteries Wholesale',
        phone: '+91 97110 54321',
        email: 'powerpoint@batteries.co.in',
        address: 'Shop 8, Battery Lane, JC Road, Bengaluru',
        gstin: '29CCCCC2222C3Z7',
        paymentTerms: 'Credit 15 Days',
        rating: 4.7,
        createdAt: now,
      ),
      Supplier(
        id: _uuid.v4(),
        name: 'National Tyres Distributor',
        company: 'MRF, Apollo & CEAT Stockist',
        phone: '+91 99300 98765',
        email: 'contact@nationaltyres.in',
        address: 'Godown 3, Transport Nagar, Chennai',
        gstin: '33DDDDD3333D4Z8',
        paymentTerms: 'Credit 45 Days',
        rating: 4.6,
        createdAt: now,
      ),
    ];
    await db.insertSuppliersBatch(suppliers);
    await db.setMeta(_suppliersKey, 'true');
  }

  static Future<void> _seedCustomers(DatabaseHelper db) async {
    final done = await db.getMeta(_customersKey);
    if (done == 'true') return;

    final now = DateTime.now();
    final c1Id = _uuid.v4();
    final c2Id = _uuid.v4();
    final c3Id = _uuid.v4();

    final customers = [
      Customer(
        id: c1Id,
        name: 'Vikram Malhotra',
        phone: '+91 98765 43210',
        email: 'vikram.m@gmail.com',
        address: 'B-402, Green Valley Apartments, Mumbai',
        totalSpent: 12450,
        visitCount: 3,
        createdAt: now.subtract(const Duration(days: 45)),
        vehicles: [
          CustomerVehicle(
            id: _uuid.v4(),
            customerId: c1Id,
            make: 'Maruti Suzuki',
            model: 'Swift ZXi',
            year: 2021,
            regNumber: 'MH-02-DN-4521',
            fuelType: 'Petrol',
            odometer: 38500,
            color: 'Pearl Arctic White',
          ),
        ],
      ),
      Customer(
        id: c2Id,
        name: 'Pooja Deshmukh',
        phone: '+91 98234 56789',
        email: 'pooja.d@yahoo.com',
        address: 'Row House 12, Baner, Pune',
        totalSpent: 18900,
        visitCount: 2,
        createdAt: now.subtract(const Duration(days: 60)),
        vehicles: [
          CustomerVehicle(
            id: _uuid.v4(),
            customerId: c2Id,
            make: 'Hyundai',
            model: 'Creta SX (O)',
            year: 2022,
            regNumber: 'MH-12-TX-8899',
            fuelType: 'Diesel',
            odometer: 42100,
            color: 'Phantom Black',
          ),
        ],
      ),
      Customer(
        id: c3Id,
        name: 'Rohan Shinde',
        phone: '+91 99887 76655',
        email: 'rohan.shinde@outlook.com',
        address: 'Flat 503, Skyline Towers, Thane',
        totalSpent: 8500,
        visitCount: 1,
        createdAt: now.subtract(const Duration(days: 20)),
        vehicles: [
          CustomerVehicle(
            id: _uuid.v4(),
            customerId: c3Id,
            make: 'Tata Motors',
            model: 'Nexon EV Empowered',
            year: 2023,
            regNumber: 'MH-04-EV-2023',
            fuelType: 'EV',
            odometer: 19400,
            color: 'Daytona Grey',
          ),
        ],
      ),
    ];

    await db.insertCustomersBatch(customers);
    await db.setMeta(_customersKey, 'true');
  }

  static Future<void> _seedSampleTransactions(DatabaseHelper db) async {
    final done = await db.getMeta(_samplesKey);
    if (done == 'true') return;

    final customers = await db.getCustomers();
    final parts = await db.getAllParts();
    if (customers.isEmpty || parts.isEmpty) return;

    final c1 = customers.first;
    final p1 = parts.firstWhere((p) => p.name.contains('Brake Pad'), orElse: () => parts[0]);
    final p2 = parts.firstWhere((p) => p.name.contains('Oil Filter') || p.name.contains('Air Filter'), orElse: () => parts[1]);

    // Sample Work Order
    final woId = _uuid.v4();
    final sampleOrder = WorkOrder(
      id: woId,
      number: 'JOB-0001',
      customerId: c1.id,
      customerName: c1.name,
      customerPhone: c1.phone,
      vehicleReg: c1.vehicles.isNotEmpty ? c1.vehicles.first.regNumber : 'MH-02-DN-4521',
      vehicleInfo: c1.vehicles.isNotEmpty ? '${c1.vehicles.first.make} ${c1.vehicles.first.model}' : 'Maruti Suzuki Swift',
      technician: 'Ramesh Mechanic',
      odometer: 38500,
      fuelLevel: '1/2',
      complaints: 'Front brake squeaking on deceleration. General inspection.',
      internalNotes: 'Pads worn out. Replaced with Brakes India set. Tested OK.',
      status: WorkOrderStatus.inProgress,
      lines: [
        WorkOrderLine(
          partId: p1.id,
          name: p1.name,
          partNumber: p1.partNumber,
          quantity: 1,
          price: p1.sellingPrice,
          gstPercent: p1.gstPercent,
          coreCharge: p1.coreCharge,
        ),
        WorkOrderLine(
          partId: '',
          name: 'Front Brake Disc & Caliper Service',
          quantity: 1,
          price: 450,
          gstPercent: 18,
          isLabour: true,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );
    await db.upsertWorkOrder(sampleOrder);

    // Sample Invoice
    final invId = _uuid.v4();
    final invLines = [
      InvoiceLine(
        partId: p2.id,
        name: p2.name,
        partNumber: p2.partNumber,
        quantity: 2,
        unitPrice: p2.sellingPrice,
        gstPercent: p2.gstPercent,
      ),
      InvoiceLine(
        partId: '',
        name: 'Periodic Service Labour',
        quantity: 1,
        unitPrice: 600,
        gstPercent: 18,
        isLabour: true,
      ),
    ];
    final sub = invLines.fold(0.0, (s, l) => s + l.subtotal);
    final gst = invLines.fold(0.0, (s, l) => s + l.gstAmount);
    final grand = sub + gst;

    final sampleInv = Invoice(
      id: invId,
      number: 'INV/26/0001',
      customerId: c1.id,
      customerName: c1.name,
      customerPhone: c1.phone,
      vehicleReg: c1.vehicles.isNotEmpty ? c1.vehicles.first.regNumber : 'MH-02-DN-4521',
      vehicleInfo: 'Maruti Suzuki Swift',
      subtotal: sub,
      gstTotal: gst,
      cgstTotal: gst / 2,
      sgstTotal: gst / 2,
      coreTotal: 0,
      grandTotal: grand,
      paymentMethod: PaymentMethod.upi,
      lines: invLines,
      notes: 'Paid via PhonePe / GPay UPI',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    );
    await db.insertInvoice(sampleInv);

    await db.setMeta(_samplesKey, 'true');
  }
}
