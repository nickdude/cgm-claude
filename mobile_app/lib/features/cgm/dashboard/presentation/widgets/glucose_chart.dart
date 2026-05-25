import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';

class GlucoseChart
    extends StatelessWidget {
  final List<FlSpot> spots;

  const GlucoseChart({
    super.key,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 50,
        maxY: 250,

        gridData: FlGridData(
          show: true,
        ),

        borderData: FlBorderData(
          show: false,
        ),

        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),

          rightTitles: const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),

          topTitles: const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            isCurved: true,

            barWidth: 4,

            dotData: FlDotData(
              show: false,
            ),

            belowBarData:
                BarAreaData(
              show: true,
            ),

            spots: spots,
          ),
        ],
      ),
    );
  }
}