import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsCharts extends StatelessWidget {
  final List<int> series;
  final Map<String, int> counts;

  const AnalyticsCharts({
    super.key,
    required this.series,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final pieSections = [
      PieChartSectionData(
        value: (counts['present'] ?? 0).toDouble(),
        color: Colors.greenAccent,
        title: "Present",
      ),
      PieChartSectionData(
        value: (counts['late'] ?? 0).toDouble(),
        color: Colors.orangeAccent,
        title: "Late",
      ),
      PieChartSectionData(
        value: (counts['absent'] ?? 0).toDouble(),
        color: Colors.redAccent,
        title: "Absent",
      ),
    ];

    final barGroups = List.generate(series.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: series[i].toDouble(),
            width: 14,
            borderRadius: BorderRadius.circular(6),
            color: series[i] == 1 ? Colors.greenAccent : Colors.redAccent,
          ),
        ],
      );
    });

    return Column(
      children: [
        // Bar Chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurple, width: 1.2),
          ),
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= series.length)
                        return const SizedBox();
                      final day = DateFormat('E')
                          .format(
                            DateTime.now().subtract(Duration(days: 6 - idx)),
                          )
                          .substring(0, 1);
                      return Text(
                        day,
                        style: const TextStyle(color: Colors.white70),
                      );
                    },
                  ),
                ),
              ),
              barGroups: barGroups,
              maxY: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Pie Chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurple, width: 1.2),
          ),
          child: PieChart(
            PieChartData(
              sections: pieSections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}
