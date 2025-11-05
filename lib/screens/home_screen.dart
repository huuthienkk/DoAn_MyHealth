import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../../models/health_model.dart';
import '../widgets/charts/health_chart.dart';
import '../widgets/charts/mood_chart.dart';
import 'health_screen.dart';
import 'mood_screen.dart';
import 'food_recognizer_screen.dart'; // ✅ thêm dòng này

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  String _username = 'Người dùng';
  final String _currentMood = 'Bình thường';
  int _steps = 3500;

  final List<String> _healthTips = [
    '💧 Uống đủ 2 lít nước mỗi ngày',
    '🏃‍♀️ Tập thể dục ít nhất 30 phút',
    '🕒 Ngủ đủ 7–8 tiếng',
    '🥗 Ăn nhiều rau xanh và trái cây',
  ];

  int _selectedTipIndex = 0;

  // 🔹 Dữ liệu demo cho biểu đồ
  final List<HealthData> _healthData = List.generate(
    7,
    (index) => HealthData(
      date: DateTime.now().subtract(Duration(days: 6 - index)),
      steps: 3000 + index * 500,
      weight: 60 + index * 0.2,
      sleepHours: 7 + (index % 2 == 0 ? 0.5 : -0.3),
    ),
  );

  final Map<String, int> _moodData = {
    'Vui': 5,
    'Buồn': 2,
    'Căng thẳng': 1,
    'Thư giãn': 3,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startTipRotation();
  }

  void _startTipRotation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _selectedTipIndex = (_selectedTipIndex + 1) % _healthTips.length;
        });
        _startTipRotation();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _authController.getUserProfile();
      if (!mounted) return;
      setState(() {
        _username = data?['username'] ?? 'Người dùng';
      });
    } catch (e) {
      _showError('Không tải được dữ liệu: $e');
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _steps += 150;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authController.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _showError('Không thể đăng xuất: $e');
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
      String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 38),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  //                    BUILD UI CHÍNH
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Xin chào, $_username',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Tip of the day
                  Card(
                    elevation: 6,
                    shadowColor: Colors.white.withValues(alpha: 0.2),
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.tips_and_updates_rounded,
                              color: Color(0xFF2575FC), size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                _healthTips[_selectedTipIndex],
                                key: ValueKey(_selectedTipIndex),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🔹 Daily Progress
                  Text('Tiến trình hôm nay',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _steps / 10000,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _steps >= 10000 ? Colors.greenAccent : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(_steps / 10000 * 100).toInt()}% hoàn thành mục tiêu',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 25),

                  // 🔹 Stats Cards
                  _buildStatCard('Số bước hôm nay', '$_steps / 10.000',
                      Icons.directions_walk_rounded, Colors.orange),
                  const SizedBox(height: 16),
                  _buildStatCard(
                      'Tâm trạng', _currentMood, Icons.mood, Colors.purple),
                  const SizedBox(height: 25),

                  // 🔹 Biểu đồ thống kê
                  HealthChart(
                    data: _healthData,
                    title: 'Số bước đi 7 ngày gần đây',
                    unit: 'bước',
                    lineColor: Colors.orange,
                  ),
                  const SizedBox(height: 20),
                  MoodChart(distribution: _moodData),
                  const SizedBox(height: 35),

                  // 🔹 Quick Actions
                  Text('Truy cập nhanh',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildNavigationButton('Sức khỏe', Icons.favorite, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HealthScreen()),
                        );
                      }),
                      const SizedBox(width: 16),
                      _buildNavigationButton('Tâm trạng', Icons.mood, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MoodScreen()),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildNavigationButton('AI Calo', Icons.fastfood_rounded,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const FoodRecognizerScreen()),
                        );
                      }),
                      const SizedBox(width: 16),
                      _buildNavigationButton('Lịch sử', Icons.history_rounded,
                          () {
                        // sau này có thể làm thêm trang thống kê
                      }),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2575FC),
        child: const Icon(Icons.add),
      ),
    );
  }
}
