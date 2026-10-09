import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Whole pesos show without decimals (₱500), otherwise two decimals.
String _peso(double v) {
  return v == v.roundToDouble()
      ? '₱${v.toStringAsFixed(0)}'
      : '₱${v.toStringAsFixed(2)}';
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  String _name() {
    final user = SupabaseService.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name']?.toString();

    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'WalletWatch User';
  }

  String _signInMethod() {
    final user = SupabaseService.client.auth.currentUser;
    final provider = user?.appMetadata['provider']?.toString() ?? 'email';

    switch (provider) {
      case 'google':
        return 'Google';
      case 'facebook':
        return 'Facebook';
      default:
        return 'Email & password';
    }
  }

  IconData _signInIcon() {
    final user = SupabaseService.client.auth.currentUser;
    final provider = user?.appMetadata['provider']?.toString() ?? 'email';

    switch (provider) {
      case 'google':
      case 'facebook':
        return Icons.verified_user_rounded;
      default:
        return Icons.mail_outline_rounded;
    }
  }

  String? _memberSince() {
    final created = SupabaseService.client.auth.currentUser?.createdAt;
    if (created == null) return null;

    final date = DateTime.tryParse(created);
    if (date == null) return null;

    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            "You'll need to log in again to see your budget and goals.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Grab these before awaiting: once the session ends, AuthGate swaps
    // this whole screen out, so `context` may no longer be usable.
    final budget = context.read<BudgetProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoggingOut = true);

    try {
      await SupabaseService.client.auth.signOut();

      // Clear the previous user's data so the next person who logs in
      // on this device never briefly sees it.
      budget.reset();

      // AuthGate listens for the sign-out and shows the Welcome screen
      // by itself. This just clears any screens pushed on top.
      navigator.popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) setState(() => _isLoggingOut = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not log out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final user = SupabaseService.client.auth.currentUser;
    final name = _name();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final memberSince = _memberSince();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // HEADER (matches the Home screen's green header)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (user?.email != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      user!.email!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFFFF5961),
                          value: '${budget.expenses.length}',
                          label: 'Expenses',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.flag_rounded,
                          color: const Color(0xFF4285F4),
                          value: '${budget.goals.length}',
                          label: 'Goals',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.savings_rounded,
                          color: const Color(0xFFFFAB00),
                          value: _peso(budget.totalSaved),
                          label: 'Saved',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'Email',
                          value: user?.email ?? 'Not available',
                        ),
                        const Divider(height: 1, color: AppTheme.border),
                        _InfoRow(
                          icon: _signInIcon(),
                          label: 'Signed in with',
                          value: _signInMethod(),
                        ),
                        if (memberSince != null) ...[
                          const Divider(height: 1, color: AppTheme.border),
                          _InfoRow(
                            icon: Icons.calendar_month_rounded,
                            label: 'Member since',
                            value: memberSince,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoggingOut ? null : _confirmLogout,
                      icon: _isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.danger,
                              ),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        backgroundColor:
                            AppTheme.danger.withValues(alpha: 0.06),
                        side: BorderSide(
                          color: AppTheme.danger.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Center(
                    child: Text(
                      'WalletWatch  •  Small steps. Bigger goals.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}