import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController();
  late final _phoneCtrl = TextEditingController();
  late final _emailCtrl = TextEditingController();
  late final _addrCtrl = TextEditingController();
  late final _stateCtrl = TextEditingController();
  late final _gstinCtrl = TextEditingController();
  late final _upiCtrl = TextEditingController();
  late final _termsCtrl = TextEditingController();
  late final _currCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _nameCtrl.text = s.shopName;
    _phoneCtrl.text = s.shopPhone;
    _emailCtrl.text = s.shopEmail;
    _addrCtrl.text = s.shopAddress;
    _stateCtrl.text = s.shopState;
    _gstinCtrl.text = s.gstin ?? '';
    _upiCtrl.text = s.upiId;
    _termsCtrl.text = s.invoiceFooterTerms;
    _currCtrl.text = s.currencySymbol;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Profile & GST')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: const [
                  Icon(Icons.storefront, color: Colors.white, size: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Information entered here appears on printed invoices, purchase orders & workshop job cards.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Shop / Garage Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone Number *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addrCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Shop Physical Address'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stateCtrl,
                    decoration: const InputDecoration(labelText: 'State (e.g. Maharashtra)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _currCtrl,
                    decoration: const InputDecoration(labelText: 'Currency Symbol'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gstinCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'GSTIN',
                hintText: '27AAAAA0000A1Z5',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _upiCtrl,
              decoration: const InputDecoration(
                labelText: 'UPI Payment ID (for Invoice QR Code)',
                hintText: 'shop@upi',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Invoice Terms & Conditions (Footer)',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Shop Profile'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (!_form.currentState!.validate()) return;
    final settings = context.read<SettingsProvider>();

    await settings.updateShopProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim(),
      upiId: _upiCtrl.text.trim(),
      terms: _termsCtrl.text.trim(),
      currencySymbol: _currCtrl.text.trim().isEmpty ? '₹' : _currCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop profile updated successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}
