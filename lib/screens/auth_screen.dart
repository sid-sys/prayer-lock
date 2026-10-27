import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

/// Sign up. One tap with Apple or Google comes first. Email is second.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _signup = true;
  bool _showEmail = false;
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fn();
    } catch (e) {
      final msg = AuthService.friendly(e);
      if (mounted && msg.isNotEmpty) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Widget _social({
    required Widget icon,
    required String label,
    required VoidCallback? onTap,
    bool dark = false,
  }) => FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: dark ? Colors.black : Colors.white,
      foregroundColor: dark ? Colors.white : Colors.black,
      minimumSize: const Size.fromHeight(56),
    ),
    onPressed: onTap,
    icon: icon,
    label: Text(label),
  );

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFCF3E3),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        // Logo, name and line from the brand sheet.
                        Image.asset(
                          'assets/img/login_top.png',
                          height: 170,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 14),
                        // Apple and Google are hidden once the person chooses email.
                        if (!_showEmail) ...[
                          if (AuthService.appleAvailable) ...[
                            _social(
                              dark: true,
                              icon: const Icon(Icons.apple, size: 26),
                              label: 'Continue with Apple',
                              onTap: _busy
                                  ? null
                                  : () => _run(AuthService.signInApple),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (AuthService.googleAvailable)
                            _social(
                              icon: const Icon(Icons.g_mobiledata, size: 34),
                              label: 'Continue with Google',
                              onTap: _busy
                                  ? null
                                  : () => _run(AuthService.signInGoogle),
                            ),
                          const SizedBox(height: 16),
                        ],
                        if (!_showEmail)
                          TextButton(
                            onPressed: () => setState(() => _showEmail = true),
                            child: Text(
                              'Use email instead',
                              style: h(
                                15,
                                color: AppColors.ink,
                                w: FontWeight.w700,
                              ),
                            ),
                          )
                        else ...[
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pass,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _run(
                                    () => _signup
                                        ? AuthService.signUpEmail(
                                            _email.text,
                                            _pass.text,
                                          )
                                        : AuthService.signInEmail(
                                            _email.text,
                                            _pass.text,
                                          ),
                                  ),
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_signup ? 'Create account' : 'Sign in'),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _showEmail = false;
                              _error = null;
                            }),
                            child: Text(
                              'Back to Apple and Google',
                              style: h(
                                14,
                                color: AppColors.soft,
                                w: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _signup = !_signup),
                            child: Text(
                              _signup
                                  ? 'I already have an account'
                                  : 'New here? Create account',
                            ),
                          ),
                          if (!_signup)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                      await AuthService.resetPassword(
                                        _email.text,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Reset email sent. Check your inbox.',
                                                ),
                                              ),
                                            );
                                      }
                                    }),
                              child: const Text('Forgot password?'),
                            ),
                        ],
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The girl with the Bible and the clouds, from the brand sheet.
            if (!keyboard && !_showEmail)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.27,
                width: double.infinity,
                child: Image.asset(
                  'assets/img/login_bottom.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
