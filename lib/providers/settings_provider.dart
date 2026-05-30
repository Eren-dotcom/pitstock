import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  ThemeMode _themeMode = ThemeMode.system;
  String _currencySymbol = '₹';
  String _shopName = 'My Spare Parts Shop';
  String? _gstin;

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  String get shopName => _shopName;
  String? get gstin => _gstin;

  Future<void> load() async {
    final t = await _db.getMeta('themeMode');
    if (t != null) {
      _themeMode = ThemeMode.values.firstWhere((m) => m.name == t,
          orElse: () => ThemeMode.system);
    }
    _shopName = await _db.getMeta('shopName') ?? _shopName;
    _gstin = await _db.getMeta('gstin');
    notifyListeners();
  }

  Future<void> setGstin(String value) async {
    _gstin = value;
    await _db.setMeta('gstin', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _db.setMeta('themeMode', mode.name);
    notifyListeners();
  }

  Future<void> setShopName(String name) async {
    _shopName = name;
    await _db.setMeta('shopName', name);
    notifyListeners();
  }
}
