import 'package:flutter/material.dart';

class AdminActions extends StatelessWidget {
  final String status;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final VoidCallback onEditLate;

  const AdminActions({
    super.key,
    required this.status,
    required this.onPresent,
    required this.onAbsent,
    required this.onEditLate,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: onPresent,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check_circle),
          label: const Text('Present'),
        ),
        ElevatedButton.icon(
          onPressed: onAbsent,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.cancel),
          label: const Text('Absent'),
        ),
        OutlinedButton.icon(
          onPressed: onEditLate,
          icon: const Icon(Icons.edit, color: Colors.orange),
          label: Text(
            status == 'late' ? 'Edit Reason' : 'Late Reason',
            style: const TextStyle(color: Colors.orange),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange),
          ),
        ),
      ],
    );
  }
}
