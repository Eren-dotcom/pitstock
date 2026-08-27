import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  ThemeMode _themeMode = ThemeMode.system;
  String _currencySymbol = '₹';
  String _shopName = 'PitStock Auto Spares & Garage';
  String? _gstin;
  String _shopPhone = '+91 98765 00000';
  String _shopEmail = 'contact@pitstock.in';
  String _shopAddress = 'Shop No. 12, Main Auto Market, Opp. Bus Stand';
  String _shopState = 'Maharashtra';
  String _upiId = 'pitstock@okaxis';
  String _invoiceFooterTerms =
      '1. Goods once sold will not be taken back without original bill.\n'
      '2. Core deposit is refundable within 7 days on surrender of undamaged old unit.\n'
      '3. Warranty claims subject to manufacturer terms.';
  double _defaultGstPercent = 18.0;

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  String get shopName => _shopName;
  String? get gstin => _gstin;
  String get shopPhone => _shopPhone;
  String get shopEmail => _shopEmail;
  String get shopAddress => _shopAddress;
  String get shopState => _shopState;
  String get upiId => _upiId;
  String get invoiceFooterTerms => _invoiceFooterTerms;
  double get defaultGstPercent => _defaultGstPercent;

  Future<void> load() async {
    final t = await _db.getMeta('themeMode');
    if (t != null) {
      _themeMode = ThemeMode.values.firstWhere((m) => m.name == t,
          orElse: () => ThemeMode.system);
    }
    _shopName = await _db.getMeta('shopName') ?? _shopName;
    _gstin = await _db.getMeta('gstin');
    _shopPhone = await _db.getMeta('shopPhone') ?? _shopPhone;
    _shopEmail = await _db.getMeta('shopEmail') ?? _shopEmail;
    _shopAddress = await _db.getMeta('shopAddress') ?? _shopAddress;
    _shopState = await _db.getMeta('shopState') ?? _shopState;
    _upiId = await _db.getMeta('upiId') ?? _upiId;
    _invoiceFooterTerms =
        await _db.getMeta('invoiceFooterTerms') ?? _invoiceFooterTerms;
    _currencySymbol = await _db.getMeta('currencySymbol') ?? _currencySymbol;
    final gst = await _db.getMeta('defaultGstPercent');
    if (gst != null) {
      _defaultGstPercent = double.tryParse(gst) ?? 18.0;
    }
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

  Future<void> updateShopProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String state,
    String? gstin,
    required String upiId,
    required String terms,
    required String currencySymbol,
  }) async {
    _shopName = name;
    _shopPhone = phone;
    _shopEmail = email;
    _shopAddress = address;
    _shopState = state;
    _gstin = gstin;
    _upiId = upiId;
    _invoiceFooterTerms = terms;
    _currencySymbol = currencySymbol;

    await _db.setMeta('shopName', name);
    await _db.setMeta('shopPhone', phone);
    await _db.setMeta('shopEmail', email);
    await _db.setMeta('shopAddress', address);
    await _db.setMeta('shopState', state);
    if (gstin != null) await _db.setMeta('gstin', gstin);
    await _db.setMeta('upiId', upiId);
    await _db.setMeta('invoiceFooterTerms', terms);
    await _db.setMeta('currencySymbol', currencySymbol);

    notifyListeners();
  }
}
