import 'package:flutter/material.dart';

class StatusStrip extends StatelessWidget {
  final String? status;
  const StatusStrip({super.key, this.status});

  String _statusEmoji(String? s) {
    switch (s) {
      case 'early':
        return '✅';
      case 'late':
        return '⏰';
      case 'absent':
        return '🚫';
      default:
        return '⚪';
    }
  }

  String _statusMessage(String? s) {
    switch (s) {
      case 'early':
        return 'You’re on time!';
      case 'late':
        return 'Running late today.';
      case 'absent':
        return 'Absent today.';
      default:
        return 'Not clocked in yet.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _statusEmoji(status);
    final message = _statusMessage(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 42)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
