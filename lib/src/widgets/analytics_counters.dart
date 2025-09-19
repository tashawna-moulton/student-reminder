import 'package:flutter/material.dart';

class AnalyticsCountersRow extends StatelessWidget {
  final int present, late, absent;
  const AnalyticsCountersRow({
    super.key,
    required this.present,
    required this.late,
    required this.absent,
  });

  @override
  Widget build(BuildContext context) {
    Widget card(String label, int count, Color border) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: border,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );

    return Row(
      children: [
        card('Present', present, Colors.greenAccent),
        card('Late', late, Colors.orangeAccent),
        card('Absent', absent, Colors.redAccent),
      ],
    );
  }
}
