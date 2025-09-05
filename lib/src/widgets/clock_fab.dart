import 'package:flutter/material.dart';

class ClockFab extends StatelessWidget {
  const ClockFab({
    super.key,
    required this.isClockedIn,
    required this.onClockIn,
    required this.onClockOut,
  });

  final bool isClockedIn;
  final VoidCallback? onClockIn;
  final VoidCallback? onClockOut;

  @override
  Widget build(BuildContext context) {
    final label = isClockedIn ? 'Clock Out' : 'Clock In';
    final icon  = isClockedIn ? Icons.logout_rounded : Icons.login_rounded;
    final onTap = isClockedIn ? onClockOut : onClockIn;

    return FloatingActionButton.extended(
      heroTag: 'clock-fab',
      onPressed: onTap, // can be null to disable
      icon: Icon(icon),
      label: Text(label),
    );
  }
}