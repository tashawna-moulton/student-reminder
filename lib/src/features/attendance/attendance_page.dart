import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:students_reminder/src/features/attendance/attendance_history.dart';
//import 'package:geolocator/geolocator.dart';

import '../../services/attendance_repository.dart';
import '../../services/location_service.dart';

// ✅ Reusable UI widgets
import '../../widgets/clock_fab.dart';
import '../../widgets/status_strip.dart';
import '../../widgets/map_card.dart';
import '../../widgets/late_reason_dialog.dart';

const _cardRadius = 20.0;
const bool _bypassTimeWindowForTesting = false;
// TODO: revert when time gating is reinstated
const bool _skipAutoClockOutForTesting = false;
// TODO: revert when auto clock-out is reinstated

enum _SnackKind { success, warning, error }

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with WidgetsBindingObserver {
  final _repo = AttendanceRepository();
  final _loc = LocationService();

  bool _isClockedIn = false;
  AttendanceDay? _today;
  List<AttendanceDay> _recentDays = const [];
  StreamSubscription<AttendanceDay?>? _todaySub;
  StreamSubscription<List<AttendanceDay>>? _historySub;
  Timer? _clockTicker;
  DateTime _now = DateTime.now();

  final DateFormat _clockFormat = DateFormat('h:mm a');
  final DateFormat _dayFormat = DateFormat('EEE, MMM d');
  final DateFormat _storageFormat = DateFormat('yyyy-MM-dd');
  bool _autoClocking = false;
  MapStatus _mapStatus = const MapStatus.loading();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startClock();
    _listenToday();
    _listenRecent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoClockOutIfNeeded();
    }
  }

  void _listenToday() {
    _todaySub?.cancel();
    _todaySub = _repo.watchToday().listen((day) {
      setState(() {
        _today = day;
        _isClockedIn = day?.clockInAt != null && day?.clockOutAt == null;
      });
      _autoClockOutIfNeeded();
    });
  }

  void _listenRecent() {
    _historySub?.cancel();
    _historySub = _repo.watchRecentDays(limit: 10).listen((days) {
      setState(() => _recentDays = days);
    });
  }

  void _startClock() {
    _clockTicker?.cancel();
    _now = DateTime.now();
    _clockTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _todaySub?.cancel();
    _historySub?.cancel();
    _clockTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- Status Colors + Icons ---
  Color _statusColor(String? status) {
    switch (status) {
      case 'early':
        return const Color(0xFF2ECC71);
      case 'late':
        return const Color(0xFFF39C12);
      case 'present':
        return const Color(0xFF3498DB);
      case 'absent':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF9B59B6);
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'early':
        return Icons.check_circle;
      case 'late':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.radio_button_checked;
    }
  }

  Widget _buildStatusBadge(String? status) {
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final label = (status ?? 'No status').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- Time Helpers ---
  String _formatTime(DateTime? value) =>
      value == null ? '--' : _clockFormat.format(value);

  String _formatDuration(Duration duration) {
    final value = duration.isNegative ? duration.abs() : duration;
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return hours > 0
        ? '${hours}h ${minutes.toString().padLeft(2, '0')}m'
        : '${minutes}m';
  }

  Duration? _clockedDuration() {
    final clockIn = _today?.clockInAt;
    if (clockIn == null) return null;
    final end = _today?.clockOutAt ?? _now;
    return end.difference(clockIn);
  }

  // ✅ Summary Row
  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white60 : Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        valueColor ?? (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Elapsed Row
  Widget _buildElapsedRow(Duration duration) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(Icons.timer, size: 22, color: Colors.indigo.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elapsed time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Late Reason Pill
  Widget _buildLateReason(String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag, color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Late reason',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Map + Pills
  Widget _buildOverviewSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        final pills = SizedBox(
          width: isWide ? 200 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationPill(),
              const SizedBox(height: 12),
              _buildStatusSummaryPill(),
            ],
          ),
        );

        final mapCard = Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
          elevation: 6,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 300,
            child: MapCard(onStatusChanged: _handleMapStatusChanged),
          ),
        );

        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  pills,
                  const SizedBox(width: 20),
                  Expanded(child: mapCard),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [pills, const SizedBox(height: 16), mapCard],
              );
      },
    );
  }

  void _handleMapStatusChanged(MapStatus status) {
    if (!mounted) return;
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.idle ||
        scheduler.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      setState(() => _mapStatus = status);
    } else {
      scheduler.addPostFrameCallback((_) {
        if (mounted) setState(() => _mapStatus = status);
      });
    }
  }

  Widget _buildLocationPill() {
    String text; // Message inside the pill
    Color pillColor; // Background color of the pill
    Color textColor; // Text + border color
    String emoji; // Emoji icon depending on state

    // Decide look based on map status
    switch (_mapStatus.state) {
      case MapLoadState.ready:
        // If map is ready, show coordinates if available
        final pos = _mapStatus.position;
        final coords = pos != null
            ? 'Lat ${pos.latitude.toStringAsFixed(4)}, Lng ${pos.longitude.toStringAsFixed(4)}'
            : 'Location ready';

        text = coords;
        pillColor = Colors.green.shade50; // light green background
        textColor = Colors.green.shade700; // dark green text
        emoji = "📍"; // pin emoji
        break;

      case MapLoadState.error:
        // If error, show error message
        text = 'Location error: ${_mapStatus.error ?? "Unknown"}';
        pillColor = Colors.red.shade50; // light red background
        textColor = Colors.red.shade700; // dark red text
        emoji = "❌"; // cross emoji
        break;

      case MapLoadState.loading:
      default:
        // While loading, show waiting message
        text = 'Detecting location…';
        pillColor = Colors.grey.shade200; // light gray background
        textColor = Colors.grey.shade600; // medium gray text
        emoji = "⏳"; // hourglass emoji
        break;
    }

    // Build the styled pill UI
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: pillColor, // background color
        borderRadius: BorderRadius.circular(30), // rounded pill shape
        border: Border.all(
          // thin border
          color: textColor.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji on the left
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          // Status text (wraps if too long)
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummaryPill() {
    final color = _statusColor(_today?.status);
    final icon = _statusIcon(_today?.status);
    final statusLabel = (_today?.status ?? 'No status').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            "Today's Status: $statusLabel",
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ✅ Window Banner (fixed missing method)
  Widget _buildWindowBanner() {
    final now = _now;
    final start = DateTime(now.year, now.month, now.day, 8, 0);
    final end = DateTime(now.year, now.month, now.day, 16, 0);
    String message;
    IconData icon;
    Color accent;

    if (now.isBefore(start)) {
      icon = Icons.upcoming;
      accent = Colors.blue.shade600;
      message = 'Clock-in opens in ${_formatDuration(start.difference(now))}';
    } else if (now.isAfter(end)) {
      icon = Icons.lock_clock;
      accent = Colors.grey.shade600;
      message = 'Clock-in closed at ${_clockFormat.format(end)}';
    } else {
      icon = Icons.schedule;
      accent = Colors.green.shade600;
      message = 'Clock-in closes in ${_formatDuration(end.difference(now))}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Auto clock-out method
  void _autoClockOutIfNeeded() {
    if (_skipAutoClockOutForTesting) return;
    if (!mounted || _autoClocking) return;
    final day = _today;
    if (day == null) return;
    if (day.clockInAt == null || day.clockOutAt != null) return;

    final cutoff = DateTime(
      day.clockInAt!.year,
      day.clockInAt!.month,
      day.clockInAt!.day,
      16,
      0,
    );
    if (!DateTime.now().isAfter(cutoff)) return;

    _autoClocking = true;
    _performClockOut(auto: true).whenComplete(() => _autoClocking = false);
  }

  // ✅ ClockIn + ClockOut
  Future<void> _handleClockIn() async {
    final now = DateTime.now();

    // Enforce clock-in time window: 8:00 AM – 4:00 PM
    if (!_bypassTimeWindowForTesting && (now.hour < 8 || now.hour >= 16)) {
      _showSnack(
        '⚠️ Clock in only allowed between 8:00–16:00',
        _SnackKind.warning,
      );
      return;
    }

    final hasPerm = await _loc.ensurePermission();
    if (!hasPerm) {
      _showSnack('⚠️ Location permission required', _SnackKind.warning);
      return;
    }

    final pos = await _loc.getCurrentPosition();

    // Define cutoffs
    final start = DateTime(now.year, now.month, now.day, 8, 0); // 8:00 AM
    final cutoff = DateTime(now.year, now.month, now.day, 8, 30); // 8:30 AM

    String status;
    String? lateReason;

    if (now.isBefore(start)) {
      status = 'early'; // before 8:00
    } else if (now.isBefore(cutoff)) {
      status = 'present'; // between 8:00 and 8:29
    } else {
      status = 'late'; // 8:30 or later
      lateReason = await showLateReasonDialog(context);
      if (lateReason == null || lateReason.trim().isEmpty) return;
    }

    await _repo.clockIn(
      lat: pos.latitude,
      lng: pos.longitude,
      status: status,
      lateReason: lateReason,
    );

    _showSnack('✅ Clocked in (${status.toUpperCase()})', _SnackKind.success);
  }

  Future<void> _handleClockOut() async {
    await _performClockOut(auto: false);
  }

  Future<void> _performClockOut({required bool auto}) async {
    if (!_isClockedIn) return;
    final day = _today;
    if (day == null || day.clockInAt == null) return;

    final hasPerm = await _loc.ensurePermission();
    if (!hasPerm) {
      if (!auto) {
        _showSnack(
          '⚠️ Location permission required to clock out.',
          _SnackKind.warning,
        );
      }
      return;
    }

    final pos = await _loc.getCurrentPosition();
    await _repo.clockOut(lat: pos.latitude, lng: pos.longitude);

    _showSnack(
      auto
          ? '✅ Auto clocked out at 4:00 PM.'
          : '✅ Clocked out. Have a good rest!',
      _SnackKind.success,
    );
  }

  void _showSnack(String message, _SnackKind kind) {
    IconData icon;
    Color color;

    switch (kind) {
      case _SnackKind.success:
        icon = Icons.check_circle_outline;
        color = const Color(0xFF27AE60);
        break;
      case _SnackKind.warning:
        icon = Icons.schedule;
        color = const Color(0xFFF39C12);
        break;
      case _SnackKind.error:
        icon = Icons.close_rounded;
        color = const Color(0xFFC0392B);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // ✅ Today’s Summary
  Widget _buildTodaySummary() {
    final day = _today;
    final duration = _clockedDuration();
    final lateReason = day?.lateReason?.trim();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      elevation: 6,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayFormat.format(_now),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _clockFormat.format(_now),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(day?.status),
              ],
            ),
            const SizedBox(height: 16),

            _buildWindowBanner(),
            const SizedBox(height: 16),
            _buildSummaryRow(
              icon: Icons.login,
              label: 'Clocked in',
              value: day?.clockInAt != null
                  ? _formatTime(day?.clockInAt)
                  : 'Not yet',
            ),
            const Divider(height: 20),
            _buildSummaryRow(
              icon: Icons.logout,
              label: 'Clocked out',
              value: day?.clockOutAt != null
                  ? _formatTime(day?.clockOutAt)
                  : 'Not yet',
            ),
            if (duration != null) ...[
              const Divider(height: 20),
              _buildElapsedRow(duration),
            ],
            if (day?.clockInLat != null && day?.clockInLng != null) ...[
              const Divider(height: 20),
              _buildSummaryRow(
                icon: Icons.location_on,
                label: 'Clock-in location',
                value:
                    '${day!.clockInLat!.toStringAsFixed(5)}, ${day.clockInLng!.toStringAsFixed(5)}',
              ),
            ],

            if (lateReason != null && lateReason.isNotEmpty) ...[
              const Divider(height: 20),
              _buildLateReason(lateReason),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ History section
  Widget _buildHistorySection() {
    if (_recentDays.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        elevation: 4,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: const [
              Icon(Icons.history, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Your attendance history will appear here once you start clocking in.',
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _recentDays.map((day) {
        return ListTile(
          leading: Icon(
            _statusIcon(day.status),
            color: _statusColor(day.status),
          ),
          title: Text(_storageFormat.format(DateTime.parse(day.id))),
          subtitle: Text(day.status ?? 'No status'),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyStreaks() {
    // Find start of this week (Monday)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Generate Mon–Fri dates
    final weekDays = List.generate(5, (i) {
      final date = startOfWeek.add(Duration(days: i));
      final dateId = DateFormat('yyyy-MM-dd').format(date);

      // Match with attendance records
      final match = _recentDays.firstWhere(
        (d) => d.dateId == dateId,
        orElse: () => AttendanceDay(id: dateId, dateId: dateId, status: null),
      );

      String emoji;
      switch (match.status) {
        case 'early':
          emoji = '✅'; // on time
          break;
        case 'late':
          emoji = '⏰'; // late
          break;
        case 'absent':
          emoji = '🚫'; // absent
          break;
        default:
          emoji = '⚪'; // no record
      }

      return {
        'label': DateFormat('E').format(date), // Mon, Tue, ...
        'emoji': emoji,
      };
    });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) {
            return Column(
              children: [
                Text(
                  day['label']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(day['emoji']!, style: const TextStyle(fontSize: 22)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AttendanceHistory()),
              );
            },
            icon: Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: StatusStrip(status: _today?.status)),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _buildOverviewSection()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTodaySummary(),
                  const SizedBox(height: 16),
                  _buildHistorySection(),
                  const SizedBox(height: 16),
                  _buildWeeklyStreaks(),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ClockFab(
        isClockedIn: _isClockedIn,
        onClockIn: _handleClockIn,
        onClockOut: _handleClockOut,
      ),
    );
  }
}
