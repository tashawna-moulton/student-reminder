import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'full_map_screen.dart'; // 👈 full screen map

/// Map loading states
enum MapLoadState { loading, ready, error }

/// Wrapper for map status
class MapStatus {
  const MapStatus._(this.state, {this.position, this.error});

  const MapStatus.loading() : this._(MapLoadState.loading);
  const MapStatus.ready(Position position)
    : this._(MapLoadState.ready, position: position);
  const MapStatus.error(String message)
    : this._(MapLoadState.error, error: message);

  final MapLoadState state;
  final Position? position;
  final String? error;
}

/// MapCard widget: shows a Google Map with user’s current location.
/// Acts like a preview card — tapping it opens the full screen map.
class MapCard extends StatefulWidget {
  const MapCard({super.key, this.onStatusChanged});

  final ValueChanged<MapStatus>? onStatusChanged;

  @override
  State<MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<MapCard> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  Set<Marker> _markers = {};

  /// Default fallback (if no GPS available)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(18.0179, -76.8099), // Kingston, JA
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _emitStatus(const MapStatus.loading());
    _initializeLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialize location + permissions
  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Location permission is required.';
          _isLoading = false;
        });
        _emitStatus(const MapStatus.error('Permission denied'));
        return;
      }

      final position = await _getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;

          // Add marker for current location
          _markers = {
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(
                title: 'My Location',
                snippet: 'Current position',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          };
        });

        _emitStatus(MapStatus.ready(position));

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              15,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Unable to determine location';
        });
        _emitStatus(const MapStatus.error('Unable to determine location'));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
      });
      _emitStatus(MapStatus.error(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _emitStatus(const MapStatus.error('Location services disabled'));
      setState(() {
        _errorMessage = 'Enable location services in settings.';
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Permissions permanently denied.';
      });
      _emitStatus(const MapStatus.error('Permission permanently denied'));
      return false;
    }

    return true;
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  void _emitStatus(MapStatus status) {
    widget.onStatusChanged?.call(status);
  }
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // 👇 Map background
      Positioned.fill(
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: _currentPosition != null
              ? CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 15.0,
                )
              : _defaultPosition,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          liteModeEnabled: true, // preview only
        ),
      ),

      // 👇 Transparent clickable layer on top of map
      Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FullMapScreen()),
              );
            },
          ),
        ),
      ),

      // 👇 Loading indicator
      if (_isLoading)
        const Center(child: CircularProgressIndicator()),

      // 👇 Error overlay
      if (_errorMessage != null && !_isLoading)
        Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
    ],
  );
}
}