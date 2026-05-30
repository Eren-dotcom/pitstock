import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/part_tile.dart';
import 'part_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final cats = ['All', ...inv.allCategories];
    final parts = _category == null || _category == 'All'
        ? inv.parts
        : inv.parts.where((p) => p.category == _category).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text('Inventory',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${parts.length} items',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = cats[i];
              final selected =
                  _category == c || (_category == null && c == 'All');
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _category = c == 'All' ? null : c),
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: parts.isEmpty
              ? const Center(child: Text('No parts in this category'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: parts.length,
                  itemBuilder: (_, i) => PartTile(
                    part: parts[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PartDetailScreen(partId: parts[i].id)),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
