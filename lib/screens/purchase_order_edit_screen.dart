import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/part.dart';
import '../models/supplier.dart';
import '../providers/inventory_provider.dart';
import '../providers/supplier_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'purchase_order_detail_screen.dart';

class PurchaseOrderEditScreen extends StatefulWidget {
  final Supplier? prefillSupplier;
  final PurchaseOrder? existing;
  const PurchaseOrderEditScreen({super.key, this.prefillSupplier, this.existing});

  @override
  State<PurchaseOrderEditScreen> createState() => _PurchaseOrderEditScreenState();
}

class _PurchaseOrderEditScreenState extends State<PurchaseOrderEditScreen> {
  Supplier? _selectedSupplier;
  final List<PurchaseOrderLine> _lines = [];
  final _notesCtrl = TextEditingController();
  DateTime? _expectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _lines.addAll(widget.existing!.lines);
      _notesCtrl.text = widget.existing!.notes ?? '';
      _expectedDate = widget.existing!.expectedDate;
    }
  }

  double get _subtotal => _lines.fold(0.0, (s, l) => s + l.subtotal);
  double get _taxTotal => _lines.fold(0.0, (s, l) => s + l.taxAmount);
  double get _grandTotal => _subtotal + _taxTotal;

  void _addCataloguePart() async {
    final inv = context.read<InventoryProvider>();
    final part = await showModalBottomSheet<Part>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PoPartPicker(parts: inv.parts),
    );
    if (part == null) return;

    final existingIdx = _lines.indexWhere((l) => l.partId == part.id);
    setState(() {
      if (existingIdx >= 0) {
        _lines[existingIdx].quantity += 1;
      } else {
        _lines.add(PurchaseOrderLine(
          partId: part.id,
          name: part.name,
          partNumber: part.partNumber,
          quantity: part.reorderQty > 0 ? part.reorderQty : 5,
          unitCost: part.costPrice > 0 ? part.costPrice : (part.sellingPrice * 0.7),
          taxPercent: part.gstPercent,
        ));
      }
    });
  }

  Future<void> _savePo() async {
    final supProv = context.read<SupplierProvider>();
    final sup = _selectedSupplier ??
        widget.prefillSupplier ??
        (supProv.suppliers.isNotEmpty ? supProv.suppliers.first : null);

    if (sup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier.')));
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one line item.')));
      return;
    }

    if (widget.existing == null) {
      final po = await supProv.createPurchaseOrder(
        supplierId: sup.id,
        supplierName: sup.name,
        expectedDate: _expectedDate,
        lines: _lines,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => PurchaseOrderDetailScreen(orderId: po.id)),
        );
      }
    } else {
      final updated = widget.existing!;
      updated.lines = _lines;
      updated.expectedDate = _expectedDate;
      updated.notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      await supProv.savePurchaseOrder(updated);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supProv = context.watch<SupplierProvider>();
    _selectedSupplier ??= widget.prefillSupplier ??
        (supProv.suppliers.isNotEmpty ? supProv.suppliers.first : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Create Purchase Order' : 'Edit PO'),
        actions: [
          IconButton(
            tooltip: 'Add Part',
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: _addCataloguePart,
          ),
        ],
      ),
      body: Column(
        children: [
          // Supplier selector & date
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(.3)),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<Supplier>(
                  value: _selectedSupplier,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Supplier / Vendor'),
                  items: supProv.suppliers
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.name} (${s.company ?? s.phone})',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSupplier = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_expectedDate == null
                            ? 'Set Expected Date'
                            : 'Expected: ${Fmt.date(_expectedDate!)}'),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 3)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setState(() => _expectedDate = d);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _lines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_shopping_cart_outlined,
                            size: 54,
                            color: Theme.of(context)
                                .disabledColor
                                .withOpacity(.4)),
                        const SizedBox(height: 8),
                        const Text('No items added yet'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Parts from Inventory'),
                          onPressed: _addCataloguePart,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _lines.length,
                    itemBuilder: (_, i) => _lineCard(_lines[i], i),
                  ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal: ${Fmt.money(_subtotal)} • Tax: ${Fmt.money(_taxTotal)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Total: ${Fmt.money(_grandTotal)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Save & Issue Purchase Order',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _lines.isEmpty ? null : _savePo,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineCard(PurchaseOrderLine line, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(line.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(Fmt.money(line.total),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.danger),
                  onPressed: () => setState(() => _lines.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: line.quantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Order Qty',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (v) {
                      setState(() {
                        line.quantity = int.tryParse(v) ?? line.quantity;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: line.unitCost.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Unit Cost ₹',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (v) {
                      setState(() {
                        line.unitCost = double.tryParse(v) ?? line.unitCost;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: line.taxPercent.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tax %',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (v) {
                      setState(() {
                        line.taxPercent = double.tryParse(v) ?? line.taxPercent;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PoPartPicker extends StatefulWidget {
  final List<Part> parts;
  const _PoPartPicker({required this.parts});
  @override
  State<_PoPartPicker> createState() => _PoPartPickerState();
}

class _PoPartPickerState extends State<_PoPartPicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.parts
        .where((p) =>
            _q.isEmpty ||
            p.name.toLowerCase().contains(_q.toLowerCase()) ||
            p.partNumber.toLowerCase().contains(_q.toLowerCase()) ||
            p.brand.toLowerCase().contains(_q.toLowerCase()))
        .take(50)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search parts to order…',
                prefixIcon: Icon(Icons.search),
              ),
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
                      '${p.brand} • In Stock: ${p.quantity} • Cost: ${Fmt.money(p.costPrice)} • Reorder: ${p.reorderQty}'),
                  trailing: Text(p.binLocation, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
