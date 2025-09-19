import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// widgets
import 'package:students_reminder/src/widgets/profile_card.dart';
import 'package:students_reminder/src/widgets/analytics_chart.dart';
import 'package:students_reminder/src/widgets/actions_row.dart';
import 'package:students_reminder/src/widgets/timeline_item.dart';
import 'package:students_reminder/src/widgets/analytics_counters.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  // ────────────────────────── helpers ──────────────────────────
  String _fmtTime(dynamic ts) {
    if (ts == null) return "—";
    try {
      final date = (ts as Timestamp).toDate();
      return DateFormat("hh:mm a").format(date);
    } catch (_) {
      return "—";
    }
  }

  String _fmtDate(dynamic ts) {
    if (ts == null) return "—";
    try {
      final date = (ts as Timestamp).toDate();
      return DateFormat("EEE, MMM d").format(date);
    } catch (_) {
      return "—";
    }
  }

  String _fmtDateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Color _statusColor(String status) {
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

  // ────────────────────────── firestore refs ──────────────────────────
  DocumentReference<Map<String, dynamic>> get _userRef =>
      FirebaseFirestore.instance.collection('users').doc(widget.userId);

  CollectionReference<Map<String, dynamic>> get _attendanceCol =>
      _userRef.collection('attendance');

  Future<void> _markStatus(String status) async {
    final ref = _attendanceCol.doc(_fmtDateKey(DateTime.now()));
    await ref.set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked $status')),
    );
  }

  Future<void> _editLateReason() async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Late reason', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type reason',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res == null) return;

    await _attendanceCol.doc(_fmtDateKey(DateTime.now())).set({
      'status': 'late',
      'lateReason': res.isEmpty ? null : res,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ────────────────────────── analytics helpers ──────────────────────────
  Map<String, int> _tally(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    int p = 0, a = 0, l = 0;
    for (final d in docs) {
      final s = (d['status'] ?? '').toString().toLowerCase();
      if (s == 'present') p++;
      else if (s == 'absent') a++;
      else if (s == 'late') l++;
    }
    return {'present': p, 'late': l, 'absent': a};
  }

  List<Map<String, dynamic>> _last7docs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final mapById = {for (final d in docs) d.id: d};
    final now = DateTime.now();
    final list = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = _fmtDateKey(day);
      final doc = mapById[key];
      final status = (doc != null ? (doc.data()?['status'] ?? '') : '')
          .toString()
          .toLowerCase();
      list.add({'day': day, 'status': status});
    }
    return list;
  }

  // ────────────────────────── UI ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Student Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userRef.snapshots(),
        builder: (context, userSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _attendanceCol.orderBy('clockInAt', descending: true).snapshots(),
            builder: (context, attnSnap) {
              if (userSnap.connectionState == ConnectionState.waiting ||
                  attnSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                );
              }

              final userData = userSnap.data?.data() ?? {};
              final name =
                  "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim().isEmpty
                      ? "Student"
                      : "${userData['firstName']} ${userData['lastName']}";
              final photoUrl = userData['photoUrl'];
              final classLabel = (userData['class'] ?? userData['track'] ?? '—').toString();

              final attnDocs = attnSnap.data?.docs ?? [];
              final counts = _tally(attnDocs);
              final last7 = _last7docs(attnDocs);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ProfileCard(
                    name: name,
                    classLabel: classLabel,
                    photoUrl: photoUrl,
                  ),
                  const SizedBox(height: 16),
                  AnalyticsCountersRow(
                    present: counts['present'] ?? 0,
                    late: counts['late'] ?? 0,
                    absent: counts['absent'] ?? 0,
                  ),
                  const SizedBox(height: 16),
                  AnalyticsCharts(
                    series: last7.map((e) => e['status'] == 'present' ? 1 : 0).toList(),
                    counts: counts,
                  ),
                  const SizedBox(height: 16),
                  ActionsRow(
                    onPresent: () => _markStatus('present'),
                    onAbsent: () => _markStatus('absent'),
                    onLate: _editLateReason,
                  ),
                  const SizedBox(height: 16),
                  ...attnDocs.map((d) {
                    final data = d.data();
                    final status = (data['status'] ?? 'unknown').toString();
                    final reason = (data['lateReason'] ?? '').toString().trim();
                    final loc = (data['location'] as Map<String, dynamic>?);
                    final lat = loc?['lat']?.toDouble();
                    final lng = loc?['lng']?.toDouble();

                    return TimelineItem(
                      prettyDate: _fmtDate(data['clockInAt']),
                      status: status,
                      inTime: _fmtTime(data['clockInAt']),
                      outTime: _fmtTime(data['clockOutAt']),
                      reason: reason.isEmpty ? null : reason,
                      mapLatLng: (lat != null && lng != null)
                          ? LatLng(lat, lng)
                          : null,
                      pillColor: _statusColor(status),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}