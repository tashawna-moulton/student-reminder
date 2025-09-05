import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/attendance_repository.dart';
import '../../services/location_service.dart';

// ✅ Reusable UI widgets
import '../../widgets/clock_fab.dart';
import '../../widgets/status_strip.dart';
import '../../widgets/map_card.dart';
import '../../widgets/late_reason_dialog.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _repo = AttendanceRepository();
  final _loc = LocationService();

  bool _isClockedIn = false;
  String? _todayStatus; // 'early' | 'late' | 'present' | 'absent'
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _listenToday();
  }

  void _listenToday() {
    _sub = _repo.todayDocRef().snapshots().listen((snap) {
      final exists = snap.exists;
      if (!exists) {
        setState(() {
          _isClockedIn = false;
          _todayStatus = null;
        });
        return;
      }
      final data = snap.data()!;
      setState(() {
        _todayStatus = data['status'] as String?;
        _isClockedIn = data['clockInAt'] != null && data['clockOutAt'] == null;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // --- Time decision helpers (local device time) ---
  bool _withinClassWindow(DateTime now) {
    final start = DateTime(now.year, now.month, now.day, 8, 0);
    final end   = DateTime(now.year, now.month, now.day, 16, 0);
    return now.isAfter(start) && now.isBefore(end);
  }

  bool _isLate(DateTime now) {
    final lateFrom = DateTime(now.year, now.month, now.day, 8, 30);
    return now.isAfter(lateFrom);
  }

  Future<void> _handleClockIn() async {
  final now = DateTime.now();

  // 1) Time window check (no await yet, so safe to use context)
  if (!_withinClassWindow(now)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clock in only allowed between 8:00–16:00')),
    );
    return;
  }

  // 2) Ask for location permission
  final hasPerm = await _loc.ensurePermission();
  if (!mounted) return; // guard after await

  if (!hasPerm) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location permission required')),
    );
    return;
  }

  // 3) Get current position
  final pos = await _loc.getCurrentPosition();
  if (!mounted) return;

  // 4) Decide status BEFORE any snackbar uses it
  String status = _isLate(now) ? 'late' : 'early';
  String? lateReason;

  // 5) If late, collect a non-empty reason
  if (status == 'late') {
    lateReason = await showLateReasonDialog(context);
    if (!mounted) return;
    if (lateReason == null || lateReason.trim().isEmpty) {
      // User cancelled or empty → don't write
      return;
    }
  }

  // 6) Write to Firestore
  await _repo.clockIn(
    lat: pos.latitude,
    lng: pos.longitude,
    status: status,
    lateReason: lateReason,
  );

  // 7) Confirm to the user
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Clocked in (${status.toUpperCase()})')),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Clean status header
          StatusStrip(status: _todayStatus),

          const SizedBox(height: 8),

          // ✅ Map placeholder card (swap with GoogleMap later)
          const Expanded(child: MapCard()),

          const SizedBox(height: 8),
        ],
      ),
      floatingActionButton: ClockFab(
        isClockedIn: _isClockedIn,
        onClockIn: _handleClockIn,
        onClockOut: null, // Milestone 3
      ),
    );
  }
}