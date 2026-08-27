import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../services/purchase_order_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PurchaseOrderDetailScreen extends StatelessWidget {
  final String orderId;
  const PurchaseOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final supProv = context.watch<SupplierProvider>();
    final settings = context.watch<SettingsProvider>();
    final po = supProv.purchaseOrders.firstWhere(
      (p) => p.id == orderId,
      orElse: () => PurchaseOrder(
        id: '',
        orderNumber: '',
        supplierId: '',
        supplierName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (po.id.isEmpty) {
      return const Scaffold(body: Center(child: Text('Purchase Order not found')));
    }

    final supplier = supProv.byId(po.supplierId);
    final canReceive = po.status != PurchaseOrderStatus.received &&
        po.status != PurchaseOrderStatus.cancelled;

    Color statusColor = switch (po.status) {
      PurchaseOrderStatus.received => AppTheme.success,
      PurchaseOrderStatus.partiallyReceived => AppTheme.accent,
      PurchaseOrderStatus.ordered => AppTheme.primary,
      PurchaseOrderStatus.draft => Colors.blueGrey,
      PurchaseOrderStatus.cancelled => AppTheme.danger,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(po.orderNumber),
        actions: [
          IconButton(
            tooltip: 'Print PO PDF',
            icon: const Icon(Icons.print),
            onPressed: () => _printPo(context, po, supplier, settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
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
                    Text(po.orderNumber,
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
                      child: Text(po.status.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Vendor: ${po.supplierName}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text('Ordered: ${Fmt.date(po.createdAt)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (po.expectedDate != null)
                  Text('Expected: ${Fmt.date(po.expectedDate!)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('Ordered Parts (${po.lines.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Items Table
          ...po.lines.map((l) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: l.isFullyReceived
                            ? AppTheme.success.withOpacity(.15)
                            : AppTheme.primary.withOpacity(.15),
                        child: Icon(
                          l.isFullyReceived ? Icons.check : Icons.inventory_2,
                          size: 16,
                          color: l.isFullyReceived
                              ? AppTheme.success
                              : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                                '${l.quantity} ordered • ${l.receivedQuantity} received • Rate: ${Fmt.money(l.unitCost)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(.6))),
                          ],
                        ),
                      ),
                      Text(Fmt.money(l.total),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 12),

          // Totals Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Subtotal', po.subtotal),
                  _row('Estimated Tax', po.taxTotal),
                  const Divider(),
                  _row('Total Order Value', po.grandTotal, bold: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (canReceive) ...[
            FilledButton.icon(
              icon: const Icon(Icons.input),
              label: const Text('Receive Goods into Stock'),
              onPressed: () => _openReceiveModal(context, po),
            ),
            const SizedBox(height: 10),
          ],

          OutlinedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print Purchase Order PDF'),
            onPressed: () => _printPo(context, po, supplier, settings),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _row(String label, double val, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 15 : 13)),
          Text(Fmt.money(val),
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 15 : 13)),
        ],
      ),
    );
  }

  Future<void> _printPo(BuildContext context, PurchaseOrder po,
      Supplier? supplier, SettingsProvider settings) async {
    await PurchaseOrderService.printPurchaseOrder(
      po: po,
      supplier: supplier,
      shopName: settings.shopName,
      shopGstin: settings.gstin,
      shopPhone: settings.shopPhone,
      shopAddress: settings.shopAddress,
    );
  }

  void _openReceiveModal(BuildContext context, PurchaseOrder po) {
    final qtyMap = <String, TextEditingController>{};
    for (final l in po.lines) {
      final remaining = (l.quantity - l.receivedQuantity).clamp(0, 9999);
      qtyMap[l.partId] = TextEditingController(text: remaining.toString());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Receive Stock — ${po.orderNumber}',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Enter the quantity received today from the supplier:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: po.lines.length,
                  itemBuilder: (_, i) {
                    final line = po.lines[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(line.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      'Ordered: ${line.quantity} • Prev recvd: ${line.receivedQuantity}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: qtyMap[line.partId],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  labelText: 'Recv Qty',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Update Inventory & Log Movements'),
                onPressed: () async {
                  final map = <String, int>{};
                  for (final e in qtyMap.entries) {
                    final q = int.tryParse(e.value.text) ?? 0;
                    if (q > 0) map[e.key] = q;
                  }
                  final supProv = context.read<SupplierProvider>();
                  final invProv = context.read<InventoryProvider>();
                  final count = await supProv.receivePurchaseOrderItems(
                    po: po,
                    receivedQtyMap: map,
                    inventory: invProv,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('$count parts received and added to inventory!'),
                      backgroundColor: AppTheme.success,
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
