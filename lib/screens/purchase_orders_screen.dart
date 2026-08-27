import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'purchase_order_edit_screen.dart';
import 'purchase_order_detail_screen.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  PurchaseOrderStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final supProv = context.watch<SupplierProvider>();
    final orders = _filterStatus == null
        ? supProv.purchaseOrders
        : supProv.purchaseOrders
            .where((p) => p.status == _filterStatus)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders (POs)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PurchaseOrderEditScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterStatus == null,
                  onSelected: (_) => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                ...PurchaseOrderStatus.values.map((st) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(st.label),
                        selected: _filterStatus == st,
                        onSelected: (_) => setState(() => _filterStatus = st),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_outlined,
                            size: 54,
                            color: Theme.of(context)
                                .disabledColor
                                .withOpacity(.4)),
                        const SizedBox(height: 8),
                        const Text('No purchase orders found'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _poCard(context, orders[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _poCard(BuildContext context, PurchaseOrder po) {
    Color statusColor = switch (po.status) {
      PurchaseOrderStatus.received => AppTheme.success,
      PurchaseOrderStatus.partiallyReceived => AppTheme.accent,
      PurchaseOrderStatus.ordered => AppTheme.primary,
      PurchaseOrderStatus.draft => Colors.blueGrey,
      PurchaseOrderStatus.cancelled => AppTheme.danger,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PurchaseOrderDetailScreen(orderId: po.id)),
        ),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(.15),
          child: Icon(Icons.shopping_bag, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text('${po.orderNumber} • ${po.supplierName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(po.status.label,
                  style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Text(
            '${Fmt.date(po.createdAt)} • ${po.totalItems} items (${po.totalReceived} recvd)\n${Fmt.money(po.grandTotal)}'),
        isThreeLine: true,
      ),
    );
  }
}
