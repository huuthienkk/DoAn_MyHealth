import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/constants.dart';
import '../common/empty_state.dart';

class MoodChart extends StatelessWidget {
  final Map<String, int> distribution;
  const MoodChart({required this.distribution, super.key});

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return SizedBox(
        height: 200,
        child: EmptyState(
          icon: Icons.pie_chart,
          title: 'Không có dữ liệu',
          message: 'Hãy ghi lại tâm trạng để xem biểu đồ',
          iconColor: AppColors.textTertiary,
        ),
      );
    }

    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    final colors = [
      AppColors.happy,
      AppColors.neutral,
      AppColors.sad,
      AppColors.primary,
      AppColors.secondary,
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

    return Column(
      children: [
        Text(
          'Phân bố tâm trạng',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.md),
        // Tạo chú thích (legend)
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: distribution.entries.toList().asMap().entries.map((entry) {
            final moodEntry = entry.value;
            final count = moodEntry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[entry.key % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  count == 1
                      ? '${moodEntry.key} (1 lần)'
                      : '${moodEntry.key} ($count lần)',
                  style: AppTextStyles.caption,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
