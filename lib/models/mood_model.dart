class MoodData {
  final DateTime date;
  final String mood; // vui, buồn, bình thường...
  final int stressLevel; // 1-10
  final String note;

  MoodData({
    required this.date,
    required this.mood,
    required this.stressLevel,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'mood': mood,
    'stressLevel': stressLevel,
    'note': note,
  };

  factory MoodData.fromMap(Map<String, dynamic> map) => MoodData(
    date: DateTime.parse(map['date']),
    mood: map['mood'],
    stressLevel: map['stressLevel'],
    note: map['note'],
  );
}
