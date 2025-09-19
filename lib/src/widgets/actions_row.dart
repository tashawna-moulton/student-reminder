import 'package:flutter/material.dart';

class ActionsRow extends StatelessWidget {
  final VoidCallback onPresent, onAbsent, onLate;

  const ActionsRow({
    super.key,
    required this.onPresent,
    required this.onAbsent,
    required this.onLate,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, IconData icon, Color color, VoidCallback onTap) =>
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, color: color, size: 18),
            label: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

    return Row(
      children: [
        btn('Present', Icons.check_circle, Colors.greenAccent, onPresent),
        const SizedBox(width: 8),
        btn('Absent', Icons.cancel, Colors.redAccent, onAbsent),
        const SizedBox(width: 8),
        btn('Late', Icons.timer, Colors.orangeAccent, onLate),
      ],
    );
  }
}
