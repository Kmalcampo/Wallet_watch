import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/budget_provider.dart';
import 'screens/auth_gate.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const WalletWatchApp());
}

class WalletWatchApp extends StatelessWidget {
  const WalletWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BudgetProvider(),
      child: MaterialApp(
        title: 'Wallet Watch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: const AuthGate(),
      ),
    );
  }
}