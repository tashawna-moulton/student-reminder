import 'package:flutter/material.dart';

class StatusDot extends StatelessWidget {
  final String status;
  const StatusDot({super.key, required this.status});

  Color _color() {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 8, backgroundColor: _color());
  }
}
