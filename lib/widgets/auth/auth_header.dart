import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            color: Color(0xFF5D3A1A), // nâu
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(subtitle!,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
