import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/part.dart';
import '../providers/inventory_provider.dart';
import '../services/label_service.dart';
import '../theme/app_theme.dart';

class LabelStudioScreen extends StatefulWidget {
  const LabelStudioScreen({super.key});

  @override
  State<LabelStudioScreen> createState() => _LabelStudioScreenState();
}

class _LabelStudioScreenState extends State<LabelStudioScreen> {
  LabelStyle _selectedStyle = LabelStyle.productBarcode;
  final Set<String> _selectedPartIds = {};
  final Map<String, int> _copies = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InventoryProvider>();

    final parts = invProv.parts.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.partNumber.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q);
    }).toList();

    final selectedCount = _selectedPartIds.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Label & Barcode Studio'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (_selectedPartIds.length == parts.length) {
                  _selectedPartIds.clear();
                } else {
                  _selectedPartIds.addAll(parts.map((p) => p.id));
                }
              });
            },
            child: Text(
                _selectedPartIds.length == parts.length ? 'Deselect All' : 'Select All'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Style Selector
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose Label Template',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SegmentedButton<LabelStyle>(
                  segments: const [
                    ButtonSegment(
                      value: LabelStyle.productBarcode,
                      label: Text('Barcode'),
                      icon: Icon(Icons.qr_code_2),
                    ),
                    ButtonSegment(
                      value: LabelStyle.shelfBinTag,
                      label: Text('Shelf Tag'),
                      icon: Icon(Icons.shelves),
                    ),
                    ButtonSegment(
                      value: LabelStyle.priceSticker,
                      label: Text('Price Tag'),
                      icon: Icon(Icons.sell),
                    ),
                  ],
                  selected: {_selectedStyle},
                  onSelectionChanged: (s) => setState(() => _selectedStyle = s.first),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search parts to print…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              itemCount: parts.length,
              itemBuilder: (_, i) {
                final p = parts[i];
                final isSelected = _selectedPartIds.contains(p.id);
                final copyCount = _copies[p.id] ?? 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedPartIds.add(p.id);
                              } else {
                                _selectedPartIds.remove(p.id);
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                  '${p.brand} • ${p.partNumber} • Loc: ${p.binLocation}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(.6))),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () {
                              if (copyCount > 1) {
                                setState(() => _copies[p.id] = copyCount - 1);
                              }
                            },
                          ),
                          Text('$copyCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              setState(() => _copies[p.id] = copyCount + 1);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
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
            icon: const Icon(Icons.print),
            label: Text('Print Selected Labels ($selectedCount items)'),
            onPressed: selectedCount == 0
                ? null
                : () async {
                    final listToPrint = <Part>[];
                    for (final id in _selectedPartIds) {
                      final p = invProv.byId(id);
                      if (p != null) {
                        final count = _copies[id] ?? 1;
                        for (int i = 0; i < count; i++) {
                          listToPrint.add(p);
                        }
                      }
                    }
                    await LabelService.printCustomLabels(listToPrint,
                        style: _selectedStyle);
                  },
          ),
        ),
      ),
    );
  }
}
