import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserDetailPage extends StatelessWidget {
  final String userId;

  const UserDetailPage({Key? key, required this.userId}) : super(key: key);

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return "—";
    try {
      final dt = (ts as Timestamp).toDate();
      return DateFormat("hh:mm a").format(dt);
    } catch (_) {
      return ts.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "present":
        return Colors.green;
      case "late":
        return Colors.orange;
      case "absent":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Attendance — $userId',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .doc(userId)
            .collection('days')
            .orderBy(FieldPath.documentId, descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs;
          if (docs == null || docs.isEmpty) {
            return const Center(
              child: Text(
                'No attendance records found.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final dayId = doc.id;
              final data = doc.data() as Map<String, dynamic>;

              final status = (data['status'] ?? 'unknown').toString();

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Date + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 20, color: Colors.deepPurple),
                              const SizedBox(width: 8),
                              Text(
                                dayId,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Clock In/Out
                      Row(
                        children: [
                          const Icon(Icons.login, color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Text("In: ${_formatTimestamp(data['clockInAt'])}"),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.logout,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 6),
                          Text("Out: ${_formatTimestamp(data['clockOutAt'])}"),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Late Reason (if exists)
                      if (data['lateReason'] != null &&
                          data['lateReason'].toString().isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Reason: ${data['lateReason']}",
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
