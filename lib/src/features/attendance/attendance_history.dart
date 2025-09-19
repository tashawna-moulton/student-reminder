import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Map<String, dynamic>>> _attendanceEvents = {};

  DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
  }


  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    Icon getStatusIcon(String status) {
      switch (status.toLowerCase()) {
        case 'present':
          return const Icon(Icons.check_circle, color: Colors.green);
        case 'late':
          return const Icon(Icons.access_time, color: Colors.orange);
        case 'absent':
          return const Icon(Icons.cancel, color: Colors.red);
        default:
          return const Icon(Icons.help_outline, color: Colors.grey);
      }
    }

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'present':
          return Colors.green;
        case 'late':
          return Colors.orange;
        case 'absent':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    void showMapDialog(
      BuildContext context,
      GeoPoint? clockInLocation,
      GeoPoint? clockOutLocation,
      DateTime? clockInAt,
      DateTime? clockOutAt,
    ) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        clockInLocation?.latitude ?? 0.0,
                        clockInLocation?.longitude ?? 0.0,
                      ),
                      zoom: 15,
                    ),
                    markers: {
                      if (clockInLocation != null)
                        Marker(
                          markerId: const MarkerId('clockIn'),
                          position: LatLng(
                            clockInLocation.latitude,
                            clockInLocation.longitude,
                          ),
                          infoWindow: InfoWindow(
                            title: 'Clock In',
                            snippet: DateFormat('hh:mm a').format(clockInAt!),
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                      if (clockOutLocation != null)
                        Marker(
                          markerId: const MarkerId('clockOut'),
                          position: LatLng(
                            clockOutLocation.latitude,
                            clockOutLocation.longitude,
                          ),
                          infoWindow: InfoWindow(
                            title: 'Clock Out',
                            snippet: DateFormat('hh:mm a').format(clockOutAt!),
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                    },
                  ),
                ),
              );
            },
          );
        },
      );
    }

    GeoPoint? getGeoPoint(dynamic value) {
      if (value is GeoPoint) return value;
      if (value is Map<String, dynamic> &&
          value.containsKey('latitude') &&
          value.containsKey('longitude')) {
        final lat = value['latitude'];
        final lng = value['longitude'];
        if (lat is num && lng is num) {
          return GeoPoint(lat.toDouble(), lng.toDouble());
        }
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TableCalendar(
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),

              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),         
              ),
              eventLoader: (day) {
                  return _attendanceEvents[normalizeDate(day)] ?? [];
                },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                      
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((event) {
                    if (event is! Map<String, dynamic>) return const SizedBox();
                    final status = (event['status'] ?? '').toLowerCase();
                    final markerColor = getStatusColor(status);
                         return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 6,
                              height: 6,
                             decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: markerColor,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                )
            ),
          
          SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            child: const Text("Today"),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('attendance')
                  .doc(user.uid)
                  .collection('days')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];

                _attendanceEvents.clear();

                for (var doc in docs) {
                  final data = doc.data();
                  final date = parseDate(data['date']);
                  if (date != null) {
                    final normalized = normalizeDate(date);
                    _attendanceEvents.putIfAbsent(normalized, () => []).add(data);
                  }
                } 
                final filteredDocs = _selectedDay == null
                    ? docs
                    : docs.where((doc) {
                        final date = parseDate(doc['date']);
                        return date != null &&
                            date.year == _selectedDay!.year &&
                            date.month == _selectedDay!.month &&
                            date.day == _selectedDay!.day;
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No attendance records for this day.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data();

                    final dateparsed = parseDate(data['date']);
                    final date = dateparsed != null
                        ? DateFormat('dd-MMM').format(dateparsed)
                        : 'Unknown Date';

                    final status = data['status'] ?? 'Unknown Status';

                    final clockTimestamp = data['clockInAt'] as Timestamp?;
                    final clockInAt = clockTimestamp != null
                        ? DateFormat('hh:mm a').format(clockTimestamp.toDate())
                        : 'Not Clocked In';

                    final clockOutTimestamp = data['clockOutAt'] as Timestamp?;
                    final clockOutAt = clockOutTimestamp != null
                        ? DateFormat('hh:mm a').format(clockOutTimestamp.toDate())
                        : 'Not Clocked Out';

                    final lateReason = data['lateReason'] ?? 'no reason';

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            elevation: 4,
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              title: Text(date),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      getStatusIcon(status),
                                      const SizedBox(width: 8),
                                      Text(status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Late reason: $lateReason'),
                                  Text('clock in: $clockInAt'),
                                  Text('Clock out: $clockOutAt'),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.map,
                                color: Colors.blue,
                              ),
                            
                              onTap: () {
                                final clockInLocation = getGeoPoint(
                                  data['clockInLoc'],
                                );
                                final clockOutLocation = getGeoPoint(
                                  data['clockOutLoc'],
                                );
                            
                                final clockTimestamp = data['clockInAt'] as Timestamp?;
                                final clockOutTimestamp = data['clockOutAt'] as Timestamp?;
                            
                                if (clockInLocation == null &&
                                    clockOutLocation == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "No valid location data found.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                showMapDialog(
                                  context,
                                  clockInLocation,
                                  clockOutLocation,
                                  clockTimestamp?.toDate(),
                                  clockOutTimestamp?.toDate(),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}