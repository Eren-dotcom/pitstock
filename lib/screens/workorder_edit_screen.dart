import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/part.dart';
import '../models/work_order.dart';
import '../providers/workorder_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/settings_provider.dart';
import '../services/invoice_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class WorkOrderEditScreen extends StatefulWidget {
  final String orderId;
  const WorkOrderEditScreen({super.key, required this.orderId});
  @override
  State<WorkOrderEditScreen> createState() => _WorkOrderEditScreenState();
}

class _WorkOrderEditScreenState extends State<WorkOrderEditScreen> {
  @override
  Widget build(BuildContext context) {
    final wop = context.watch<WorkOrderProvider>();
    final wo = wop.orders.firstWhere((o) => o.id == widget.orderId,
        orElse: () => WorkOrder(
            id: '',
            number: '',
            customerName: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()));
    if (wo.id.isEmpty) {
      return const Scaffold(body: Center(child: Text('Work order not found')));
    }
    final completed = wo.status == WorkOrderStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: Text(wo.number),
        actions: [
          if (!completed)
            IconButton(
              tooltip: 'Add part',
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () => _addPart(wo),
            ),
          if (!completed)
            IconButton(
              tooltip: 'Add labour',
              icon: const Icon(Icons.engineering),
              onPressed: () => _addLabour(wo),
            ),
        ],
      ),
      body: Column(
        children: [
          _customerHeader(wo),
          Expanded(
            child: wo.lines.isEmpty
                ? const Center(child: Text('No items. Add parts or labour.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: wo.lines.length,
                    itemBuilder: (_, i) => _lineCard(wo, wo.lines[i], completed),
                  ),
          ),
          _totalsBar(wo, completed),
        ],
      ),
    );
  }

  Widget _customerHeader(WorkOrder wo) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(wo.customerName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
              '${wo.vehicleInfo ?? ''}  ${wo.vehicleReg ?? ''}  ${wo.customerPhone ?? ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _lineCard(WorkOrder wo, WorkOrderLine l, bool completed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(l.isLabour ? Icons.engineering : Icons.settings,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(l.name,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(Fmt.money(l.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (!completed)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() => wo.lines.remove(l));
                      context.read<WorkOrderProvider>().save(wo);
                    },
                  ),
              ],
            ),
            Text(
                '${l.quantity} × ${Fmt.money(l.price)}  •  GST ${l.gstPercent.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12)),
            if (l.coreCharge > 0)
              Row(
                children: [
                  Checkbox(
                    value: l.coreReturned,
                    onChanged: completed
                        ? null
                        : (v) {
                            setState(() => l.coreReturned = v ?? false);
                            context.read<WorkOrderProvider>().save(wo);
                          },
                  ),
                  Expanded(
                    child: Text(
                        'Old core returned? (saves ${Fmt.money(l.coreCharge * l.quantity)} core charge)',
                        style: const TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _totalsBar(WorkOrder wo, bool completed) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12),
          ],
        ),
        child: Column(
          children: [
            _row('Subtotal', wo.subtotal),
            _row('GST', wo.gstTotal),
            if (wo.coreTotal > 0) _row('Core charge', wo.coreTotal),
            const Divider(),
            _row('Grand Total', wo.grandTotal, bold: true),
            const SizedBox(height: 10),
            Row(
              children: [
                if (!completed)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Complete + Deduct'),
                      onPressed: () => _complete(wo),
                    ),
                  ),
                if (!completed) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Generate Bill'),
                    onPressed: () => _generateBill(wo),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                    fontSize: bold ? 16 : 14)),
            Text(Fmt.money(v),
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                    fontSize: bold ? 16 : 14)),
          ],
        ),
      );

  Future<void> _addPart(WorkOrder wo) async {
    final inv = context.read<InventoryProvider>();
    final part = await showModalBottomSheet<Part>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PartPicker(parts: inv.parts),
    );
    if (part == null) return;
    setState(() {
      wo.lines.add(WorkOrderLine(
        partId: part.id,
        name: part.name,
        quantity: 1,
        price: part.sellingPrice,
        gstPercent: part.gstPercent,
        coreCharge: part.coreCharge,
      ));
    });
    context.read<WorkOrderProvider>().save(wo);
  }

  Future<void> _addLabour(WorkOrder wo) async {
    final name = TextEditingController(text: 'Labour / Service');
    final amount = TextEditingController(text: '500');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Labour'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Description')),
          TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount ₹')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        wo.lines.add(WorkOrderLine(
          partId: '',
          name: name.text.trim(),
          price: double.tryParse(amount.text) ?? 0,
          gstPercent: 18,
          isLabour: true,
        ));
      });
      context.read<WorkOrderProvider>().save(wo);
    }
  }

  Future<void> _complete(WorkOrder wo) async {
    final inv = context.read<InventoryProvider>();
    final warnings =
        await context.read<WorkOrderProvider>().complete(wo, inv);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(warnings.isEmpty
          ? 'Completed. Parts deducted from inventory.'
          : 'Completed with warnings: ${warnings.join('; ')}'),
      backgroundColor: warnings.isEmpty ? AppTheme.success : AppTheme.warning,
    ));
  }

  Future<void> _generateBill(WorkOrder wo) async {
    final settings = context.read<SettingsProvider>();
    final inv = context.read<InvoiceProvider>();
    final invoice = await inv.createFromWorkOrder(wo);
    wo.invoiceId = invoice['id'] as String;
    await context.read<WorkOrderProvider>().save(wo);
    await InvoiceService.printInvoice(
      invoiceNumber: invoice['number'] as String,
      shopName: settings.shopName,
      shopGstin: settings.gstin,
      customerName: wo.customerName,
      customerPhone: wo.customerPhone,
      vehicleReg: wo.vehicleReg,
      lines: wo.lines,
    );
  }
}

class _PartPicker extends StatefulWidget {
  final List<Part> parts;
  const _PartPicker({required this.parts});
  @override
  State<_PartPicker> createState() => _PartPickerState();
}

class _PartPickerState extends State<_PartPicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.parts
        .where((p) =>
            _q.isEmpty ||
            p.name.toLowerCase().contains(_q.toLowerCase()) ||
            p.partNumber.toLowerCase().contains(_q.toLowerCase()))
        .take(50)
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: .8,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Search part…', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                      '${p.brand} • ${Fmt.money(p.sellingPrice)} • stock ${p.quantity}'),
                  trailing: p.hasCore
                      ? const Chip(label: Text('CORE', style: TextStyle(fontSize: 10)))
                      : null,
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
