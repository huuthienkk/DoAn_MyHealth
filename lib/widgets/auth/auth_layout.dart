// auth_layout.dart
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;
  final double headerHeight;

  const AuthLayout({super.key, required this.child, this.headerHeight = 220});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Green curved header
          Container(
            height: headerHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF7BA46E), // xanh lá pastel
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(120),
                bottomRight: Radius.circular(120),
              ),
            ),
          ),

          // Body
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                headerHeight - 40, // đẩy nội dung xuống dưới header
                24,
                32,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
