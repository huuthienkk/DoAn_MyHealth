// login_screen.dart
import 'package:flutter/material.dart';
import '../widgets/auth/auth_layout.dart';
import '../widgets/auth/auth_header.dart';
import '../widgets/auth/app_text_field.dart';
import '../widgets/auth/app_button.dart';
import '../widgets/auth/auth_footer.dart';
import '../models/login_view_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final LoginViewModel _viewModel = LoginViewModel();
  final AuthService _authService = AuthService();
  bool _obscure = true;
  bool _loading = false;
  bool _biometricAvailable = false;

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _viewModel.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      _showSnack('Đăng nhập thành công!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Lỗi đăng nhập', error: true);
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _authService.isBiometricAvailable();
    setState(() => _biometricAvailable = available);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        _showSnack('Đăng nhập Google thành công!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _loading = true);
    try {
      final authenticated = await _authService.authenticateWithBiometrics(
        reason: 'Xác thực để đăng nhập',
      );
      if (authenticated && mounted) {
        // Nếu đã đăng nhập trước đó, chỉ cần xác thực
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _showSnack('Xác thực thành công!');
          await Future.delayed(const Duration(milliseconds: 800));
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showSnack('Vui lòng đăng nhập bằng email trước', error: true);
        }
      }
    } catch (e) {
      _showSnack('Xác thực thất bại: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(title: "Sign In To My Health"),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _emailCtrl,
                  label: "Email",
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Vui lòng nhập email' : null,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passCtrl,
                  label: "Password",
                  obscureText: _obscure,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: "Sign In",
                  onPressed: _handleLogin,
                  loading: _loading,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // OAuth buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Biometric login
          if (_biometricAvailable)
            OutlinedButton.icon(
              onPressed: _loading ? null : _handleBiometricLogin,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Đăng nhập bằng vân tay/Face ID'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          const SizedBox(height: 16),
          AuthFooter(
            text: "Don't have an account?",
            actionText: "Sign Up",
            action: () => Navigator.pushNamed(context, '/register'),
          ),
          const SizedBox(height: 8),
          AuthFooter(
            text: "Forgot password?",
            actionText: "Reset",
            action: () => Navigator.pushNamed(context, '/forgot'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
