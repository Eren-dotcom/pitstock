import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/part.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/invoice_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'invoice_detail_screen.dart';

/// Fast counter POS / Direct Billing Screen for walk-in sales & regular customers.
class PosBillingScreen extends StatefulWidget {
  final Customer? prefillCustomer;
  const PosBillingScreen({super.key, this.prefillCustomer});

  @override
  State<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends State<PosBillingScreen> {
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _vehicleRegCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  Customer? _selectedCustomer;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final List<InvoiceLine> _cart = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillCustomer != null) {
      _selectCustomer(widget.prefillCustomer!);
    }
  }

  void _selectCustomer(Customer c) {
    setState(() {
      _selectedCustomer = c;
      _customerNameCtrl.text = c.name;
      _customerPhoneCtrl.text = c.phone;
      if (c.vehicles.isNotEmpty) {
        _vehicleRegCtrl.text = c.vehicles.first.regNumber;
      }
    });
  }

  double get _subtotal => _cart.fold(0.0, (s, l) => s + l.subtotal);
  double get _gstTotal => _cart.fold(0.0, (s, l) => s + l.gstAmount);
  double get _coreTotal => _cart.fold(0.0, (s, l) => s + l.coreAmount);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0.0;
  double get _grandTotal =>
      (_subtotal + _gstTotal + _coreTotal - _discount).clamp(0.0, double.infinity);

  void _addItem(Part p) {
    final idx = _cart.indexWhere((l) => l.partId == p.id);
    setState(() {
      if (idx >= 0) {
        final cur = _cart[idx];
        _cart[idx] = InvoiceLine(
          partId: cur.partId,
          name: cur.name,
          partNumber: cur.partNumber,
          quantity: cur.quantity + 1,
          unitPrice: cur.unitPrice,
          gstPercent: cur.gstPercent,
          coreCharge: cur.coreCharge,
          isLabour: cur.isLabour,
          coreReturned: cur.coreReturned,
        );
      } else {
        _cart.add(InvoiceLine(
          partId: p.id,
          name: p.name,
          partNumber: p.partNumber,
          quantity: 1,
          unitPrice: p.sellingPrice,
          gstPercent: p.gstPercent,
          coreCharge: p.coreCharge,
          isLabour: false,
        ));
      }
    });
  }

  void _addLabour() async {
    final nameCtrl = TextEditingController(text: 'Labour / Fitment Charge');
    final amountCtrl = TextEditingController(text: '300');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Service / Labour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount ₹')),
          ],
        ),
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
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      setState(() {
        _cart.add(InvoiceLine(
          partId: '',
          name: nameCtrl.text.trim(),
          quantity: 1,
          unitPrice: amount,
          gstPercent: 18,
          isLabour: true,
        ));
      });
    }
  }

  void _pickCustomer() async {
    final custProv = context.read<CustomerProvider>();
    final customer = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CustomerPicker(customers: custProv.customers),
    );
    if (customer != null) {
      _selectCustomer(customer);
    }
  }

  void _pickPartFromCatalogue() async {
    final inv = context.read<InventoryProvider>();
    final part = await showModalBottomSheet<Part>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PosPartPicker(parts: inv.parts),
    );
    if (part != null) {
      _addItem(part);
    }
  }

  Future<void> _completeCheckout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add items to cart before checkout.')));
      return;
    }
    final custName = _customerNameCtrl.text.trim().isEmpty
        ? 'Walk-in Customer'
        : _customerNameCtrl.text.trim();

    setState(() => _busy = true);

    try {
      final invProv = context.read<InventoryProvider>();
      final invoiceProv = context.read<InvoiceProvider>();
      final custProv = context.read<CustomerProvider>();
      final settings = context.read<SettingsProvider>();

      final invoice = await invoiceProv.createDirectSale(
        customerId: _selectedCustomer?.id,
        customerName: custName,
        customerPhone: _customerPhoneCtrl.text.trim().isEmpty
            ? null
            : _customerPhoneCtrl.text.trim(),
        vehicleReg: _vehicleRegCtrl.text.trim().isEmpty
            ? null
            : _vehicleRegCtrl.text.trim(),
        lines: _cart,
        discountAmount: _discount,
        paymentMethod: _paymentMethod,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        inventory: invProv,
        customerProvider: custProv,
      );

      if (!mounted) return;
      setState(() => _busy = false);

      // Offer instant print or view
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.success, size: 28),
              SizedBox(width: 8),
              Text('Sale Completed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bill No: ${invoice.number}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Total: ${Fmt.money(invoice.grandTotal)} (${invoice.paymentMethod.label})'),
              const SizedBox(height: 4),
              const Text('Stock deducted automatically from inventory.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close POS
              },
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Print Tax Bill'),
              onPressed: () async {
                await InvoiceService.printInvoice(
                  invoice: invoice,
                  shopName: settings.shopName,
                  shopGstin: settings.gstin,
                  shopPhone: settings.shopPhone,
                  shopAddress: settings.shopAddress,
                  upiId: settings.upiId,
                  footerTerms: settings.invoiceFooterTerms,
                );
              },
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
                  ),
                );
              },
              child: const Text('View Bill'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS / Quick Billing'),
        actions: [
          IconButton(
            tooltip: 'Add Part',
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: _pickPartFromCatalogue,
          ),
          IconButton(
            tooltip: 'Add Labour',
            icon: const Icon(Icons.engineering),
            onPressed: _addLabour,
          ),
        ],
      ),
      body: Column(
        children: [
          _customerSection(),
          Expanded(
            child: _cart.isEmpty
                ? _emptyCart()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _cart.length,
                    itemBuilder: (_, i) => _cartItemTile(_cart[i], i),
                  ),
          ),
          _checkoutSummaryBar(),
        ],
      ),
    );
  }

  Widget _customerSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    prefixIcon: Icon(Icons.person),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.contacts, color: AppTheme.primary),
                tooltip: 'Select Existing Customer',
                onPressed: _pickCustomer,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone No.',
                    prefixIcon: Icon(Icons.phone),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _vehicleRegCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Reg (e.g. MH-12-AB-1234)',
                    prefixIcon: Icon(Icons.directions_car),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Theme.of(context).disabledColor.withOpacity(.4)),
          const SizedBox(height: 12),
          const Text('Cart is empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Tap below to add parts or labour charges.'),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Add Part'),
                onPressed: _pickPartFromCatalogue,
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.engineering),
                label: const Text('Add Labour'),
                onPressed: _addLabour,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartItemTile(InvoiceLine item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(item.isLabour ? Icons.engineering : Icons.settings,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(Fmt.money(item.total),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                  onPressed: () => setState(() => _cart.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Rate: ${Fmt.money(item.unitPrice)} • GST ${item.gstPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
                const Spacer(),
                // Qty buttons
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.4)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (item.quantity > 1) {
                              _cart[index] = InvoiceLine(
                                partId: item.partId,
                                name: item.name,
                                partNumber: item.partNumber,
                                quantity: item.quantity - 1,
                                unitPrice: item.unitPrice,
                                gstPercent: item.gstPercent,
                                coreCharge: item.coreCharge,
                                isLabour: item.isLabour,
                                coreReturned: item.coreReturned,
                              );
                            } else {
                              _cart.removeAt(index);
                            }
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _cart[index] = InvoiceLine(
                              partId: item.partId,
                              name: item.name,
                              partNumber: item.partNumber,
                              quantity: item.quantity + 1,
                              unitPrice: item.unitPrice,
                              gstPercent: item.gstPercent,
                              coreCharge: item.coreCharge,
                              isLabour: item.isLabour,
                              coreReturned: item.coreReturned,
                            );
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.coreCharge > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Checkbox(
                    value: item.coreReturned,
                    onChanged: (v) {
                      setState(() {
                        _cart[index] = InvoiceLine(
                          partId: item.partId,
                          name: item.name,
                          partNumber: item.partNumber,
                          quantity: item.quantity,
                          unitPrice: item.unitPrice,
                          gstPercent: item.gstPercent,
                          coreCharge: item.coreCharge,
                          isLabour: item.isLabour,
                          coreReturned: v ?? false,
                        );
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                        'Old core returned (saves ${Fmt.money(item.coreCharge * item.quantity)})',
                        style: const TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _checkoutSummaryBar() {
    return Container(
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
              children: [
                Expanded(
                  child: DropdownButtonFormField<PaymentMethod>(
                    value: _paymentMethod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: PaymentMethod.values
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.label, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _paymentMethod = v ?? PaymentMethod.cash),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Discount ₹',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items (${_cart.length}): ${Fmt.money(_subtotal)} • GST: ${Fmt.money(_gstTotal)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Total: ${Fmt.money(_grandTotal)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.receipt_long),
                label: Text(_busy ? 'Processing Sale…' : 'Generate Bill & Pay ${Fmt.money(_grandTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onPressed: _busy || _cart.isEmpty ? null : _completeCheckout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosPartPicker extends StatefulWidget {
  final List<Part> parts;
  const _PosPartPicker({required this.parts});
  @override
  State<_PosPartPicker> createState() => _PosPartPickerState();
}

class _PosPartPickerState extends State<_PosPartPicker> {
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
                hintText: 'Search part by name, part no, brand…',
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
                      '${p.brand} • ${p.partNumber} • Stock: ${p.quantity} • Loc: ${p.binLocation}'),
                  trailing: Text(Fmt.money(p.sellingPrice),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
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

class _CustomerPicker extends StatefulWidget {
  final List<Customer> customers;
  const _CustomerPicker({required this.customers});
  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.customers
        .where((c) =>
            _q.isEmpty ||
            c.name.toLowerCase().contains(_q.toLowerCase()) ||
            c.phone.contains(_q) ||
            c.vehicles.any((v) => v.regNumber.toLowerCase().contains(_q.toLowerCase())))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search customer name, phone, vehicle plate…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No customers found.'))
                : ListView.builder(
                    controller: scroll,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final c = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(.15),
                          child: const Icon(Icons.person, color: AppTheme.primary),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${c.phone}${c.vehicles.isNotEmpty ? ' • ${c.vehicles.first.regNumber}' : ''}'),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
