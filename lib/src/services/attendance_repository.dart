// lib/src/services/attendance_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// e.g., 2025-09-04  ->  "20250904" or "2025-09-04" (choose one format; here use YYYY-MM-DD)
  String todayId([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(n);
  }

  /// attendance/{uid}/days/{YYYY-MM-DD}
  DocumentReference<Map<String, dynamic>> todayDocRef([DateTime? now]) {
    final id = todayId(now);
    return _db
        .collection('attendance')
        .doc(_uid)
        .collection('days')
        .doc(id);
  }

  Future<void> clockIn({
    required double lat,
    required double lng,
    required String status, // 'early' | 'late'
    String? lateReason,
  }) async {
    final ref = todayDocRef();
    await ref.set({
      'date': todayId(),
      'status': status,
      'clockInAt': FieldValue.serverTimestamp(),
      'clockInLoc': {'latitude': lat, 'longitude': lng},
      if (lateReason != null) 'lateReason': lateReason,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}