// lib/src/services/attendance_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:students_reminder/src/services/auth_service.dart';

class AttendanceDay {
  AttendanceDay({
    required this.id,
    this.dateId,
    this.status,
    this.clockInAt,
    this.clockOutAt,
    this.clockInLat,
    this.clockInLng,
    this.clockOutLat,
    this.clockOutLng,
    this.lateReason,
  });

  final String id;
  final String? dateId;
  final String? status;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final double? clockInLat;
  final double? clockInLng;
  final double? clockOutLat;
  final double? clockOutLng;
  final String? lateReason;

  factory AttendanceDay.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final clockIn = data['clockInAt'];
    final clockOut = data['clockOutAt'];
    final clockInLoc = data['clockInLoc'] as Map<String, dynamic>?;
    final clockOutLoc = data['clockOutLoc'] as Map<String, dynamic>?;

    return AttendanceDay(
      id: doc.id,
      dateId: data['date'] as String?,
      status: data['status'] as String?,
      clockInAt: clockIn is Timestamp ? clockIn.toDate() : null,
      clockOutAt: clockOut is Timestamp ? clockOut.toDate() : null,
      clockInLat: (clockInLoc?['latitude'] as num?)?.toDouble(),
      clockInLng: (clockInLoc?['longitude'] as num?)?.toDouble(),
      clockOutLat: (clockOutLoc?['latitude'] as num?)?.toDouble(),
      clockOutLng: (clockOutLoc?['longitude'] as num?)?.toDouble(),
      lateReason: data['lateReason'] as String?,
    );
  }
}

class AttendanceRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// TODO(rayacademy): migrate legacy docs from `attendance/{uid}/days` into the
  /// new `users/{uid}/attendance` subtree before deleting the old data.

  /// e.g., 2025-09-04  ->  "20250904" or "2025-09-04" (choose one format; here use YYYY-MM-DD)
  String todayId([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(n);
  }

  /// users/{uid}/attendance/{YYYY-MM-DD}
  DocumentReference<Map<String, dynamic>> todayDocRef([DateTime? now]) {
    final id = todayId(now);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .doc(id);
  }

  Stream<AttendanceDay?> watchToday([DateTime? now]) {
    return todayDocRef(now).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AttendanceDay.fromDoc(doc);
    });
  }

  Stream<List<AttendanceDay>> watchRecentDays({int limit = 7}) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceDay.fromDoc).toList());
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
      "userId" : AuthService.instance.currentUser!.uid,
    }, SetOptions(merge: true));
  }

  Future<void> clockOut({
    required double lat,
    required double lng,
  }) async {
    final ref = todayDocRef();
    await ref.set({
      'date': todayId(),
      'clockOutAt': FieldValue.serverTimestamp(),
      'clockOutLoc': {'latitude': lat, 'longitude': lng},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
