import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scanned_item.dart';
import '../models/stock_movement.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum MovementSource { bill, scan }

/// Review screen for AI-parsed items before committing to inventory.
/// User can edit qty/price, toggle inclusion, and see catalogue matches.
class ScanReviewScreen extends StatefulWidget {
  final List<ScannedItem> items;
  final MovementSource source;
  final String title;
  const ScanReviewScreen({
    super.key,
    required this.items,
    required this.source,
    required this.title,
  });

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  final _refController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final selectedCount = widget.items.where((e) => e.selected).length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'Reference (bill no / supplier)',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.items.length,
              itemBuilder: (_, i) {
                final item = widget.items[i];
                final matched =
                    item.matchedPartId != null ? inv.byId(item.matchedPartId!) : null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: item.selected,
                              onChanged: (v) => setState(
                                  () => item.selected = v ?? true),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  if (matched != null)
                                    Text('✓ matches: ${matched.name}',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppTheme.success))
                                  else
                                    const Text('＋ will create new part',
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: AppTheme.accent)),
                                ],
                              ),
                            ),
                            _confidenceBadge(item.confidence),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _miniField(
                                label: 'Qty',
                                initial: item.quantity.toString(),
                                onChanged: (v) =>
                                    item.quantity = int.tryParse(v) ?? item.quantity,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _miniField(
                                label: 'Price ₹',
                                initial: item.price.toStringAsFixed(0),
                                onChanged: (v) => item.price =
                                    double.tryParse(v) ?? item.price,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('$selectedCount of ${widget.items.length} selected',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Add to Inventory'),
                    onPressed:
                        selectedCount == 0 ? null : () => _commit(inv),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceBadge(double c) {
    final pct = (c * 100).toStringAsFixed(0);
    final color = c >= 0.75
        ? AppTheme.success
        : c >= 0.6
            ? AppTheme.warning
            : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(.14),
          borderRadius: BorderRadius.circular(20)),
      child: Text('AI $pct%',
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _miniField({
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initial,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
          labelText: label, isDense: true, contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      onChanged: onChanged,
    );
  }

  Future<void> _commit(InventoryProvider inv) async {
    final type = widget.source == MovementSource.bill
        ? MovementType.billImport
        : MovementType.scanImport;
    final n = await inv.commitScannedItems(widget.items,
        source: type,
        reference: _refController.text.trim().isEmpty
            ? null
            : _refController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$n items added/updated in inventory')));
    Navigator.pop(context);
  }
}
