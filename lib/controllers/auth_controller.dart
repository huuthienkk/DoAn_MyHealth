// auth_controller.dart
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseService _firebaseService = FirebaseService();

  Future<UserModel?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      return await _firebaseService.signUp(
        email: email,
        password: password,
        name: name,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      // <-- sửa tại đây
      // Không dùng biến exception, trả về lỗi tổng quát
      throw Exception('Register error');
    }
  }

  // Thay đổi kiểu trả về cho khớp với implementation của FirebaseService.signIn
  Future<dynamic> login(String email, String password) async {
    try {
      final user = await _firebaseService.signIn(
        email: email,
        password: password,
      );
      if (user == null) {
        throw Exception('Login returned null user.');
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _firebaseService.resetPassword(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Forgot password error: $e');
    }
  }

  Future<void> logout() async => await _firebaseService.signOut();

  User? getCurrentUser() => FirebaseAuth.instance.currentUser;

  // Thêm method getUserProfile để tránh lỗi gọi không tồn tại từ HomeScreen.
  // Trả về Map để dễ sử dụng mà không phụ thuộc chặt vào UserModel.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    return {
      'uid': u.uid,
      'email': u.email,
      'displayName': u.displayName,
      'username': u.displayName ?? (u.email?.split('@').first ?? 'Người dùng'),
    };
  }
}
