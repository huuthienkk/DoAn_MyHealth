import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/health_model.dart';
import '../../utils/constants.dart';
import '../common/empty_state.dart';

class HealthChart extends StatelessWidget {
  final List<HealthData> data;
  final Color lineColor;
  final String title;
  final String unit;

  const HealthChart({
    required this.data,
    this.lineColor = AppColors.primary,
    this.title = 'Bước trong những ngày gần đây',
    this.unit = 'bước',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 220,
        child: EmptyState(
          icon: Icons.bar_chart,
          title: 'Không có dữ liệu',
          message: 'Hãy thêm dữ liệu để xem biểu đồ',
          iconColor: AppColors.textTertiary,
        ),
      );
    }

    // Sắp xếp theo ngày (tạo copy để không mutate original)
    final sortedData = List<HealthData>.from(data)..sort((a, b) => a.date.compareTo(b.date));

    final spots = List.generate(
      sortedData.length,
      (index) => FlSpot(
        index.toDouble(),
        sortedData[index].steps.toDouble(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.transparent,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.border,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: AppTextStyles.caption,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= sortedData.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        DateFormat('dd/MM').format(sortedData[idx].date),
                        style: AppTextStyles.caption,
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        lineColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  spots: spots,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Đơn vị: $unit',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
