import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'data/database_helper.dart';
import 'data/seed_data.dart';
import 'providers/inventory_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/workorder_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/customer_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialise DB and seed the Indian car spare-parts catalogue & vendors on first run.
  final db = DatabaseHelper.instance;
  await db.database;
  await SeedData.ensureSeeded(db);

  runApp(const PitStockApp());
}

class PitStockApp extends StatelessWidget {
  const PitStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..load()),
        ChangeNotifierProvider(create: (_) => WorkOrderProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()..bootstrap()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'PitStock',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
