import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/marketplace_repository.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.repository,
    required this.authService,
  });

  final MarketplaceRepository repository;
  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Nova Collector');
  final _emailController = TextEditingController(text: 'collector@example.com');
  final _passwordController = TextEditingController(text: 'novamarket');
  final _confirmPasswordController = TextEditingController(text: 'novamarket');

  bool _creatingAccount = true;
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (_creatingAccount) {
        await widget.authService.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            repository: widget.repository,
            authService: widget.authService,
          ),
        ),
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to continue. Please check your wallet account.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showWalletMessage(String provider) {
    _showMessage('$provider can be connected through Supabase Auth providers.');
  }

  @override
  Widget build(BuildContext context) {
    final title = _creatingAccount ? 'Create collector profile' : 'Welcome back';
    final subtitle = _creatingAccount
        ? 'Save watchlists, bid history, and portfolio stats with Supabase auth.'
        : 'Continue watching live auctions and curated drops.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LoginHero(),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.8,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFA5ABC0),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121420),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFF24283A)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .24),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.authService.isDemo) ...[
                            const _DemoBanner(),
                            const SizedBox(height: 16),
                          ],
                          if (_creatingAccount) ...[
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Collector name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your collector name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Use at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          if (_creatingAccount) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords must match';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : Text(
                                    _creatingAccount
                                        ? 'Create profile'
                                        : 'Enter marketplace',
                                  ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _WalletButton(
                                  label: 'Wallet',
                                  icon: Icons.account_balance_wallet_outlined,
                                  onTap: () => _showWalletMessage('Wallet'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _WalletButton(
                                  label: 'Google',
                                  icon: Icons.g_mobiledata,
                                  onTap: () => _showWalletMessage('Google'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(
                      () => _creatingAccount = !_creatingAccount,
                    ),
                    child: Text(
                      _creatingAccount
                          ? 'Already collecting? Sign in'
                          : 'New collector? Create a profile',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: .34),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 58),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: .14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: .3)),
      ),
      child: const Text(
        'Demo mode: add Supabase keys to load live users, listings, bids, and watchlists.',
        style: TextStyle(color: Color(0xFFD9D6FF), height: 1.35),
      ),
    );
  }
}

class _WalletButton extends StatelessWidget {
  const _WalletButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF30364D)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
