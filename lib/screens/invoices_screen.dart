import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'invoice_detail_screen.dart';
import 'pos_billing_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InvoiceProvider>();
    final list = invProv.searchInvoices(_query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices & Sales'),
        actions: [
          IconButton(
            tooltip: 'Export Sales CSV',
            icon: const Icon(Icons.download),
            onPressed: () =>
                ExportService.exportInvoicesCsv(context, invProv.invoices),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const PosBillingScreen())),
        icon: const Icon(Icons.point_of_sale),
        label: const Text('New Sale / POS'),
      ),
      body: Column(
        children: [
          // Revenue Summary Banner
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Total Sales', Fmt.compactMoney(invProv.totalSalesRevenue)),
                Container(width: 1, height: 36, color: Colors.white24),
                _stat('Invoices', '${invProv.totalInvoicesCount}'),
                Container(width: 1, height: 36, color: Colors.white24),
                _stat('GST Collected', Fmt.compactMoney(invProv.totalGstCollected)),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by bill no, customer, phone, plate…',
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
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 54,
                            color: Theme.of(context)
                                .disabledColor
                                .withOpacity(.4)),
                        const SizedBox(height: 8),
                        const Text('No invoices found'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _invoiceTile(context, list[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _invoiceTile(BuildContext context, Invoice inv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(invoiceId: inv.id)),
        ),
        leading: CircleAvatar(
          backgroundColor: inv.isCancelled
              ? AppTheme.danger.withOpacity(.15)
              : AppTheme.secondary.withOpacity(.15),
          child: Icon(
            inv.isCancelled ? Icons.cancel : Icons.receipt,
            color: inv.isCancelled ? AppTheme.danger : AppTheme.secondary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text('${inv.number} • ${inv.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration:
                          inv.isCancelled ? TextDecoration.lineThrough : null)),
            ),
            if (inv.isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('CANCELLED',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Text(
            '${Fmt.date(inv.createdAt)} • ${inv.paymentMethod.label}\n${inv.totalItemCount} items${inv.vehicleReg != null ? ' • ${inv.vehicleReg}' : ''}'),
        isThreeLine: true,
        trailing: Text(
          Fmt.money(inv.grandTotal),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: inv.isCancelled ? Colors.grey : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
