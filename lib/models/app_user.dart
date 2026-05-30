/// Role-Based Access Control roles.
enum UserRole { owner, manager, staff }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.owner => 'Owner',
        UserRole.manager => 'Manager',
        UserRole.staff => 'Staff',
      };

  /// Capability matrix used across the app.
  bool get canViewInvoiceImages => this != UserRole.staff; // owner & manager
  bool get canEditPrices => this != UserRole.staff;
  bool get canDeleteParts => this == UserRole.owner;
  bool get canManageUsers => this == UserRole.owner;
  bool get canViewReports => this != UserRole.staff;
  bool get canEditInventory => true; // all roles can adjust stock
  bool get canBillCustomers => true;
  bool get canBackup => this == UserRole.owner; // owner-only data export/restore
}

class AppUser {
  final String id;
  String name;
  String pin; // simple 4-digit pin for local auth (demo)
  UserRole role;

  AppUser({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'pin': pin,
        'role': role.name,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        name: m['name'] as String,
        pin: m['pin'] as String? ?? '0000',
        role: UserRole.values
            .firstWhere((e) => e.name == m['role'], orElse: () => UserRole.staff),
      );
}
