import '../controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class LoginViewModel {
  final AuthController _authController = AuthController();

  Future<void> login(String email, String password) async {
    // Kiểm tra mạng
    final result = await InternetAddress.lookup('google.com');
    if (result.isEmpty || result[0].rawAddress.isEmpty) {
      throw Exception('Không có kết nối Internet');
    }

    try {
      await _authController.login(email, password);
    } on FirebaseAuthException catch (e) {
      rethrow; // Để UI hiển thị lỗi
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }
}
