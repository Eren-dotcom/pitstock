import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InvoiceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice History')),
      body: inv.invoices.isEmpty
          ? const Center(child: Text('No invoices generated yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inv.invoices.length,
              itemBuilder: (_, i) {
                final r = inv.invoices[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondary.withOpacity(.15),
                      child: const Icon(Icons.receipt,
                          color: AppTheme.secondary),
                    ),
                    title: Text('${r['number']} • ${r['customerName']}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(Fmt.date(
                        DateTime.parse(r['createdAt'] as String))),
                    trailing: Text(
                        Fmt.money((r['grandTotal'] as num).toDouble()),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
    );
  }
}
