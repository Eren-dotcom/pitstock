import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/work_order.dart';
import '../providers/workorder_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'workorder_edit_screen.dart';

class WorkOrdersScreen extends StatelessWidget {
  const WorkOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wop = context.watch<WorkOrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Work Orders / Job Cards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newOrder(context),
        icon: const Icon(Icons.add),
        label: const Text('New Job'),
      ),
      body: wop.loading
          ? const Center(child: CircularProgressIndicator())
          : wop.orders.isEmpty
              ? const Center(child: Text('No job cards yet. Create one.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wop.orders.length,
                  itemBuilder: (_, i) => _card(context, wop.orders[i]),
                ),
    );
  }

  Widget _card(BuildContext context, WorkOrder wo) {
    final color = switch (wo.status) {
      WorkOrderStatus.completed => AppTheme.success,
      WorkOrderStatus.cancelled => AppTheme.danger,
      WorkOrderStatus.inProgress => AppTheme.accent,
      WorkOrderStatus.open => AppTheme.primary,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(Icons.build, color: color),
        ),
        title: Text('${wo.number} • ${wo.customerName}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${wo.vehicleInfo ?? wo.vehicleReg ?? '—'} • ${wo.partCount} parts\n${Fmt.money(wo.grandTotal)}'),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(.14),
              borderRadius: BorderRadius.circular(20)),
          child: Text(wo.status.label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => WorkOrderEditScreen(orderId: wo.id))),
      ),
    );
  }

  Future<void> _newOrder(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final reg = TextEditingController();
    final info = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Job Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Customer name *')),
            TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Phone')),
            TextField(
                controller: reg,
                decoration:
                    const InputDecoration(labelText: 'Vehicle reg no')),
            TextField(
                controller: info,
                decoration: const InputDecoration(
                    labelText: 'Vehicle (make/model/year)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      final wo = await context.read<WorkOrderProvider>().create(
            customerName: name.text.trim(),
            customerPhone: phone.text.trim().isEmpty ? null : phone.text.trim(),
            vehicleReg: reg.text.trim().isEmpty ? null : reg.text.trim(),
            vehicleInfo: info.text.trim().isEmpty ? null : info.text.trim(),
          );
      if (context.mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => WorkOrderEditScreen(orderId: wo.id)));
      }
    }
  }
}
