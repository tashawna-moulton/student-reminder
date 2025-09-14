import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _repo = AttendanceRepository();
  final _loc = LocationService();

  String _status = 'Checking attendance status...';
  bool _isClockedIn = false;
  String? _todayStatus; // 'early' | 'late' | 'present' | 'absent'

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _checkAndAutoClockOut();
    _listenToday();
    _initializeLocation();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ---------------- Attendance logic ----------------

  // Auto Clock-Out after 4:00 PM if still clocked in
  Future<void> _checkAndAutoClockOut() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _status = 'Not signed in.');
        return;
      }

      final now = DateTime.now();
      final todayId = DateFormat('yyyy-MM-dd').format(now);

      // Only attempt auto clock-out after 4 PM local time
      if (now.hour < 16) {
        await _updateStatus();
        return;
      }

      final docRef =
          _firestore.collection('attendance').doc(user.uid).collection('days').doc(todayId);
      final doc = await docRef.get();

      final data = doc.data();
      final clockInAt = data?['clockInAt'];
      final clockOutAt = data?['clockOutAt'];

      if (doc.exists && clockInAt != null && clockOutAt == null) {
        // Ensure location permission before getting position
        final hasPerm = await _loc.ensurePermission();
        if (!hasPerm) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required to auto clock-out.')),
          );
          return;
        }

        final position = await Geolocator.getCurrentPosition();

        await docRef.update({
          'clockOutAt': FieldValue.serverTimestamp(),
          'clockOutLoc': GeoPoint(position.latitude, position.longitude),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Automatically clocked out.')),
        );
        setState(() {
          _status = 'Automatically clocked out.';
          _isClockedIn = false;
        });
      } else {
        await _updateStatus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error determining auto clock-out.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto clock-out error: $e')),
      );
    }
  }

  Future<void> _handleClockOut() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not signed in.')),
        );
        return;
      }

      final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final hasPerm = await _loc.ensurePermission();
      if (!mounted) return;
      if (!hasPerm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
        return;
      }

      final pos = await _loc.getCurrentPosition();
      if (!mounted) return;

      await _firestore
          .collection('attendance')
          .doc(user.uid)
          .collection('days')
          .doc(todayId)
          .update({
        'clockOutAt': FieldValue.serverTimestamp(),
        'clockOutLoc': GeoPoint(pos.latitude, pos.longitude),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _status = 'Clocked out successfully.';
        _isClockedIn = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clocked out successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clocking out: $e')),
      );
    }
  }

  Future<void> _updateStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _status = 'Not signed in.');
      return;
    }

    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final doc =
        await _firestore.collection('attendance').doc(user.uid).collection('days').doc(todayId).get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data();
      final inAt = data?['clockInAt'];
      final outAt = data?['clockOutAt'];

      if (inAt != null && outAt == null) {
        setState(() {
          _status = 'You are currently clocked in.';
          _isClockedIn = true;
        });
      } else if (outAt != null) {
        setState(() {
          _status = 'You have already clocked out today.';
          _isClockedIn = false;
        });
      } else {
        setState(() {
          _status = 'You are not clocked in today.';
          _isClockedIn = false;
        });
      }
    } else {
      setState(() {
        _status = 'No clock-in record found for today.';
        _isClockedIn = false;
      });
    }
  }

  void _listenToday() {
    _sub = _repo.todayDocRef().snapshots().listen((snap) {
      if (!mounted) return;

      if (!snap.exists) {
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

  // --- Time decision helpers (local device time) ---
  bool _withinClassWindow(DateTime now) {
    final start = DateTime(now.year, now.month, now.day, 8, 0);
    final end = DateTime(now.year, now.month, now.day, 16, 0);
    // inclusive at start, exclusive at end (8:00 <= now < 16:00)
    return (now.isAfter(start) || now.isAtSameMomentAs(start)) && now.isBefore(end);
  }

  bool _isLate(DateTime now) {
    final lateFrom = DateTime(now.year, now.month, now.day, 8, 30);
    return now.isAfter(lateFrom);
  }

  Future<void> _handleClockIn() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in.')),
      );
      return;
    }

    final now = DateTime.now();

    // 1) Time window check
    if (!_withinClassWindow(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clock in only allowed between 8:00–16:00')),
      );
      return;
    }

    // 2) Ask for location permission
    final hasPerm = await _loc.ensurePermission();
    if (!mounted) return;

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

    // 6) Write to Firestore (via repository)
    await _repo.clockIn(
      lat: pos.latitude,
      lng: pos.longitude,
      status: status,
      lateReason: lateReason,
    );

    // 7) Confirm to the user
    if (!mounted) return;
    setState(() => _isClockedIn = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Clocked in (${status.toUpperCase()})')),
    );
  }

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(18.0179, -76.8099), // Jamaica coordinates as fallback
    zoom: 15.0,
  );

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check and request location permissions
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Location permission is required for attendance tracking';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await _getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _markers = {
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(
                title: 'My Location',
                snippet: 'Current position',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          };
        });

        // Move camera to current location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Location services are disabled. Please enable location services.';
      });
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Location permission denied';
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Location permissions are permanently denied. Please enable them in settings.';
      });
      return false;
    }

    return true;
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  Future<void> _onMyLocationPressed() async {
    if (_currentPosition != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 17.0,
          ),
        ),
      );
    } else {
      // Refresh location
      await _initializeLocation();
    }
  }

    GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  Set<Marker> _markers = {};

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          StatusStrip(status: _todayStatus),

          const SizedBox(height: 8),

          // Map / location card
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading map...'),
                      ],
                    ),
                  )
                : GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: _currentPosition != null
                        ? CameraPosition(
                            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            zoom: 15.0,
                          )
                        : _defaultPosition,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false, // We'll use our custom button
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                    buildingsEnabled: true,
                    trafficEnabled: false,
                  ),
          ),

          const SizedBox(height: 8),

          // Current text status + manual clock-out button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isClockedIn ? _handleClockOut : null,
                  child: const Text('Clock Out'),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: ClockFab(
        isClockedIn: _isClockedIn,
        onClockIn: _handleClockIn,
        onClockOut: _handleClockOut, // enable if your FAB supports it
      ),
    );
  }
  Widget _buildLocationStatus() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text('Location Error', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(_errorMessage!),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _initializeLocation,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_currentPosition != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text('Location Found', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
              'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
