import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:students_reminder/src/widgets/map_card.dart';

class TimelineItem extends StatelessWidget {
  final String prettyDate, status, inTime, outTime;
  final String? reason;
  final LatLng? mapLatLng;
  final Color pillColor;

  const TimelineItem({
    super.key,
    required this.prettyDate,
    required this.status,
    required this.inTime,
    required this.outTime,
    this.reason,
    this.mapLatLng,
    required this.pillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                prettyDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pillColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pillColor.withOpacity(0.6)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: pillColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // In/Out times
          Row(
            children: [
              const Icon(Icons.login, size: 18, color: Colors.greenAccent),
              const SizedBox(width: 6),
              Text('In: $inTime', style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              const Icon(Icons.logout, size: 18, color: Colors.redAccent),
              const SizedBox(width: 6),
              Text(
                'Out: $outTime',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          // Reason
          if (reason != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning, size: 18, color: Colors.orangeAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Reason: $reason",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Map Preview
          if (mapLatLng != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 140,
                child: MapCard(fixedPosition: mapLatLng),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
