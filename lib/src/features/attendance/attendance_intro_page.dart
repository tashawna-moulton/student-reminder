import 'package:flutter/material.dart';

class DateSearchMapBar extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onPickDate;
  final VoidCallback onSearch;
  final VoidCallback onMap;

  const DateSearchMapBar({
    super.key,
    required this.range,
    required this.onPickDate,
    required this.onSearch,
    required this.onMap,
  });

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildButton(
          icon: Icons.calendar_month,
          label: "Date",
          onTap: onPickDate,
        ),
        _buildButton(icon: Icons.search, label: "Search", onTap: onSearch),
        _buildButton(icon: Icons.location_on, label: "Map", onTap: onMap),
      ],
    );
  }
}
