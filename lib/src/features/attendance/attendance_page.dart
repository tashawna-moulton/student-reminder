
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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

  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _status = 'Checking attendance status...';

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

    _checkAndAutoClockOut();
  }

  // Auto Clock-Out Logic
  Future<void> _checkAndAutoClockOut() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final uid = _auth.currentUser!.uid;

    // Check if time is after 4 PM
    if (now.hour >= 16) { 
      final docRef = _firestore.collection('attendance').doc(uid).collection('days').doc(today);
      final doc = await docRef.get();

      // Check if the user is clocked in but not yet clocked out
      if (doc.exists && doc.data()?['clockInAt'] != null && doc.data()?['clockOutAt'] == null) {
        final position = await Geolocator.getCurrentPosition();
        await docRef.update({
          'clockOutAt': FieldValue.serverTimestamp(),
          'clockOutLoc': GeoPoint(position.latitude, position.longitude),
        });
        // Notify the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Automatically clocked out.')),
        );
        setState(() {
          _status = 'Automatically clocked out.';
        });
      }
    }
    // Update status based on current attendance record
    await _updateStatus();
  }

  // Manually Clock Out Logic
  Future<void> _handleClockOut() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final uid = _auth.currentUser!.uid;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Update the Firestore document for today
      await _firestore.collection('attendance').doc(uid).collection('days').doc(today).update({
        'clockOutAt': FieldValue.serverTimestamp(),
        'clockOutLoc': GeoPoint(position.latitude, position.longitude),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _status = 'Clocked out successfully.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clocked out successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clocking out: $e')),
      );
    }
  }

  Future<void> _updateStatus() async {
    final uid = _auth.currentUser!.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final doc = await _firestore.collection('attendance').doc(uid).collection('days').doc(today).get();

    if (doc.exists) {
      final data = doc.data();
      if (data?['clockInAt'] != null && data?['clockOutAt'] == null) {
        setState(() {
          _status = 'You are currently clocked in.';
        });
      } else if (data?['clockOutAt'] != null) {
        setState(() {
          _status = 'You have already clocked out today.';
        });
      } else {
        setState(() {
          _status = 'You are not clocked in today.';
        });
      }
    } else {
      setState(() {
        _status = 'No clock-in record found for today.';
      });
    }
  }

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleClockOut,
              child: const Text('Clock Out'),
            ),
          ],
        ),
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