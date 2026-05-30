import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/part.dart';
import '../providers/inventory_provider.dart';
import '../data/catalogue_data.dart';

class PartEditScreen extends StatefulWidget {
  final Part? existing;
  final String? prefillName;
  final String? prefillBarcode;
  const PartEditScreen(
      {super.key, this.existing, this.prefillName, this.prefillBarcode});

  @override
  State<PartEditScreen> createState() => _PartEditScreenState();
}

class _PartEditScreenState extends State<PartEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
      text: widget.existing?.name ?? widget.prefillName ?? '');
  late final _partNo =
      TextEditingController(text: widget.existing?.partNumber ?? '');
  late final _qty = TextEditingController(
      text: (widget.existing?.quantity ?? 0).toString());
  late final _low = TextEditingController(
      text: (widget.existing?.lowStockThreshold ?? 5).toString());
  late final _cost = TextEditingController(
      text: (widget.existing?.costPrice ?? 0).toStringAsFixed(0));
  late final _sell = TextEditingController(
      text: (widget.existing?.sellingPrice ?? 0).toStringAsFixed(0));
  late final _barcode = TextEditingController(
      text: widget.existing?.barcode ?? widget.prefillBarcode ?? '');
  late final _location =
      TextEditingController(text: widget.existing?.location ?? '');
  late final _notes =
      TextEditingController(text: widget.existing?.notes ?? '');

  late String _brand = widget.existing?.brand ?? CatalogueData.brands.first;
  late String _category =
      widget.existing?.category ?? CatalogueData.categories.first;
  late String _vehicleMake =
      widget.existing?.vehicleMake ?? CatalogueData.vehicleMakes.last;
  late final _model =
      TextEditingController(text: widget.existing?.vehicleModel ?? '');
  late String _unit = widget.existing?.unit ?? 'pcs';
  late double _gst = widget.existing?.gstPercent ?? 18;
  late PartType _partType = widget.existing?.partType ?? PartType.aftermarket;
  late final _yearFrom = TextEditingController(
      text: widget.existing?.yearFrom?.toString() ?? '');
  late final _yearTo =
      TextEditingController(text: widget.existing?.yearTo?.toString() ?? '');
  late final _shelf =
      TextEditingController(text: widget.existing?.shelf ?? '');
  late final _bin = TextEditingController(text: widget.existing?.bin ?? '');
  late final _coreCharge = TextEditingController(
      text: (widget.existing?.coreCharge ?? 0).toStringAsFixed(0));
  late bool _hasCore = widget.existing?.hasCore ?? false;

  @override
  Widget build(BuildContext context) {
    final inv = context.read<InventoryProvider>();
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit Part' : 'Add Part')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Part name *', required: true),
            _field(_partNo, 'Part number'),
            Row(children: [
              Expanded(child: _dropdown('Category', CatalogueData.categories,
                  _category, (v) => setState(() => _category = v!))),
              const SizedBox(width: 12),
              Expanded(child: _dropdown('Brand / Maker', CatalogueData.brands,
                  _brand, (v) => setState(() => _brand = v!))),
            ]),
            const SizedBox(height: 12),
            // OEM vs Aftermarket
            const SizedBox(height: 4),
            SegmentedButton<PartType>(
              segments: const [
                ButtonSegment(
                    value: PartType.oem, label: Text('OEM (Genuine)')),
                ButtonSegment(
                    value: PartType.aftermarket, label: Text('Aftermarket')),
              ],
              selected: {_partType},
              onSelectionChanged: (s) => setState(() => _partType = s.first),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _dropdown('Vehicle make', CatalogueData.vehicleMakes,
                      _vehicleMake, (v) => setState(() => _vehicleMake = v!))),
              const SizedBox(width: 12),
              Expanded(child: _field(_model, 'Model')),
            ]),
            const SizedBox(height: 12),
            // Fitment year range
            Row(children: [
              Expanded(child: _field(_yearFrom, 'Year from', number: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_yearTo, 'Year to', number: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _field(_qty, 'Quantity', number: true)),
              const SizedBox(width: 12),
              Expanded(child: _dropdown('Unit',
                  const ['pcs', 'set', 'litre', 'box', 'pair'], _unit,
                  (v) => setState(() => _unit = v!))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_cost, 'Cost price ₹', number: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_sell, 'Selling price ₹', number: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_low, 'Low-stock alert', number: true)),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown(
                    'GST %',
                    const ['0', '5', '12', '18', '28'],
                    _gst.toStringAsFixed(0),
                    (v) => setState(() => _gst = double.parse(v!))),
              ),
            ]),
            const SizedBox(height: 12),
            // Shelf / bin location tracking
            Row(children: [
              Expanded(child: _field(_shelf, 'Shelf (e.g. A1)')),
              const SizedBox(width: 12),
              Expanded(child: _field(_bin, 'Bin (e.g. 03)')),
            ]),
            const SizedBox(height: 4),
            // Core charge tracking
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Carries a core charge'),
              subtitle:
                  const Text('Refundable deposit on returnable old part'),
              value: _hasCore,
              onChanged: (v) => setState(() => _hasCore = v),
            ),
            if (_hasCore) _field(_coreCharge, 'Core charge ₹', number: true),
            const SizedBox(height: 8),
            _field(_barcode, 'Barcode'),
            _field(_location, 'Rack / location (legacy)'),
            _field(_notes, 'Notes', maxLines: 3),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text(editing ? 'Save Changes' : 'Add to Inventory'),
              onPressed: () => _save(inv, editing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool number = false, bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _dropdown(String label, List<String> options, String value,
      ValueChanged<String?> onChanged) {
    final safe = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      value: safe,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((o) => DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _save(InventoryProvider inv, bool editing) async {
    if (!_form.currentState!.validate()) return;
    final qty = int.tryParse(_qty.text) ?? 0;
    if (editing) {
      final updated = widget.existing!.copyWith(
        name: _name.text.trim(),
        partNumber: _partNo.text.trim(),
        brand: _brand,
        category: _category,
        partType: _partType,
        vehicleMake: _vehicleMake,
        vehicleModel: _model.text.trim().isEmpty ? null : _model.text.trim(),
        yearFrom: int.tryParse(_yearFrom.text),
        yearTo: int.tryParse(_yearTo.text),
        unit: _unit,
        quantity: qty,
        lowStockThreshold: int.tryParse(_low.text) ?? 5,
        costPrice: double.tryParse(_cost.text) ?? 0,
        sellingPrice: double.tryParse(_sell.text) ?? 0,
        gstPercent: _gst,
        coreCharge: _hasCore ? (double.tryParse(_coreCharge.text) ?? 0) : 0,
        hasCore: _hasCore,
        shelf: _shelf.text.trim().isEmpty ? null : _shelf.text.trim(),
        bin: _bin.text.trim().isEmpty ? null : _bin.text.trim(),
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      await inv.updatePart(updated);
    } else {
      await inv.addPart(
        name: _name.text.trim(),
        partNumber: _partNo.text.trim(),
        brand: _brand,
        category: _category,
        partType: _partType,
        vehicleMake: _vehicleMake,
        vehicleModel: _model.text.trim().isEmpty ? null : _model.text.trim(),
        yearFrom: int.tryParse(_yearFrom.text),
        yearTo: int.tryParse(_yearTo.text),
        unit: _unit,
        quantity: qty,
        lowStockThreshold: int.tryParse(_low.text) ?? 5,
        costPrice: double.tryParse(_cost.text) ?? 0,
        sellingPrice: double.tryParse(_sell.text) ?? 0,
        gstPercent: _gst,
        coreCharge: _hasCore ? (double.tryParse(_coreCharge.text) ?? 0) : 0,
        hasCore: _hasCore,
        shelf: _shelf.text.trim().isEmpty ? null : _shelf.text.trim(),
        bin: _bin.text.trim().isEmpty ? null : _bin.text.trim(),
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }
}
