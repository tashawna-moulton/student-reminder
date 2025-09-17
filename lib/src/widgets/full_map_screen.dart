import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

// TODO: replace with your real Google API key
const String googleApiKey = "YOUR_GOOGLE_API_KEY";

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({super.key});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _showAttendance = true;
  bool _showCafes = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAttendanceMarkers();
  }

  /// 📍 Get user current location
  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() => _currentPosition = pos);

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
      );
    }
  }

  /// 🔹 Load attendance markers from Firestore
  Future<void> _loadAttendanceMarkers() async {
    if (!_showAttendance) return;

    final snap = await FirebaseFirestore.instance
        .collection("attendance")
        .get();
    final markers = snap.docs.map((doc) {
      final data = doc.data();
      final lat = (data["lat"] ?? 18.0179).toDouble();
      final lng = (data["lng"] ?? -76.8099).toDouble();
      final status = data["status"] ?? "unknown";

      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: "Attendance: $status",
          snippet: "User: ${doc.id}",
        ),
        onTap: () {
          _showMarkerDetails(doc.id, data);
        },
      );
    }).toSet();

    setState(() {
      _markers.addAll(markers);
    });
  }

  /// 🔹 Show marker details
  void _showMarkerDetails(String id, Map<String, dynamic> data) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Attendance Record",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text("User: $id"),
              Text("Status: ${data['status']}"),
              Text("Clock In: ${data['clockInAt'] ?? '—'}"),
              Text("Clock Out: ${data['clockOutAt'] ?? '—'}"),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text("Get Directions"),
                onPressed: () async {
                  if (_currentPosition == null) return;
                  await _drawRoute(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    LatLng(
                      (data["lat"] ?? 18.0179).toDouble(),
                      (data["lng"] ?? -76.8099).toDouble(),
                    ),
                  );
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🛣️ Get directions from Google Directions API
  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data["status"] == "OK") {
      final points = _decodePolyline(
        data["routes"][0]["overview_polyline"]["points"],
      );

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("directions"),
            color: Colors.blue,
            width: 5,
            points: points,
          ),
        );
      });
    }
  }

  /// Polyline decoder
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  /// 🔍 Search Places API
  Future<List<Map<String, dynamic>>> _searchPlaces(String input) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey";
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    return data["predictions"]?.cast<Map<String, dynamic>>() ?? [];
  }

  /// 📍 Get Place Details
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey";
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    return data["result"];
  }

  /// ☕ Load cafes nearby
  Future<void> _loadNearbyCafes() async {
    if (_currentPosition == null) return;
    final url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=1500&type=cafe&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data["status"] == "OK") {
      final results = data["results"] as List;
      setState(() {
        for (var r in results) {
          final loc = r["geometry"]["location"];
          _markers.add(
            Marker(
              markerId: MarkerId(r["place_id"]),
              position: LatLng(loc["lat"], loc["lng"]),
              infoWindow: InfoWindow(title: r["name"]),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Explore Map")),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(18.0179, -76.8099),
              zoom: 10,
            ),
            myLocationEnabled: true,
            markers: _markers,
            polylines: _polylines,
          ),

          /// 🔍 Search Bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: TypeAheadField<Map<String, dynamic>>(
              suggestionsCallback: (pattern) async =>
                  await _searchPlaces(pattern),
              itemBuilder: (context, prediction) =>
                  ListTile(title: Text(prediction["description"])),
              onSelected: (prediction) async {
                final details = await _getPlaceDetails(prediction["place_id"]);
                if (details != null) {
                  final loc = details["geometry"]["location"];
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(loc["lat"], loc["lng"]),
                      15,
                    ),
                  );
                  setState(() {
                    _markers.add(
                      Marker(
                        markerId: MarkerId(details["place_id"]),
                        position: LatLng(loc["lat"], loc["lng"]),
                        infoWindow: InfoWindow(title: details["name"]),
                      ),
                    );
                  });
                }
              },
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: "Search places...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),

          /// ✅ Filter Chips
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text("Attendance"),
                  selected: _showAttendance,
                  onSelected: (val) {
                    setState(() {
                      _showAttendance = val;
                      _markers.clear();
                      if (val) _loadAttendanceMarkers();
                    });
                  },
                ),
                FilterChip(
                  label: const Text("Cafes"),
                  selected: _showCafes,
                  onSelected: (val) async {
                    setState(() {
                      _showCafes = val;
                      _markers.clear();
                    });
                    if (val) {
                      await _loadNearbyCafes();
                    } else {
                      if (_showAttendance) _loadAttendanceMarkers();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "recenter",
            mini: true,
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
