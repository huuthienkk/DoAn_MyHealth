import 'package:flutter/material.dart';

Future<void> showErrorDialog(
  BuildContext context,
  String message, {
  String title = 'Lỗi',
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
