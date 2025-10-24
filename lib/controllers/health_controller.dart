import '../models/health_model.dart';
import '../services/firebase_service.dart';

class HealthController {
  final FirebaseService _service = FirebaseService();

  Future<void> addHealthData(String uid, HealthData data) async {
    await _service.addHealthData(uid, data);
  }

  Future<List<HealthData>> getHealthData(String uid) async {
    return await _service.getHealthData(uid);
  }
}
