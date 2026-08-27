import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stock_movement.dart';
import '../providers/inventory_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  MovementType? _selectedType;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement Audit Log'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download),
            onPressed: () async {
              final all = await invProv.movements(limit: 500);
              if (context.mounted) {
                await ExportService.exportMovementsCsv(context, all);
              }
            },
          ),
        ],
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
                  label: const Text('All Types'),
                  selected: _selectedType == null,
                  onSelected: (_) => setState(() => _selectedType = null),
                ),
                const SizedBox(width: 8),
                ...MovementType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t.label),
                        selected: _selectedType == t,
                        onSelected: (_) => setState(() => _selectedType = t),
                      ),
                    )),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search reference, part name, bill no…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<StockMovement>>(
              future: invProv.movements(limit: 300),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var list = snap.data!;
                if (_selectedType != null) {
                  list = list.where((m) => m.type == _selectedType).toList();
                }
                if (_query.isNotEmpty) {
                  final q = _query.toLowerCase();
                  list = list.where((m) {
                    final part = invProv.byId(m.partId);
                    final partName = part?.name.toLowerCase() ?? '';
                    final ref = m.reference?.toLowerCase() ?? '';
                    return partName.contains(q) || ref.contains(q);
                  }).toList();
                }

                if (list.isEmpty) {
                  return const Center(child: Text('No stock movements found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final part = invProv.byId(m.partId);
                    final isPos = m.delta >= 0;
                    final color = isPos ? AppTheme.success : AppTheme.danger;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(.15),
                          child: Icon(
                            isPos ? Icons.arrow_downward : Icons.arrow_upward,
                            color: color,
                          ),
                        ),
                        title: Text(
                            part != null
                                ? '${part.name} (${part.brand})'
                                : 'Part #${m.partId.substring(0, 6)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${m.type.label} • ${m.reference ?? 'Manual change'}\n${Fmt.date(m.date)}'),
                        isThreeLine: true,
                        trailing: Text(
                          '${isPos ? '+' : ''}${m.delta}',
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
