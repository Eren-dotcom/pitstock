import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
import '../models/app_user.dart';

/// Role-Based Access Control session state.
class AuthProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<AppUser> _users = [];
  AppUser? _current;

  List<AppUser> get users => _users;
  AppUser? get current => _current;
  UserRole get role => _current?.role ?? UserRole.staff;
  bool get isLoggedIn => _current != null;

  Future<void> load() async {
    _users = await _db.getUsers();
    notifyListeners();
  }

  /// Try to log in by user id + pin.
  bool login(String userId, String pin) {
    final matches = _users.where((e) => e.id == userId && e.pin == pin);
    if (matches.isNotEmpty) {
      _current = matches.first;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _current = null;
    notifyListeners();
  }

  Future<void> addUser(AppUser u) async {
    await _db.upsertUser(u);
    await load();
  }

  Future<void> updateUser(AppUser u) async {
    await _db.upsertUser(u);
    await load();
  }

  Future<void> deleteUser(String id) async {
    await _db.deleteUser(id);
    await load();
  }
}
