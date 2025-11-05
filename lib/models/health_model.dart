class HealthData {
  final DateTime date;
  final int steps;
  final double weight;
  final double sleepHours;

  HealthData({
    required this.date,
    required this.steps,
    required this.weight,
    required this.sleepHours,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'steps': steps,
        'weight': weight,
        'sleepHours': sleepHours,
      };

  factory HealthData.fromMap(Map<String, dynamic> map) => HealthData(
        date: DateTime.parse(map['date']),
        steps: map['steps'],
        weight: map['weight'],
        sleepHours: map['sleepHours'],
      );
}
