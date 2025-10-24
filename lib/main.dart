// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'firebase_options.dart';
import 'screens/health_screen.dart'; // 🟢 Thêm dòng này

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Log lỗi khởi tạo Firebase
    debugPrint('Firebase initialize error: $e');
  }

  // Khởi tạo hệ thống thông báo cục bộ
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('NotificationService initialize error: $e');
  }

  // Warm-up storage (không bắt buộc, chỉ để tải cache nếu có)
  try {
    await StorageService.instance.getHealthJson();
    await StorageService.instance.getMoodJson();
  } catch (e) {
    debugPrint('StorageService warm-up error: $e');
  }

  // Khóa orientation (tuỳ chọn)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Giám sát sức khỏe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/health': (context) => const HealthScreen(),
      },
    );
  }
}
