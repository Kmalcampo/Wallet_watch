import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/budget_provider.dart';
import '../services/supabase_service.dart';
import 'root_screen.dart';
import 'welcome_screen.dart';

/// The very first widget the app shows. It listens to Supabase's auth
/// state and swaps between WelcomeScreen (logged out) and RootScreen
/// (logged in).
///
/// Data is loaded exactly once per login — Supabase's auth stream also
/// fires on background events like token refreshes, so naively
/// reloading on every stream event would silently re-fetch your data
/// over and over even while just sitting on the Home screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _loadedForUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = SupabaseService.client.auth.currentSession;
        final userId = session?.user.id;

        if (userId == null) {
          _loadedForUserId = null; // reset so a future login reloads fresh
          return const WelcomeScreen();
        }

        // Only fire the data load the first time we see this user's id,
        // not on every subsequent stream event (token refresh, etc.).
        if (_loadedForUserId != userId) {
          _loadedForUserId = userId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final provider = context.read<BudgetProvider>();
            provider.loadCurrentPeriod();
            provider.loadSavingsGoals();
          });
        }

        return const RootScreen();
      },
    );
  }
}