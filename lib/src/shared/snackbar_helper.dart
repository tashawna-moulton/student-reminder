import 'package:flutter/material.dart';

class SnackbarHelper {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Colors.green[600]!, Icons.check_circle);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Colors.red[700]!, Icons.error);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
