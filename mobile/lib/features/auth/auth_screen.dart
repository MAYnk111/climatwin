import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await AuthService.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${AuthService.instance.currentUser?.email}!'),
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onAuthSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.mapAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter your registered email address to reset password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Password Reset Email Sent'),
            content: Text('A password reset link has been dispatched to $email. Please check your inbox.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.mapAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInAnonymously();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in as Guest Analyst'),
            duration: Duration(seconds: 2),
          ),
        );
        widget.onAuthSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.mapAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create CLIMATWIN Account' : 'Sign In to CLIMATWIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ClimatwinTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ClimatwinTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ClimatwinTheme.darkGreenPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.shield_outlined, color: ClimatwinTheme.darkGreenPrimary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Firebase Cloud Authentication',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ClimatwinTheme.textPrimary),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Secures your custom portfolios, watchlists, alert rules, and stress test scenarios.',
                          style: TextStyle(fontSize: 11, color: ClimatwinTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tab Selector: Sign In vs Sign Up
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Sign In')),
                ButtonSegment(value: true, label: Text('Register')),
              ],
              selected: {_isSignUp},
              onSelectionChanged: (val) {
                setState(() {
                  _isSignUp = val.first;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 20),

            // Email Input
            const Text('Work / Analyst Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'analyst@fund.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20, color: ClimatwinTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Password Input
            const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClimatwinTheme.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline, size: 20, color: ClimatwinTheme.textSecondary),
              ),
            ),
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  child: const Text('Forgot Password?', style: TextStyle(fontSize: 11, color: ClimatwinTheme.darkGreenPrimary)),
                ),
              )
            else
              const SizedBox(height: 12),

            // Error notice
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: ClimatwinTheme.riskHigh.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClimatwinTheme.riskHigh.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: ClimatwinTheme.riskHigh),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 11, color: ClimatwinTheme.riskHigh),
                      ),
                    ),
                  ],
                ),
              ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClimatwinTheme.darkGreenPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _handleAuth,
                child: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _isSignUp ? 'Create Account' : 'Sign In',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Guest Login Option
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.person_outline, size: 18, color: ClimatwinTheme.textSecondary),
                label: const Text(
                  'Continue as Guest Analyst',
                  style: TextStyle(fontSize: 13, color: ClimatwinTheme.textSecondary),
                ),
                onPressed: _isLoading ? null : _handleGuestLogin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
