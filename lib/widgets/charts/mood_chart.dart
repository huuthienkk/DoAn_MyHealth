import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodChart extends StatelessWidget {
  final Map<String, int> distribution;
  const MoodChart({required this.distribution, super.key});

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Không có dữ liệu')),
      );
    }

    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.blueAccent,
      Colors.purple
    ];

    int idx = 0;
    final sections = distribution.entries.map((entry) {
      final mood = entry.key;
      final count = entry.value.toDouble();
      final percent = total == 0 ? 0 : (count / total) * 100;

      final section = PieChartSectionData(
        value: count,
        color: colors[idx % colors.length],
        title: '${percent.toStringAsFixed(0)}%',
        radius: 55,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        badgeWidget: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            mood,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
      idx++;
      return section;
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Phân bố tâm trạng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tạo chú thích (legend)
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: distribution.keys
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: colors[entry.key % colors.length],
                          ),
                          const SizedBox(width: 4),
                          Text(entry.value.toString() == '1'
                              ? '${entry.key} (1 lần)'
                              : '${entry.key} (${entry.value} lần)'),
                        ],
                      ))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }
}
