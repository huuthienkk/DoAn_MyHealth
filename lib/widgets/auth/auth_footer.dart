// auth_footer.dart
import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  final String? text;
  final String? actionText;
  final VoidCallback action;

  const AuthFooter({
    super.key,
    this.text,
    this.actionText,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (text != null)
          Text(
            text!,
            style: const TextStyle(
              color: Color(0xFF6B7280), // Màu xám như fraud.ai
              fontSize: 14,
            ),
          ),
        if (actionText != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: action,
            child: Text(
              actionText!,
              style: const TextStyle(
                color: Colors.black, // Màu đen
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ]
      ],
    );
  }
}
