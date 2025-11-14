import 'package:flutter/material.dart';
import '../widgets/auth/auth_layout.dart';
import '../widgets/auth/auth_header.dart';
import '../widgets/auth/app_text_field.dart';
import '../widgets/auth/app_button.dart';
import '../controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final AuthController _authController = AuthController();
  bool _loading = false;

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : const Color(0xFF2575FC),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authController.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      _showSnack('Email đặt lại mật khẩu đã được gửi!');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "Lỗi gửi email", error: true);
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        children: [
          const AuthHeader(
            title: "Quên mật khẩu?",
            subtitle: "Nhập email để nhận hướng dẫn đặt lại mật khẩu",
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: AppTextField(
              controller: _emailCtrl,
              label: "Email",
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) =>
                  v == null || !v.contains('@') ? "Email không hợp lệ" : null,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: "Gửi yêu cầu",
            onPressed: _handleReset,
            loading: _loading,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Quay về đăng nhập",
              style: TextStyle(
                color: Color(0xFF2575FC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }
}
