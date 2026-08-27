import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'customer_detail_screen.dart';
import 'customer_edit_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final custProv = context.watch<CustomerProvider>();
    final list = custProv.search(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Directory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerEditScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('New Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by customer name, phone, vehicle plate…',
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
                        Icon(Icons.person_search_outlined,
                            size: 54,
                            color: Theme.of(context)
                                .disabledColor
                                .withOpacity(.4)),
                        const SizedBox(height: 8),
                        const Text('No customers found'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _customerCard(context, list[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _customerCard(BuildContext context, Customer c) {
    final vehicleText = c.vehicles.isNotEmpty
        ? c.vehicles.map((v) => '${v.make} ${v.model} (${v.regNumber})').join(', ')
        : 'No vehicle registered';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customerId: c.id)),
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(.15),
          child: const Icon(Icons.person, color: AppTheme.primary),
        ),
        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${c.phone}\n$vehicleText',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Fmt.money(c.totalSpent),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primary)),
            Text('${c.visitCount} visits',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
