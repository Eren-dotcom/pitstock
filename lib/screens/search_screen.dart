import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../providers/inventory_provider.dart';
import '../services/search_service.dart';
import '../services/nl_search_service.dart';
import '../theme/app_theme.dart';
import '../widgets/part_tile.dart';
import 'part_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _speech = SpeechToText();
  bool _listening = false;
  bool _nlMode = true; // natural-language mode on by default
  SearchFilters _filters = SearchFilters();
  List<String> _understood = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runQuery(String text) {
    if (_nlMode) {
      final res = NlSearchService.parse(text);
      setState(() {
        _filters = res.filters;
        _understood = res.understood;
      });
    } else {
      setState(() {
        _filters.query = text;
        _understood = [];
      });
    }
  }

  Future<void> _voiceSearch() async {
    final available = await _speech.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition unavailable')));
      }
      return;
    }
    setState(() => _listening = true);
    _speech.listen(onResult: (r) {
      _controller.text = r.recognizedWords;
      _runQuery(r.recognizedWords);
      if (r.finalResult) setState(() => _listening = false);
    });
  }

  void _openFilters() async {
    final result = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
          filters: _filters.copy(), inv: context.read<InventoryProvider>()),
    );
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final results = inv.search(_filters);
    final suggestions = _controller.text.isNotEmpty && results.isEmpty && !_nlMode
        ? inv.suggestions(_controller.text)
        : <String>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: _runQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _nlMode
                        ? 'Ask e.g. "brake pads for swift under 1000"'
                        : 'Search name, part no, brand, vehicle…',
                    prefixIcon: Icon(
                        _nlMode ? Icons.auto_awesome : Icons.search,
                        color: _nlMode ? AppTheme.primary : null),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _controller.clear();
                              _filters = SearchFilters(sort: _filters.sort);
                              _understood = [];
                            }),
                          ),
                        IconButton(
                          icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                              color: _listening ? AppTheme.danger : null),
                          onPressed: _voiceSearch,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: _filters.hasActiveFilters,
                child: Container(
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: AppTheme.primary),
                    onPressed: _openFilters,
                  ),
                ),
              ),
            ],
          ),
        ),
        // NL / classic toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 16,
                  color: _nlMode
                      ? AppTheme.primary
                      : Theme.of(context).disabledColor),
              const SizedBox(width: 6),
              const Text('Smart (ask in plain words)',
                  style: TextStyle(fontSize: 12.5)),
              const Spacer(),
              Switch(
                value: _nlMode,
                onChanged: (v) {
                  setState(() => _nlMode = v);
                  _runQuery(_controller.text);
                },
              ),
            ],
          ),
        ),
        // Understood chips (what the AI parsed)
        if (_nlMode && _understood.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 2),
                    child: Text('Understood:',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ),
                  ..._understood.map((u) => Chip(
                        label: Text(u, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppTheme.primary.withOpacity(.12),
                        side: BorderSide.none,
                      )),
                ],
              ),
            ),
          ),
        // Example prompts when empty
        if (_nlMode && _controller.text.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: NlSearchService.examples
                    .map((e) => ActionChip(
                          label: Text(e, style: const TextStyle(fontSize: 11.5)),
                          avatar: const Icon(Icons.bolt, size: 14),
                          onPressed: () {
                            _controller.text = e;
                            _runQuery(e);
                          },
                        ))
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${results.length} results',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
              const Spacer(),
              DropdownButton<SearchSort>(
                value: _filters.sort,
                underline: const SizedBox.shrink(),
                isDense: true,
                items: SearchSort.values
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label,
                            style: const TextStyle(fontSize: 12.5))))
                    .toList(),
                onChanged: (s) =>
                    setState(() => _filters.sort = s ?? SearchSort.relevance),
              ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              children: suggestions
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            _controller.text = s;
                            _runQuery(s);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        Expanded(
          child: results.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: results.length,
                  itemBuilder: (_, i) => PartTile(
                    part: results[i],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                PartDetailScreen(partId: results[i].id))),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 64,
                color: Theme.of(context).disabledColor.withOpacity(.5)),
            const SizedBox(height: 12),
            const Text('No matching parts'),
            const SizedBox(height: 4),
            Text(
                _nlMode
                    ? 'Try rephrasing, e.g. "filters for creta"'
                    : 'Try fewer filters or check spelling',
                style: TextStyle(
                    fontSize: 12,
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(.5))),
          ],
        ),
      );
}

class _FilterSheet extends StatefulWidget {
  final SearchFilters filters;
  final InventoryProvider inv;
  const _FilterSheet({required this.filters, required this.inv});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchFilters f = widget.filters;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .75,
      maxChildSize: .9,
      minChildSize: .5,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.4),
                    borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text('Advanced Filters',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => f = SearchFilters(
                      query: f.query, sort: f.sort)),
                  child: const Text('Reset'),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _toggleTile('Only low stock', f.onlyLowStock,
                      (v) => setState(() => f.onlyLowStock = v)),
                  _toggleTile('Only out of stock', f.onlyOutOfStock,
                      (v) => setState(() => f.onlyOutOfStock = v)),
                  _toggleTile('Only OEM / genuine', f.oemOnly,
                      (v) => setState(() => f.oemOnly = v)),
                  const SizedBox(height: 8),
                  _facet('Category', widget.inv.allCategories, f.categories),
                  _facet('Brand / Maker', widget.inv.allBrands, f.brands),
                  _facet('Vehicle Make', widget.inv.allVehicleMakes,
                      f.vehicleMakes),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, f),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: onChanged,
      );

  Widget _facet(String title, List<String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final on = selected.contains(o);
            return FilterChip(
              label: Text(o, style: const TextStyle(fontSize: 12.5)),
              selected: on,
              onSelected: (_) => setState(() {
                on ? selected.remove(o) : selected.add(o);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}
