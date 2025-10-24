import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodChart extends StatelessWidget {
  final Map<String, int> distribution;
  const MoodChart({required this.distribution, super.key}); // <-- use super.key

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const SizedBox(
          height: 150, child: Center(child: Text('Không có dữ liệu')));
    }

    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    final colors = [Colors.green, Colors.orange, Colors.red, Colors.blueGrey];

    int idx = 0;
    final sections = distribution.entries.map((e) {
      final value = e.value.toDouble();
      final percentage = total == 0 ? 0.0 : (value / total) * 100;
      final s = PieChartSectionData(
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[idx % colors.length],
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      idx++;
      return s;
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Phân bố tâm trạng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(sections: sections, centerSpaceRadius: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
