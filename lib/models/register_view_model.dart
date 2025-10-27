import '../controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterViewModel {
  final AuthController _authController = AuthController();

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _authController.register(name, email, password);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Lỗi khi đăng ký: $e');
    }
  }
}
