import 'package:flutter/material.dart';

class SocialRow extends StatelessWidget {
  const SocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circle("assets/images/facebook.png"),
        const SizedBox(width: 16),
        _circle("assets/images/google.png"),
        const SizedBox(width: 16),
        _circle("assets/images/instagram.png"),
      ],
    );
  }

  Widget _circle(String path) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: Image.asset(path, width: 26, height: 26),
      ),
    );
  }
}
