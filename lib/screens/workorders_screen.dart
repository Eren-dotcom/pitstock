import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/work_order.dart';
import '../providers/workorder_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'workorder_edit_screen.dart';

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  WorkOrderStatus? _filterStatus;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final wop = context.watch<WorkOrderProvider>();

    var orders = wop.searchOrders(_query);
    if (_filterStatus != null) {
      orders = orders.where((o) => o.status == _filterStatus).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workshop Job Cards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newOrder(context),
        icon: const Icon(Icons.add),
        label: const Text('New Job Card'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Jobs'),
                  selected: _filterStatus == null,
                  onSelected: (_) => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                ...WorkOrderStatus.values.map((st) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(st.label),
                        selected: _filterStatus == st,
                        onSelected: (_) => setState(() => _filterStatus = st),
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
                hintText: 'Search by job no, customer, mechanic, plate…',
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
            child: wop.loading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.build_circle_outlined,
                                size: 54,
                                color: Theme.of(context)
                                    .disabledColor
                                    .withOpacity(.4)),
                            const SizedBox(height: 8),
                            const Text('No job cards found'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: orders.length,
                        itemBuilder: (_, i) => _card(context, orders[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, WorkOrder wo) {
    final color = switch (wo.status) {
      WorkOrderStatus.completed => AppTheme.success,
      WorkOrderStatus.cancelled => AppTheme.danger,
      WorkOrderStatus.readyForDelivery => AppTheme.secondary,
      WorkOrderStatus.waitingParts => const Color(0xFFE91E63),
      WorkOrderStatus.inProgress => AppTheme.accent,
      WorkOrderStatus.open => AppTheme.primary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(Icons.build, color: color),
        ),
        title: Text('${wo.number} • ${wo.customerName}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${wo.vehicleInfo ?? wo.vehicleReg ?? 'No vehicle'} • ${wo.partCount} parts, ${wo.labourCount} services\n${Fmt.money(wo.grandTotal)} • ${wo.technician ?? 'Unassigned mechanic'}'),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(.14),
              borderRadius: BorderRadius.circular(16)),
          child: Text(wo.status.label,
              style: TextStyle(
                  color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
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
    final mechanic = TextEditingController();
    final complaints = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Workshop Job Card'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Customer Name *')),
              const SizedBox(height: 8),
              TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 8),
              TextField(
                  controller: reg,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Vehicle Reg (e.g. MH-12-AB-1234)')),
              const SizedBox(height: 8),
              TextField(
                  controller: info,
                  decoration: const InputDecoration(labelText: 'Vehicle Make / Model (e.g. Swift Dzire)')),
              const SizedBox(height: 8),
              TextField(
                  controller: mechanic,
                  decoration: const InputDecoration(labelText: 'Assigned Mechanic / Tech')),
              const SizedBox(height: 8),
              TextField(
                  controller: complaints,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Customer Complaints / Issues')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create Job Card')),
        ],
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty) {
      final wo = await context.read<WorkOrderProvider>().create(
            customerName: name.text.trim(),
            customerPhone: phone.text.trim().isEmpty ? null : phone.text.trim(),
            vehicleReg: reg.text.trim().isEmpty ? null : reg.text.trim(),
            vehicleInfo: info.text.trim().isEmpty ? null : info.text.trim(),
            technician: mechanic.text.trim().isEmpty ? null : mechanic.text.trim(),
            complaints: complaints.text.trim().isEmpty ? null : complaints.text.trim(),
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
