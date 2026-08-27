import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/customer.dart';

/// Manages customers and customer vehicles.
class CustomerProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<Customer> _customers = [];
  bool _loading = true;

  List<Customer> get customers => _customers;
  bool get loading => _loading;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    _customers = await _db.getCustomers();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => bootstrap();

  Customer? byId(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Customer? byPhone(String phone) {
    try {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      return _customers.firstWhere((c) {
        final cClean = c.phone.replaceAll(RegExp(r'[^0-9]'), '');
        return cClean.endsWith(clean) || clean.endsWith(cClean);
      });
    } catch (_) {
      return null;
    }
  }

  Customer? byVehicleReg(String reg) {
    try {
      final clean = reg.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      return _customers.firstWhere((c) => c.vehicles.any((v) {
            final vClean =
                v.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
            return vClean == clean;
          }));
    } catch (_) {
      return null;
    }
  }

  List<Customer> search(String query) {
    if (query.trim().isEmpty) return _customers;
    final q = query.toLowerCase().trim();
    return _customers.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if (c.phone.contains(q)) return true;
      if (c.vehicles.any((v) =>
          v.regNumber.toLowerCase().contains(q) ||
          '${v.make} ${v.model}'.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }

  // ---- Customer CRUD ----
  Future<Customer> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? gstin,
    String? notes,
    List<CustomerVehicle>? vehicles,
  }) async {
    final cId = _uuid.v4();
    final c = Customer(
      id: cId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      gstin: gstin,
      notes: notes,
      createdAt: DateTime.now(),
      vehicles: vehicles?.map((v) => CustomerVehicle(
        id: v.id.isEmpty ? _uuid.v4() : v.id,
        customerId: cId,
        make: v.make,
        model: v.model,
        year: v.year,
        regNumber: v.regNumber,
        vin: v.vin,
        engineNo: v.engineNo,
        fuelType: v.fuelType,
        odometer: v.odometer,
        color: v.color,
        notes: v.notes,
      )).toList() ?? [],
    );
    await _db.upsertCustomer(c);
    _customers.add(c);
    _customers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    return c;
  }

  Future<void> updateCustomer(Customer c) async {
    await _db.upsertCustomer(c);
    final i = _customers.indexWhere((e) => e.id == c.id);
    if (i >= 0) _customers[i] = c;
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await _db.deleteCustomer(id);
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> addVehicleToCustomer(String customerId, CustomerVehicle vehicle) async {
    final c = byId(customerId);
    if (c == null) return;
    final v = vehicle.copyWith();
    c.vehicles.add(v);
    await updateCustomer(c);
  }

  Future<void> recordTransaction(String customerId, double amount) async {
    final c = byId(customerId);
    if (c == null) return;
    c.totalSpent += amount;
    c.visitCount += 1;
    await updateCustomer(c);
  }
}
