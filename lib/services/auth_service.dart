import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseService _firebaseService = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Đăng nhập bằng Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return null;

      // Lưu thông tin vào Firestore
      await _firebaseService.signIn(
        email: user.email ?? '',
        password: '', // Không cần password cho OAuth
      );

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName,
      );
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  /// Kiểm tra xem thiết bị có hỗ trợ biometric không
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Lấy danh sách các phương thức biometric có sẵn
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Xác thực bằng biometric
  Future<bool> authenticateWithBiometrics({
    String reason = 'Xác thực để truy cập ứng dụng',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Đăng xuất Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }
}

