import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/part.dart';
import '../models/work_order.dart';
import '../providers/workorder_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/invoice_service.dart';
import '../services/job_card_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'invoice_detail_screen.dart';

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
    final settings = context.watch<SettingsProvider>();
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
          IconButton(
            tooltip: 'Print Job Card',
            icon: const Icon(Icons.print),
            onPressed: () => _printJobCard(wo, settings),
          ),
          if (!completed)
            IconButton(
              tooltip: 'Add Part',
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () => _addPart(wo),
            ),
          if (!completed)
            IconButton(
              tooltip: 'Add Labour',
              icon: const Icon(Icons.engineering),
              onPressed: () => _addLabour(wo),
            ),
        ],
      ),
      body: Column(
        children: [
          _customerHeader(wo),
          _statusSelector(wo),
          Expanded(
            child: wo.lines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.build_outlined,
                            size: 48,
                            color: Theme.of(context)
                                .disabledColor
                                .withOpacity(.4)),
                        const SizedBox(height: 8),
                        const Text('No parts or labour added yet'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Add Part'),
                              onPressed: () => _addPart(wo),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.engineering),
                              label: const Text('Add Labour'),
                              onPressed: () => _addLabour(wo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
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
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(wo.customerName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              Text(wo.vehicleReg ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
              '${wo.vehicleInfo ?? 'Vehicle'} • ${wo.customerPhone ?? 'No Phone'}'
              '${wo.technician != null ? ' • Tech: ${wo.technician}' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (wo.complaints != null && wo.complaints!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Issues: ${wo.complaints}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontSize: 11.5)),
          ],
        ],
      ),
    );
  }

  Widget _statusSelector(WorkOrder wo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: WorkOrderStatus.values.map((s) {
            final isSelected = wo.status == s;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(s.label, style: const TextStyle(fontSize: 11.5)),
                selected: isSelected,
                onSelected: (val) {
                  if (val && !wo.stockDeducted) {
                    setState(() => wo.status = s);
                    context.read<WorkOrderProvider>().save(wo);
                  }
                },
              ),
            );
          }).toList(),
        ),
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
                      label: const Text('Complete Job'),
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
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                    fontSize: bold ? 15 : 13)),
            Text(Fmt.money(v),
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                    fontSize: bold ? 15 : 13)),
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
        partNumber: part.partNumber,
        quantity: 1,
        price: part.sellingPrice,
        gstPercent: part.gstPercent,
        coreCharge: part.coreCharge,
      ));
    });
    context.read<WorkOrderProvider>().save(wo);
  }

  Future<void> _addLabour(WorkOrder wo) async {
    final name = TextEditingController(text: 'General Service Labour');
    final amount = TextEditingController(text: '500');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Labour / Fitment Charge'),
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
    final custProv = context.read<CustomerProvider>();
    final warnings = await context
        .read<WorkOrderProvider>()
        .complete(wo, inv, customerProvider: custProv);
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
    final inv = context.read<InvoiceProvider>();
    final custProv = context.read<CustomerProvider>();
    final invProv = context.read<InventoryProvider>();

    if (!wo.stockDeducted) {
      await context
          .read<WorkOrderProvider>()
          .complete(wo, invProv, customerProvider: custProv);
    }

    final invoice = await inv.createFromWorkOrder(wo);
    wo.invoiceId = invoice.id;
    await context.read<WorkOrderProvider>().save(wo);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id)),
      );
    }
  }

  Future<void> _printJobCard(WorkOrder wo, SettingsProvider settings) async {
    await JobCardService.printJobCard(
      workOrder: wo,
      shopName: settings.shopName,
      shopPhone: settings.shopPhone,
      shopAddress: settings.shopAddress,
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
                  hintText: 'Search parts for job…', prefixIcon: Icon(Icons.search)),
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
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${p.brand} • ${Fmt.money(p.sellingPrice)} • Stock: ${p.quantity} • Loc: ${p.binLocation}'),
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
