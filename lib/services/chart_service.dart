import 'package:intl/intl.dart';
import '../models/health_model.dart';
import '../models/mood_model.dart';

class ChartService {
  // Trả về dữ liệu health cho N ngày gần nhất (sắp xếp theo ngày tăng dần)
  static List<HealthData> lastNDaysHealth(List<HealthData> all, int n) {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: n - 1));
    // Map ngày->HealthData (nếu có nhiều entry cùng ngày, lấy tổng steps và trung bình weight/sleep)
    final Map<String, HealthData> map = {};
    final fmt = DateFormat('yyyy-MM-dd');
    for (var h in all) {
      final key = fmt.format(h.date);
      if (!map.containsKey(key)) {
        map[key] = HealthData(
          date: DateTime.parse(key),
          steps: h.steps,
          weight: h.weight,
          sleepHours: h.sleepHours,
        );
      } else {
        final ex = map[key]!;
        map[key] = HealthData(
          date: ex.date,
          steps: ex.steps + h.steps,
          weight: (ex.weight + h.weight) / 2,
          sleepHours: (ex.sleepHours + h.sleepHours) / 2,
        );
      }
    }
    final List<HealthData> result = [];
    for (int i = 0; i < n; i++) {
      final d = start.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      if (map.containsKey(key)) {
        result.add(map[key]!);
      } else {
        result.add(HealthData(date: d, steps: 0, weight: 0, sleepHours: 0));
      }
    }
    return result;
  }

  // Thống kê phân bố mood (map mood->count)
  static Map<String, int> moodDistribution(List<MoodData> list) {
    final Map<String, int> out = {};
    for (var m in list) {
      out[m.mood] = (out[m.mood] ?? 0) + 1;
    }
    return out;
  }
}
