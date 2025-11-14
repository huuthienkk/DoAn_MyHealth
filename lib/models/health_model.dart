class HealthData {
  final DateTime date;
  final int steps;
  final double weight;
  final double sleepHours;
  
  // Các trường mới
  final double? height; // Chiều cao (cm)
  final int? systolicBP; // Huyết áp tâm thu (SYS)
  final int? diastolicBP; // Huyết áp tâm trương (DIA)
  final int? heartRate; // Nhịp tim (bpm)
  final double? waterIntake; // Lượng nước (ml)
  final double? caloriesIn; // Calo nạp vào
  final double? caloriesOut; // Calo tiêu thụ

  HealthData({
    required this.date,
    required this.steps,
    required this.weight,
    required this.sleepHours,
    this.height,
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.waterIntake,
    this.caloriesIn,
    this.caloriesOut,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'steps': steps,
        'weight': weight,
        'sleepHours': sleepHours,
        'height': height,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'heartRate': heartRate,
        'waterIntake': waterIntake,
        'caloriesIn': caloriesIn,
        'caloriesOut': caloriesOut,
      };

  factory HealthData.fromMap(Map<String, dynamic> map) => HealthData(
        date: DateTime.parse(map['date']),
        steps: map['steps'] ?? 0,
        weight: map['weight'] ?? 0.0,
        sleepHours: map['sleepHours'] ?? 0.0,
        height: map['height']?.toDouble(),
        systolicBP: map['systolicBP']?.toInt(),
        diastolicBP: map['diastolicBP']?.toInt(),
        heartRate: map['heartRate']?.toInt(),
        waterIntake: map['waterIntake']?.toDouble(),
        caloriesIn: map['caloriesIn']?.toDouble(),
        caloriesOut: map['caloriesOut']?.toDouble(),
      );
}
