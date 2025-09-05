import 'package:flutter/material.dart';

class MapCard extends StatelessWidget {
  const MapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Google Map goes here'),
      ),
    );
  }
}