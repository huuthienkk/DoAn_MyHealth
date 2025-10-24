import '../models/mood_model.dart';
import '../services/firebase_service.dart';

class MoodController {
  final FirebaseService _service = FirebaseService();

  Future<void> addMood(String uid, MoodData data) async {
    await _service.addMoodData(uid, data);
  }

  Future<List<MoodData>> getMood(String uid) async {
    return await _service.getMoodData(uid);
  }
}
