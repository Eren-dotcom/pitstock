import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/supplier_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'purchase_order_edit_screen.dart';
import 'purchase_order_detail_screen.dart';

class SupplierDetailScreen extends StatelessWidget {
  final String supplierId;
  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    final supProv = context.watch<SupplierProvider>();
    final supplier = supProv.byId(supplierId);

    if (supplier == null) {
      return const Scaffold(body: Center(child: Text('Supplier not found')));
    }

    final pos = supProv.purchaseOrders
        .where((p) => p.supplierId == supplier.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, supProv, supplier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PurchaseOrderEditScreen(prefillSupplier: supplier),
          ),
        ),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Create Purchase Order'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Profile Card
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
                    Text(supplier.name,
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
                      child: Text('★ ${supplier.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (supplier.company != null) ...[
                  const SizedBox(height: 4),
                  Text(supplier.company!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(supplier.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
                if (supplier.email != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(supplier.email!,
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ],
                if (supplier.gstin != null) ...[
                  const SizedBox(height: 4),
                  Text('GSTIN: ${supplier.gstin}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (supplier.address != null)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Address'),
                      subtitle: Text(supplier.address!),
                    ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.payment_outlined),
                    title: const Text('Payment Terms'),
                    subtitle: Text(supplier.paymentTerms ?? 'Credit 30 Days'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Purchase Orders History (${pos.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (pos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No purchase orders created for this vendor yet.'),
              ),
            )
          else
            ...pos.map((po) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PurchaseOrderDetailScreen(orderId: po.id)),
                    ),
                    title: Text(po.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${Fmt.date(po.createdAt)} • ${po.totalItems} items\nStatus: ${po.status.label}'),
                    isThreeLine: true,
                    trailing: Text(Fmt.money(po.grandTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, SupplierProvider supProv, dynamic s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Supplier?'),
        content: Text('Are you sure you want to remove "${s.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              supProv.deleteSupplier(s.id);
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close screen
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
