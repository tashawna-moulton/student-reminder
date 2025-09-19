import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SummaryRow extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const SummaryRow({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    // ✅ Count statuses
    final present = docs.where((d) => d['status'] == 'present').length;
    final late = docs.where((d) => d['status'] == 'late').length;
    final absent = docs.where((d) => d['status'] == 'absent').length;

    Widget summaryCard({
      required String label,
      required int count,
      required Color borderColor,
      required IconData icon,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: borderColor, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        summaryCard(
          label: "Present",
          count: present,
          borderColor: Colors.greenAccent,
          icon: Icons.check_circle,
        ),
        summaryCard(
          label: "Late",
          count: late,
          borderColor: Colors.orangeAccent,
          icon: Icons.access_time,
        ),
        summaryCard(
          label: "Absent",
          count: absent,
          borderColor: Colors.redAccent,
          icon: Icons.cancel,
        ),
      ],
    );
  }
}
