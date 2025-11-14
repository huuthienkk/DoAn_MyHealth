import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),

        // ICON
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Color(0xFF7BA46E)) // pastel green
            : null,
        suffixIcon: suffixIcon,

        filled: true,
        fillColor: Colors.white,

        // ---- NORMAL BORDER (không focus) ----
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(
            color: Color(0xFFDDDDDD), // xám nhạt, giống trong UI mẫu
            width: 1.2,
          ),
        ),

        // ---- FOCUS BORDER (click vào mới xanh) ----
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(
            color: Color(0xFF7BA46E), // xanh đậm hơn
            width: 2,
          ),
        ),

        // padding
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
