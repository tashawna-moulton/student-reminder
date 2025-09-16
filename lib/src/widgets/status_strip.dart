import 'package:flutter/material.dart';

class StatusStrip extends StatelessWidget {
  final String? status;
  const StatusStrip({super.key, this.status});

  Color _statusColor(String? s) {
    switch (s) {
      case 'early':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'present':
        return Colors.blue;
      case 'absent':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = status == null ? 'No status yet' : 'Today: ${status!.toUpperCase()}';
    final color = _statusColor(status);

    // If withValues isn't available in your SDK, keep withOpacity
    final bg = color.withAlpha(8);
    // final bg = color.withValues(alpha: 0.08); // newer SDKs

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}