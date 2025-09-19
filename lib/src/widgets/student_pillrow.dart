import 'package:flutter/material.dart';

class StudentRow extends StatelessWidget {
  final String name;
  final String status;
  final String? photoUrl;
  final String? reason;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final VoidCallback onEditReason;

  const StudentRow({
    super.key,
    required this.name,
    required this.status,
    this.photoUrl,
    this.reason,
    required this.onPresent,
    required this.onAbsent,
    required this.onEditReason,
  });

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.greenAccent;
      case 'late':
        return Colors.orangeAccent;
      case 'absent':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _statusColor();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Avatar + Name + Status
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),

              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: borderColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Reason (only if late/absent)
          if (status.toLowerCase() == 'late' ||
              status.toLowerCase() == 'absent') ...[
            Text(
              reason == null || reason!.isEmpty
                  ? "No reason provided"
                  : "Reason: $reason",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                label: "Present",
                color: Colors.greenAccent,
                icon: Icons.check_circle,
                onTap: onPresent,
              ),
              _actionButton(
                label: "Absent",
                color: Colors.redAccent,
                icon: Icons.cancel,
                onTap: onAbsent,
              ),
              _actionButton(
                label: "Late",
                color: Colors.orangeAccent,
                icon: Icons.timer,
                onTap: onEditReason,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
