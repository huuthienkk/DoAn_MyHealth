import 'package:flutter/material.dart';
import '../widgets/auth/auth_layout.dart';
import '../widgets/auth/auth_header.dart';
import '../widgets/auth/app_text_field.dart';
import '../widgets/auth/app_button.dart';
import '../widgets/auth/auth_footer.dart';
import '../models/register_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final RegisterViewModel _viewModel = RegisterViewModel();
  bool _obscure = true;
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _viewModel.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (!mounted) return;
      _showSnack('Đăng ký thành công!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Lỗi đăng ký', error: true);
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
            title: "Tạo tài khoản mới",
            subtitle: "Đăng ký để bắt đầu theo dõi sức khỏe của bạn",
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                    controller: _nameCtrl,
                    label: "Họ và tên",
                    prefixIcon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Vui lòng nhập họ tên" : null),
                const SizedBox(height: 16),
                AppTextField(
                    controller: _emailCtrl,
                    label: "Email",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? "Email không hợp lệ"
                        : null),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passCtrl,
                  label: "Mật khẩu",
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? "Mật khẩu ít nhất 6 ký tự"
                      : null,
                ),
                const SizedBox(height: 24),
                AppButton(
                    text: "Đăng ký",
                    onPressed: _handleRegister,
                    loading: _loading),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AuthFooter(
            text: "Đã có tài khoản?",
            actionText: "Đăng nhập ngay",
            action: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
