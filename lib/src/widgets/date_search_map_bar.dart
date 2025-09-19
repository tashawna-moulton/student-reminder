import 'package:flutter/material.dart';

/// ✅ Modern row with Search + Options (Date/Map)
class DateSearchMapBar extends StatefulWidget {
  final VoidCallback onPickDate; // when date tapped
  final Function(String) onSearch; // when search submitted
  final VoidCallback onMap; // when map tapped

  const DateSearchMapBar({
    super.key,
    required this.onPickDate,
    required this.onSearch,
    required this.onMap,
  });

  @override
  State<DateSearchMapBar> createState() => _DateSearchMapBarState();
}

class _DateSearchMapBarState extends State<DateSearchMapBar> {
  final TextEditingController _controller = TextEditingController();

  /// 📌 Bottom sheet with "Date" and "Map" options
  void _openOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87, // dark theme sheet
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small handle bar (top indicator)
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 📅 Date option
              ListTile(
                leading: const Icon(
                  Icons.date_range,
                  color: Colors.greenAccent,
                ),
                title: const Text(
                  "Pick Date",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPickDate();
                },
              ),

              // 🗺️ Map option
              ListTile(
                leading: const Icon(Icons.map, color: Colors.deepPurpleAccent),
                title: const Text(
                  "Open Map",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onMap();
                },
              ),

              const SizedBox(height: 8),
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
        // 🔍 Search bar with purple gradient border glow
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.8),
                  Colors.deepPurple.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),

                  // 📝 Input field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search student...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onSubmitted: widget.onSearch,
                    ),
                  ),

                  // ❌ Clear button (only if text exists)
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() => _controller.clear());
                        widget.onSearch(""); // reset search
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ⚙️ Options button (opens bottom sheet with Date/Map)
        GestureDetector(
          onTap: _openOptions,
          child: Container(
            width: 60,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.more_horiz,
              color: Colors.deepPurpleAccent,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}
