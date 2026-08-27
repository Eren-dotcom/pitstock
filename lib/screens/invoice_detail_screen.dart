import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../services/invoice_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InvoiceProvider>();
    final settings = context.watch<SettingsProvider>();
    final invoice = invProv.byId(invoiceId);

    if (invoice == null) {
      return const Scaffold(body: Center(child: Text('Invoice not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.number),
        actions: [
          IconButton(
            tooltip: 'Print Tax Bill',
            icon: const Icon(Icons.print),
            onPressed: () => _printPdf(context, invoice, settings),
          ),
          if (!invoice.isCancelled)
            IconButton(
              tooltip: 'Cancel / Refund',
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.danger),
              onPressed: () => _confirmCancel(context, invoice),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (invoice.isCancelled)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.danger.withOpacity(.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: AppTheme.danger),
                  SizedBox(width: 8),
                  Text('This invoice has been CANCELLED / REFUNDED.',
                      style: TextStyle(
                          color: AppTheme.danger, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(invoice.number,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(invoice.paymentMethod.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Date: ${Fmt.date(invoice.createdAt)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                Text(invoice.customerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                if (invoice.customerPhone != null || invoice.vehicleReg != null)
                  Text(
                      '${invoice.customerPhone ?? ''}  ${invoice.vehicleReg != null ? '• ${invoice.vehicleReg}' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('Itemized Breakdown (${invoice.lines.length} items)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          // Lines
          ...invoice.lines.map((l) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(l.isLabour ? Icons.engineering : Icons.settings,
                          size: 20, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                                '${l.quantity} × ${Fmt.money(l.unitPrice)} • GST ${l.gstPercent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(.6))),
                          ],
                        ),
                      ),
                      Text(Fmt.money(l.total),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 12),

          // Totals Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totRow('Subtotal', invoice.subtotal),
                  if (invoice.discountAmount > 0)
                    _totRow('Discount', -invoice.discountAmount, isDiscount: true),
                  _totRow('CGST (${(invoice.gstTotal > 0 ? '9%' : '0%')})', invoice.cgstTotal),
                  _totRow('SGST (${(invoice.gstTotal > 0 ? '9%' : '0%')})', invoice.sgstTotal),
                  if (invoice.coreTotal > 0)
                    _totRow('Core Deposit', invoice.coreTotal),
                  const Divider(),
                  _totRow('Grand Total', invoice.grandTotal, bold: true),
                ],
              ),
            ),
          ),

          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.notes, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(invoice.notes!,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print / Share PDF Invoice'),
            onPressed: () => _printPdf(context, invoice, settings),
          ),
        ],
      ),
    );
  }

  Widget _totRow(String label, double v,
      {bool bold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                  fontSize: bold ? 16 : 13.5)),
          Text(
              '${isDiscount ? '−' : ''}${Fmt.money(v.abs())}',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                  fontSize: bold ? 16 : 13.5,
                  color: isDiscount ? AppTheme.success : null)),
        ],
      ),
    );
  }

  Future<void> _printPdf(
      BuildContext context, Invoice invoice, SettingsProvider settings) async {
    await InvoiceService.printInvoice(
      invoice: invoice,
      shopName: settings.shopName,
      shopGstin: settings.gstin,
      shopPhone: settings.shopPhone,
      shopAddress: settings.shopAddress,
      upiId: settings.upiId,
      footerTerms: settings.invoiceFooterTerms,
    );
  }

  void _confirmCancel(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel & Refund Invoice?'),
        content: Text(
            'This will mark "${invoice.number}" as cancelled and return all part quantities back to inventory.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Bill')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              final invProv = context.read<InventoryProvider>();
              final invoiceProv = context.read<InvoiceProvider>();
              await invoiceProv.cancelAndRefundInvoice(invoice.id,
                  inventory: invProv);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice cancelled & stock restored.')));
              }
            },
            child: const Text('Cancel & Restore Stock'),
          ),
        ],
      ),
    );
  }
}
