import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'name_input_screen.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsSignUp;

  const LoginScreen({
    super.key,
    this.initialIsSignUp = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isSignUp = widget.initialIsSignUp;

  bool _isSubmitting = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = SupabaseService.client.auth;

      if (_isSignUp) {
       final response = await auth.signUp(
  email: _emailController.text.trim(),
  password: _passwordController.text,
);

if (!mounted) return;

if (response.user != null && response.session != null) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const NameInputScreen(),
    ),
  );
}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created! Check your email to confirm your account.',
              ),
            ),
          );

          setState(() => _isSignUp = false);
        }
      } else {
    final response = await auth.signInWithPassword(
  email: _emailController.text.trim(),
  password: _passwordController.text,
);

if (!mounted) return;

if (response.session != null) {
  Navigator.of(context).pop();
}
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Feature: SSO via Supabase's Google OAuth provider. On web this
  /// redirects in the same tab and comes back automatically. On
  /// Android/iOS it needs the custom URL scheme registered in the
  /// platform manifest (see the Android setup notes) so the app can
  /// catch the redirect — AuthGate's auth-state listener then takes
  /// over once the session exists, same as email/password login.
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
       redirectTo: kIsWeb
    ? Uri.base.origin
    : 'io.supabase.walletwatch://login-callback/',
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not sign in with Google. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Same flow as Google SSO, just with Facebook as the provider.
  Future<void> _signInWithFacebook() async {
    setState(() {
      _isFacebookLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb
    ? Uri.base.origin
    : 'io.supabase.walletwatch://login-callback/',
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not sign in with Facebook. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDF0E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 58,
                    color: Color(0xFF087F5B),
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075E4D),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isSignUp
                      ? 'Start tracking your money today.'
                      : 'Log in to continue managing your budget.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7C75),
                  ),
                ),

                const SizedBox(height: 28),

                // --- SSO ---
                OutlinedButton(
                  onPressed: (_isSubmitting ||
                          _isGoogleLoading ||
                          _isFacebookLoading)
                      ? null
                      : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDE7E5)),
                  ),
                  child: _isGoogleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _GoogleGlyph(),
                            SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 10),

                OutlinedButton(
                  onPressed: (_isSubmitting ||
                          _isGoogleLoading ||
                          _isFacebookLoading)
                      ? null
                      : _signInWithFacebook,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDE7E5)),
                  ),
                  child: _isFacebookLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _FacebookGlyph(),
                            SizedBox(width: 10),
                            Text(
                              'Continue with Facebook',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  'Email',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Enter your email',
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: 'Enter your password',
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 26),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isSignUp ? 'Create Account' : 'Log In',
                        ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          });
                        },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log in'
                        : "Don't have an account? Sign up",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple "G" glyph so the Google button doesn't need a bundled
/// logo asset. Swap for Google's actual brand mark asset if you add
/// one to your project later.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}

/// A simple "f" glyph so the Facebook button doesn't need a bundled
/// logo asset. Swap for the real brand mark if you add one later.
class _FacebookGlyph extends StatelessWidget {
  const _FacebookGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1877F2),
      ),
      child: const Text(
        'f',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}