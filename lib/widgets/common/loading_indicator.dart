import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({this.message, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: const TextStyle(color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}
