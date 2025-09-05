// lib/src/models/attendance_day.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceDay {
  final String date;              // "YYYY-MM-DD"
  final String status;            // 'early' | 'late' | 'present' | 'absent'
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final double? clockInLat;
  final double? clockInLng;
  final double? clockOutLat;
  final double? clockOutLng;
  final String? lateReason;

  AttendanceDay({
    required this.date,
    required this.status,
    this.clockInAt,
    this.clockOutAt,
    this.clockInLat,
    this.clockInLng,
    this.clockOutLat,
    this.clockOutLng,
    this.lateReason,
  });

  /// Convert Firestore Timestamp/DateTime to DateTime?
  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  factory AttendanceDay.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    return AttendanceDay(
      date: (d['date'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'absent',
      clockInAt: _toDateTime(d['clockInAt']),
      clockOutAt: _toDateTime(d['clockOutAt']),
      clockInLat: (d['clockInLoc']?['latitude'] as num?)?.toDouble(),
      clockInLng: (d['clockInLoc']?['longitude'] as num?)?.toDouble(),
      clockOutLat: (d['clockOutLoc']?['latitude'] as num?)?.toDouble(),
      clockOutLng: (d['clockOutLoc']?['longitude'] as num?)?.toDouble(),
      lateReason: d['lateReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? _loc(double? lat, double? lng) {
      if (lat == null || lng == null) return null;
      return {'latitude': lat, 'longitude': lng};
    }

    return {
      'date': date,
      'status': status,
      'clockInAt': clockInAt,
      'clockOutAt': clockOutAt,
      'clockInLoc': _loc(clockInLat, clockInLng),
      'clockOutLoc': _loc(clockOutLat, clockOutLng),
      'lateReason': lateReason,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}