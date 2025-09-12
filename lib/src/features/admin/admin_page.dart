import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:students_reminder/src/features/admin/user_detail_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  DateTimeRange? _range;
  bool _isAdmin = false;
  bool _loadedRole = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isAdmin = true;
        _loadedRole = true;
      });
      return;
    }
    //Users => {User ID} => role = Admin (Admin users will see this page)
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final role = snap.data()?['role'] as String?;
    setState(() {
      _isAdmin = role == 'admin';
      _loadedRole = true;
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial =
        _range ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    final col = FirebaseFirestore.instance.collection('attendance');
    if (_range == null) {
      // default to today
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
      return col
          .where('days', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date');
    } else {
      final start = DateTime(
        _range!.start.year,
        _range!.start.month,
        _range!.start.day,
      );
      final end = DateTime(
        _range!.end.year,
        _range!.end.month,
        _range!.end.day,
        23,
        59,
        59,
        999,
      );
      return col
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date');
    }
  }

  Future<void> _markStatus(DocumentReference docRef, String status) async {
    await docRef.update({
      'status': status,
      if (status != 'late') 'lateReason': null,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Marked $status')));
  }

  Future<void> _editLateReason(
    DocumentReference docRef,
    String? current,
  ) async {
    final controller = TextEditingController(text: current ?? '');
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Late Reason'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter reason'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (res == null) return;
    await docRef.update({
      'status': 'late',
      'lateReason': res.isEmpty ? null : res,
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Late reason updated')));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to view this page.'),
        ),
      );
    }

    final q = _buildQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Attendance'),
        actions: [
          IconButton(
            tooltip: 'Pick date range',
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("attendance")
            .snapshots(), // Listen to all attendance documents
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs;
          print("hello $docs");
          if (docs == null || docs.isEmpty) {
            return const Center(child: Text('No attendance records found'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              // Customize UI per user:
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('User ID: ${doc.id}'),
                  subtitle: Text('Days recorded: ${data['days']?.length ?? 0}'),
                  onTap: () {
                    // Navigate to detail view for specific user:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailPage(userId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _yyyyMmDd(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _AdminActions extends StatelessWidget {
  final String status;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final VoidCallback onEditLate;

  const _AdminActions({
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
        ElevatedButton(onPressed: onPresent, child: const Text('Present')),
        OutlinedButton(onPressed: onAbsent, child: const Text('Absent')),
        TextButton.icon(
          onPressed: onEditLate,
          icon: const Icon(Icons.edit),
          label: Text(status == 'late' ? 'Edit Reason' : 'Late Reason'),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  Color _color(BuildContext context) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 8, backgroundColor: _color(context));
  }
}
