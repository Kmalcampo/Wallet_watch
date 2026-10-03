import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -75,
              left: -80,
              child: _LeafDecoration(
                width: 230,
                height: 230,
              ),
            ),

            Positioned(
              bottom: -90,
              right: -70,
              child: _LeafDecoration(
                width: 230,
                height: 230,
              ),
            ),

            ListView(
              padding: const EdgeInsets.fromLTRB(
                28,
                48,
                28,
                24,
              ),
              children: [
                const SizedBox(height: 12),

                const Center(
                  child: _WalletLogo(),
                ),

                const SizedBox(height: 8),

                const Text(
                  'WalletWatch',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryDark,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Small steps. Bigger goals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 34),

                const _FeatureItem(
                  icon: Icons.savings_outlined,
                  title: 'Track your allowance.',
                  subtitle: 'Know where your money goes.',
                ),

                const _FeatureItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Build better habits.',
                  subtitle: 'Spend wisely, achieve more.',
                ),

                const _FeatureItem(
                  icon: Icons.track_changes_rounded,
                  title: 'Reach your goals.',
                  subtitle: 'Today’s choices shape tomorrow.',
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(
                            initialIsSignUp: true,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Get Started',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeafDecoration extends StatelessWidget {
  final double width;
  final double height;

  const _LeafDecoration({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F4EC),
        borderRadius: BorderRadius.circular(
          width / 2,
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F2EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryDark,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
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

class _WalletLogo extends StatelessWidget {
  const _WalletLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            left: 20,
            child: Transform.rotate(
              angle: -0.5,
              child: const Icon(
                Icons.remove,
                color: AppTheme.primaryDark,
                size: 30,
              ),
            ),
          ),

          Positioned(
            top: 5,
            right: 20,
            child: Transform.rotate(
              angle: 0.5,
              child: const Icon(
                Icons.remove,
                color: AppTheme.primaryDark,
                size: 30,
              ),
            ),
          ),

          Positioned(
            top: 25,
            child: Container(
              width: 76,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF76B894),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryDark,
                  width: 3,
                ),
              ),
            ),
          ),

          Positioned(
            top: 39,
            right: 14,
            child: Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppTheme.primaryDark,
                  width: 3,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
          ),

          Positioned(
            top: 8,
            child: Icon(
              Icons.cloud_outlined,
              color: AppTheme.primaryDark,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}