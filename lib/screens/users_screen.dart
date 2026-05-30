import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Owner-only screen to manage staff and roles (RBAC).
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});
  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManage = auth.role.canManageUsers;

    return Scaffold(
      appBar: AppBar(title: const Text('Users & Roles')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _edit(context, auth, null),
              icon: const Icon(Icons.person_add),
              label: const Text('Add User'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canManage)
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock, color: AppTheme.danger),
                title: Text('Only the Owner can manage users.'),
              ),
            ),
          ...auth.users.map((u) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(.15),
                    child: const Icon(Icons.person, color: AppTheme.primary),
                  ),
                  title: Text(u.name),
                  subtitle: Text(u.role.label),
                  trailing: canManage
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _edit(context, auth, u)),
                          if (u.role != UserRole.owner)
                            IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => auth.deleteUser(u.id)),
                        ])
                      : Chip(label: Text(u.role.label)),
                ),
              )),
          const SizedBox(height: 16),
          Card(
            color: AppTheme.primary.withOpacity(.06),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Role capabilities',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('• Owner: full access incl. delete, users, invoice images'),
                  Text('• Manager: prices, reports, invoice images'),
                  Text('• Staff: stock & billing only; cannot see invoice images or prices edit'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, AuthProvider auth, AppUser? existing) {
    final name = TextEditingController(text: existing?.name ?? '');
    final pin = TextEditingController(text: existing?.pin ?? '');
    UserRole role = existing?.role ?? UserRole.staff;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add User' : 'Edit User'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: pin,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '4-digit PIN')),
            DropdownButtonFormField<UserRole>(
              value: role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: UserRole.values
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (r) => setState(() => role = r ?? UserRole.staff),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || pin.text.trim().length != 4) {
                  return;
                }
                final u = AppUser(
                  id: existing?.id ?? _uuid.v4(),
                  name: name.text.trim(),
                  pin: pin.text.trim(),
                  role: role,
                );
                existing == null ? auth.addUser(u) : auth.updateUser(u);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
