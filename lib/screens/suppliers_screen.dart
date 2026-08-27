import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import '../theme/app_theme.dart';
import 'supplier_detail_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final supProv = context.watch<SupplierProvider>();
    final suppliers = supProv.suppliers.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          (s.company != null && s.company!.toLowerCase().contains(q)) ||
          s.phone.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Parts Suppliers & Vendors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editSupplier(context, null),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Supplier'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search suppliers by name, brand, phone…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: suppliers.isEmpty
                ? const Center(child: Text('No suppliers found.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: suppliers.length,
                    itemBuilder: (_, i) => _supplierCard(suppliers[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _supplierCard(Supplier s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SupplierDetailScreen(supplierId: s.id)),
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary.withOpacity(.15),
          child: const Icon(Icons.business, color: AppTheme.secondary),
        ),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${s.company ?? s.phone}\nTerms: ${s.paymentTerms ?? 'Credit'} • Rating: ★ ${s.rating.toStringAsFixed(1)}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _editSupplier(context, s),
        ),
      ),
    );
  }

  void _editSupplier(BuildContext context, Supplier? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final compCtrl = TextEditingController(text: existing?.company ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final gstinCtrl = TextEditingController(text: existing?.gstin ?? '');
    final termsCtrl =
        TextEditingController(text: existing?.paymentTerms ?? 'Credit 30 Days');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scroll,
            children: [
              Text(existing == null ? 'New Supplier' : 'Edit Supplier',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Supplier Name *')),
              const SizedBox(height: 12),
              TextField(
                  controller: compCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Company / Distribution')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number *')),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 12),
              TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 12),
              TextField(
                  controller: gstinCtrl,
                  decoration: const InputDecoration(labelText: 'GSTIN')),
              const SizedBox(height: 12),
              TextField(
                  controller: termsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Payment Terms (e.g. Credit 30 Days)')),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      phoneCtrl.text.trim().isEmpty) {
                    return;
                  }
                  final supProv = context.read<SupplierProvider>();
                  if (existing == null) {
                    await supProv.addSupplier(
                      name: nameCtrl.text.trim(),
                      company: compCtrl.text.trim().isEmpty
                          ? null
                          : compCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                      address: addrCtrl.text.trim().isEmpty
                          ? null
                          : addrCtrl.text.trim(),
                      gstin: gstinCtrl.text.trim().isEmpty
                          ? null
                          : gstinCtrl.text.trim(),
                      paymentTerms: termsCtrl.text.trim(),
                    );
                  } else {
                    final updated = existing.copyWith(
                      name: nameCtrl.text.trim(),
                      company: compCtrl.text.trim().isEmpty
                          ? null
                          : compCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                      address: addrCtrl.text.trim().isEmpty
                          ? null
                          : addrCtrl.text.trim(),
                      gstin: gstinCtrl.text.trim().isEmpty
                          ? null
                          : gstinCtrl.text.trim(),
                      paymentTerms: termsCtrl.text.trim(),
                    );
                    await supProv.updateSupplier(updated);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Supplier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
