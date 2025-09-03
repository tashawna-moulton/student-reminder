import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _status = 'Checking attendance status...';

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
      ),
    );
  }
}