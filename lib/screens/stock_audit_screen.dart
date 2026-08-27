import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/part.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class StockAuditScreen extends StatefulWidget {
  const StockAuditScreen({super.key});

  @override
  State<StockAuditScreen> createState() => _StockAuditScreenState();
}

class _StockAuditScreenState extends State<StockAuditScreen> {
  String? _selectedShelf;
  String? _selectedCategory;
  final Map<String, TextEditingController> _countCtrls = {};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InventoryProvider>();

    final shelves = invProv.parts
        .map((p) => p.shelf)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    final parts = invProv.parts.where((p) {
      if (_selectedShelf != null && p.shelf != _selectedShelf) return false;
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    // Initialize controllers
    for (final p in parts) {
      _countCtrls.putIfAbsent(
          p.id, () => TextEditingController(text: p.quantity.toString()));
    }

    int totalDiffUnits = 0;
    double totalDiffValue = 0;
    for (final p in parts) {
      final ctrl = _countCtrls[p.id];
      if (ctrl != null) {
        final counted = int.tryParse(ctrl.text) ?? p.quantity;
        final diff = counted - p.quantity;
        totalDiffUnits += diff.abs();
        totalDiffValue += (diff * p.costPrice);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Physical Stock Audit'),
        actions: [
          IconButton(
            tooltip: 'Reset Counts',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                for (final p in parts) {
                  _countCtrls[p.id]?.text = p.quantity.toString();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedShelf,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Shelf',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Shelves')),
                      ...shelves.map((s) => DropdownMenuItem(value: s, child: Text('Shelf $s'))),
                    ],
                    onChanged: (v) => setState(() => _selectedShelf = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Filter Category',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...invProv.allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
              ],
            ),
          ),

          // Discrepancy Summary
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: totalDiffUnits > 0
                  ? AppTheme.warning.withOpacity(.12)
                  : AppTheme.success.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: totalDiffUnits > 0
                    ? AppTheme.warning.withOpacity(.4)
                    : AppTheme.success.withOpacity(.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  totalDiffUnits > 0 ? Icons.info_outline : Icons.check_circle_outline,
                  color: totalDiffUnits > 0 ? AppTheme.warning : AppTheme.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    totalDiffUnits > 0
                        ? '$totalDiffUnits discrepancy units detected (Net Value: ${Fmt.money(totalDiffValue)})'
                        : 'All physical counts match system quantities.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: totalDiffUnits > 0 ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              itemCount: parts.length,
              itemBuilder: (_, i) => _auditTile(parts[i]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.done_all),
            label: Text(_busy ? 'Reconciling…' : 'Apply Audit & Reconcile Discrepancies'),
            onPressed: _busy || totalDiffUnits == 0
                ? null
                : () => _applyReconciliation(context, parts),
          ),
        ),
      ),
    );
  }

  Widget _auditTile(Part p) {
    final ctrl = _countCtrls[p.id]!;
    final counted = int.tryParse(ctrl.text) ?? p.quantity;
    final diff = counted - p.quantity;

    Color diffColor = diff == 0
        ? AppTheme.success
        : (diff > 0 ? AppTheme.primary : AppTheme.danger);

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
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                      '${p.brand} • Loc: ${p.binLocation} • System: ${p.quantity} ${p.unit}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
                ],
              ),
            ),
            if (diff != 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${diff > 0 ? '+' : ''}$diff',
                  style: TextStyle(
                      color: diffColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
            ],
            SizedBox(
              width: 70,
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Counted',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyReconciliation(BuildContext context, List<Part> parts) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Physical Reconciliation'),
        content: const Text(
            'This will update current stock levels in the database to your physical counted numbers and create audit movements.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reconcile Stock')),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _busy = true);

    final counts = <String, int>{};
    for (final p in parts) {
      final ctrl = _countCtrls[p.id];
      if (ctrl != null) {
        counts[p.id] = int.tryParse(ctrl.text) ?? p.quantity;
      }
    }

    final invProv = context.read<InventoryProvider>();
    final count = await invProv.reconcilePhysicalAudit(counts, 'Physical Stock Audit');

    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$count parts reconciled successfully!'),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pop(context);
    }
  }
}
