import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/workorder_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'customer_edit_screen.dart';
import 'pos_billing_screen.dart';
import 'workorder_edit_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final custProv = context.watch<CustomerProvider>();
    final invProv = context.watch<InvoiceProvider>();
    final woProv = context.watch<WorkOrderProvider>();
    final customer = custProv.byId(customerId);

    if (customer == null) {
      return const Scaffold(body: Center(child: Text('Customer not found')));
    }

    final invoices = invProv.invoices
        .where((i) => i.customerId == customer.id || i.customerPhone == customer.phone)
        .toList();

    final jobs = woProv.orders
        .where((o) => o.customerId == customer.id || o.customerPhone == customer.phone)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CustomerEditScreen(existing: customer)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, custProv, customer),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(customer.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${customer.visitCount} visits',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(customer.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
                if (customer.email != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(customer.email!,
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ],
                if (customer.address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.home, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(customer.address!,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Lifetime Spend:',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(Fmt.money(customer.totalSpent),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Shortcuts
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('New Bill (POS)'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PosBillingScreen(prefillCustomer: customer),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.build_circle),
                  label: const Text('Start Job Card'),
                  onPressed: () => _startJobCard(context, customer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Registered Vehicles Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Registered Vehicles (${customer.vehicles.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Vehicle'),
                onPressed: () => _addVehicleModal(context, custProv, customer),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (customer.vehicles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('No vehicles added yet for this customer.'),
              ),
            )
          else
            ...customer.vehicles.map((v) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x221E5AF6),
                      child: Icon(Icons.directions_car, color: AppTheme.primary),
                    ),
                    title: Text(v.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Fuel: ${v.fuelType} • Odo: ${v.odometer} km${v.color != null ? ' • Color: ${v.color}' : ''}'),
                  ),
                )),

          const SizedBox(height: 16),
          Text('Service & Job Cards History (${jobs.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          if (jobs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('No past job cards for this customer.'),
              ),
            )
          else
            ...jobs.map((j) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WorkOrderEditScreen(orderId: j.id)),
                    ),
                    title: Text('${j.number} • ${j.status.label}'),
                    subtitle: Text(
                        '${Fmt.date(j.createdAt)} • ${j.vehicleInfo ?? j.vehicleReg ?? ''}'),
                    trailing: Text(Fmt.money(j.grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),

          const SizedBox(height: 16),
          Text('Past Invoices (${invoices.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          if (invoices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('No invoices recorded yet.'),
              ),
            )
          else
            ...invoices.map((inv) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(inv.number),
                    subtitle: Text('${Fmt.date(inv.createdAt)} • ${inv.paymentMethod.label}'),
                    trailing: Text(Fmt.money(inv.grandTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _startJobCard(BuildContext context, Customer c) async {
    final vehicle = c.vehicles.isNotEmpty ? c.vehicles.first : null;
    final wo = await context.read<WorkOrderProvider>().create(
          customerId: c.id,
          customerName: c.name,
          customerPhone: c.phone,
          vehicleReg: vehicle?.regNumber,
          vehicleInfo: vehicle != null ? '${vehicle.make} ${vehicle.model}' : null,
          odometer: vehicle?.odometer,
        );
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorkOrderEditScreen(orderId: wo.id)),
      );
    }
  }

  void _addVehicleModal(
      BuildContext context, CustomerProvider custProv, Customer c) {
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '2022');
    final regCtrl = TextEditingController();
    final odoCtrl = TextEditingController(text: '0');
    final fuelCtrl = TextEditingController(text: 'Petrol');
    final colorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Customer Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: makeCtrl,
                  decoration: const InputDecoration(labelText: 'Make (e.g. Maruti Suzuki)')),
              const SizedBox(height: 8),
              TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(labelText: 'Model (e.g. Swift)')),
              const SizedBox(height: 8),
              TextField(
                  controller: regCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Reg Number (e.g. MH-12-AB-1234) *')),
              const SizedBox(height: 8),
              TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year')),
              const SizedBox(height: 8),
              TextField(
                  controller: odoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Odometer Reading (KM)')),
              const SizedBox(height: 8),
              TextField(
                  controller: fuelCtrl,
                  decoration: const InputDecoration(labelText: 'Fuel Type (Petrol/Diesel/CNG/EV)')),
              const SizedBox(height: 8),
              TextField(
                  controller: colorCtrl,
                  decoration: const InputDecoration(labelText: 'Vehicle Color')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (regCtrl.text.trim().isEmpty) return;
              final vehicle = CustomerVehicle(
                id: const Uuid().v4(),
                customerId: c.id,
                make: makeCtrl.text.trim().isEmpty ? 'Car' : makeCtrl.text.trim(),
                model: modelCtrl.text.trim().isEmpty ? '' : modelCtrl.text.trim(),
                year: int.tryParse(yearCtrl.text),
                regNumber: regCtrl.text.trim().toUpperCase(),
                odometer: int.tryParse(odoCtrl.text) ?? 0,
                fuelType: fuelCtrl.text.trim(),
                color: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
              );
              await custProv.addVehicleToCustomer(c.id, vehicle);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save Vehicle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, CustomerProvider custProv, Customer c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Remove "${c.name}" and all linked vehicle records?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              custProv.deleteCustomer(c.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
