import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/part.dart';
import '../models/stock_movement.dart';
import '../providers/inventory_provider.dart';
import '../services/label_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/part_tile.dart';
import 'part_edit_screen.dart';

class PartDetailScreen extends StatelessWidget {
  final String partId;
  const PartDetailScreen({super.key, required this.partId});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final part = inv.byId(partId);
    if (part == null) {
      return const Scaffold(body: Center(child: Text('Part not found')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                tooltip: 'Print Barcode Label',
                icon: const Icon(Icons.qr_code_2),
                onPressed: () => _printSingleLabel(context, part),
              ),
              IconButton(
                tooltip: 'Duplicate / Clone',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  final cloned = await inv.clonePart(part);
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PartDetailScreen(partId: cloned.id)),
                    );
                  }
                },
              ),
              IconButton(
                tooltip: 'Edit Part',
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PartEditScreen(existing: part))),
              ),
              IconButton(
                tooltip: 'Delete Part',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, inv, part),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: part.imagePath != null &&
                      File(part.imagePath!).existsSync()
                  ? Image.file(File(part.imagePath!), fit: BoxFit.cover)
                  : Container(
                      decoration:
                          BoxDecoration(gradient: AppTheme.brandGradient),
                      child: Center(
                        child: Icon(
                            PartTile.iconFor(part.category),
                            size: 80,
                            color: Colors.white.withOpacity(.9)),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${part.brand} • ${part.partNumber}',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(.6))),
                  const SizedBox(height: 16),
                  _stockControls(context, inv, part),
                  const SizedBox(height: 16),
                  _quickAdjustBar(context, inv, part),
                  const SizedBox(height: 16),
                  _infoGrid(context, part),
                  const SizedBox(height: 16),
                  Text('Stock Movements Audit Trail',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _movements(context, inv, part),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockControls(
      BuildContext context, InventoryProvider inv, Part part) {
    Color c = part.isOutOfStock
        ? AppTheme.danger
        : part.isLowStock
            ? AppTheme.warning
            : AppTheme.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: c.withOpacity(.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withOpacity(.4))),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Stock',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(.6))),
              Text('${part.quantity} ${part.unit}',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: c)),
              if (part.isLowStock)
                Text('Below threshold (${part.lowStockThreshold} ${part.unit})',
                    style: const TextStyle(fontSize: 11, color: AppTheme.warning)),
            ],
          ),
          const Spacer(),
          _roundBtn(context, Icons.remove, () {
            inv.adjustStock(part.id, -1,
                type: MovementType.stockOut, reference: 'Quick Manual −1');
          }),
          const SizedBox(width: 10),
          _roundBtn(context, Icons.add, () {
            inv.adjustStock(part.id, 1,
                type: MovementType.stockIn, reference: 'Quick Manual +1');
          }, filled: true),
        ],
      ),
    );
  }

  Widget _quickAdjustBar(
      BuildContext context, InventoryProvider inv, Part part) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock Adjustments with Reason',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _adjustChip(context, inv, part, +5, 'Restock +5', MovementType.stockIn),
                _adjustChip(context, inv, part, +10, 'Restock +10', MovementType.stockIn),
                _adjustChip(context, inv, part, -1, 'Damaged −1', MovementType.damage),
                _adjustChip(context, inv, part, -1, 'Return −1', MovementType.stockReturn),
                ActionChip(
                  label: const Text('Custom'),
                  avatar: const Icon(Icons.tune, size: 14),
                  onPressed: () => _customAdjustDialog(context, inv, part),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adjustChip(BuildContext context, InventoryProvider inv, Part part,
      int delta, String label, MovementType type) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      onPressed: () async {
        await inv.adjustStock(part.id, delta,
            type: type, reference: 'Quick $label');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Stock adjusted: $label')));
        }
      },
    );
  }

  void _customAdjustDialog(
      BuildContext context, InventoryProvider inv, Part part) {
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();
    MovementType type = MovementType.adjust;
    bool isAddition = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Custom Stock Adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('+ Add Stock'),
                      selected: isAddition,
                      onSelected: (_) => setState(() => isAddition = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('− Deduct Stock'),
                      selected: !isAddition,
                      onSelected: (_) => setState(() => isAddition = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MovementType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Reason Code'),
                items: MovementType.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                    .toList(),
                onChanged: (v) => setState(() => type = v ?? MovementType.adjust),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reference Note (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                final delta = isAddition ? qty : -qty;
                await inv.adjustStock(
                  part.id,
                  delta,
                  type: type,
                  reference: reasonCtrl.text.trim().isEmpty
                      ? 'Manual adjustment'
                      : reasonCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(BuildContext context, IconData icon, VoidCallback onTap,
      {bool filled = false}) {
    return Material(
      color: filled ? AppTheme.primary : Theme.of(context).cardColor,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: filled ? Colors.white : null),
        ),
      ),
    );
  }

  Widget _infoGrid(BuildContext context, Part part) {
    final rows = <(String, String)>[
      ('Category', part.category),
      ('Type', part.partType.label),
      ('Fitment', part.fitment),
      ('Cost Price', Fmt.money2(part.costPrice)),
      ('Selling Price (MRP)', Fmt.money2(part.sellingPrice)),
      ('GST Rate', '${part.gstPercent.toStringAsFixed(0)}%'),
      ('Profit Margin', '${part.marginPercent.toStringAsFixed(1)}% (Profit: ${Fmt.money2(part.grossProfitPerUnit)}/unit)'),
      if (part.hasCore) ('Core Deposit', Fmt.money2(part.coreCharge)),
      ('Total Stock Value', Fmt.money(part.stockValue)),
      ('Shelf / Bin Location', part.binLocation),
      ('Barcode', part.barcode ?? '—'),
      ('Supplier / Vendor', part.supplier ?? '—'),
      ('Min / Max Stock', '${part.minStock} min • ${part.maxStock} max'),
      ('Reorder Quantity', '${part.reorderQty} ${part.unit}'),
      if (part.warrantyMonths > 0) ('Warranty', '${part.warrantyMonths} Months'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            for (final r in rows)
              if (r.$2.isNotEmpty)
                ListTile(
                  dense: true,
                  title: Text(r.$1,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(.6))),
                  trailing: Text(r.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            if (part.notes != null && part.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(part.notes!,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _movements(BuildContext context, InventoryProvider inv, Part part) {
    return FutureBuilder<List<StockMovement>>(
      future: inv.movements(partId: part.id),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Padding(
              padding: EdgeInsets.all(16), child: LinearProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) return const Text('No movements yet.');
        return Card(
          child: Column(
            children: list.take(20).map((m) {
              final pos = m.delta >= 0;
              return ListTile(
                dense: true,
                leading: Icon(
                    pos ? Icons.arrow_downward : Icons.arrow_upward,
                    color: pos ? AppTheme.success : AppTheme.danger),
                title: Text(m.type.label),
                subtitle: Text(
                    '${m.reference ?? ''}\n${Fmt.date(m.date)}',
                    style: const TextStyle(fontSize: 11)),
                isThreeLine: true,
                trailing: Text('${pos ? '+' : ''}${m.delta}',
                    style: TextStyle(
                        color: pos ? AppTheme.success : AppTheme.danger,
                        fontWeight: FontWeight.w700)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _printSingleLabel(BuildContext context, Part part) async {
    await LabelService.printSinglePartLabel(part, copies: 1);
  }

  void _confirmDelete(
      BuildContext context, InventoryProvider inv, Part part) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete part?'),
        content: Text('Remove "${part.name}" and its history?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              inv.deletePart(part.id);
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
