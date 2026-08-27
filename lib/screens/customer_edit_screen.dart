import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CustomerEditScreen extends StatefulWidget {
  final Customer? existing;
  const CustomerEditScreen({super.key, this.existing});

  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
  late final _emailCtrl = TextEditingController(text: widget.existing?.email ?? '');
  late final _addrCtrl = TextEditingController(text: widget.existing?.address ?? '');
  late final _gstinCtrl = TextEditingController(text: widget.existing?.gstin ?? '');
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');

  // Quick initial vehicle
  final _vMakeCtrl = TextEditingController();
  final _vModelCtrl = TextEditingController();
  final _vYearCtrl = TextEditingController(text: '2022');
  final _vRegCtrl = TextEditingController();
  final _vOdoCtrl = TextEditingController(text: '0');
  String _vFuel = 'Petrol';

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit Customer' : 'Add New Customer')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Full Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Customer name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone number required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addrCtrl,
              decoration: const InputDecoration(labelText: 'Customer Address / Area'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gstinCtrl,
              decoration: const InputDecoration(labelText: 'Customer GSTIN (if business)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Customer Preferences / Notes'),
            ),
            const SizedBox(height: 20),

            if (!editing) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text('Add Primary Vehicle (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: _vMakeCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Make (e.g. Maruti Suzuki)')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                        controller: _vModelCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Model (e.g. Swift Dzire)')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: _vRegCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                            labelText: 'Reg No (e.g. MH-12-AB-1234)')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                        controller: _vYearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Year')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: _vOdoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Odometer (KM)')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _vFuel,
                      decoration: const InputDecoration(labelText: 'Fuel Type'),
                      items: const [
                        DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                        DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                        DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                        DropdownMenuItem(value: 'EV', child: Text('EV')),
                        DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                      ],
                      onChanged: (v) => setState(() => _vFuel = v ?? 'Petrol'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text(editing ? 'Save Changes' : 'Create Customer Profile'),
              onPressed: _saveCustomer,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _saveCustomer() async {
    if (!_form.currentState!.validate()) return;
    final custProv = context.read<CustomerProvider>();

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await custProv.updateCustomer(updated);
    } else {
      List<CustomerVehicle> initVehicles = [];
      if (_vRegCtrl.text.trim().isNotEmpty) {
        initVehicles.add(CustomerVehicle(
          id: const Uuid().v4(),
          customerId: '',
          make: _vMakeCtrl.text.trim().isEmpty ? 'Vehicle' : _vMakeCtrl.text.trim(),
          model: _vModelCtrl.text.trim(),
          year: int.tryParse(_vYearCtrl.text),
          regNumber: _vRegCtrl.text.trim().toUpperCase(),
          odometer: int.tryParse(_vOdoCtrl.text) ?? 0,
          fuelType: _vFuel,
        ));
      }
      await custProv.addCustomer(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        vehicles: initVehicles,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
