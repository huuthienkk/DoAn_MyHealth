import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_controller.dart';
import '../models/health_model.dart';
import '../widgets/common/bottom_navigation_bar.dart';
import 'health_screen.dart';
import 'mood_screen.dart';
import 'food_recognizer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  final HealthController _healthController = HealthController();

  String _username = 'Người dùng';
  final List<HealthData> _healthData = [];

  int _selectedBottomIndex = 0;

  // Water intake time slots
  final List<Map<String, dynamic>> _waterIntakeSlots = [
    {'time': '6am - 8am', 'completed': true},
    {'time': '9am - 11am', 'completed': true},
    {'time': '11am - 2pm', 'completed': false},
    {'time': '2pm - 4pm', 'completed': false},
  ];

  // Activity progress data
  final List<int> _weeklySteps = [3000, 4500, 6000, 3500, 7000, 5500, 4000];

  // Workout progress data
  final List<int> _weeklyWorkout = [30, 45, 60, 35, 70, 55, 40];

  // Latest activities
  final List<Map<String, dynamic>> _latestActivities = [
    {'action': 'Drinking 300ml Water', 'time': 'About 3 minutes ago'},
    {'action': 'Eat Snack (Fitbar)', 'time': 'About 10 minutes ago'},
  ];

  @override
  void initState() {
    super.initState();
    _waitAndLoadData();
  }

  Future<void> _waitAndLoadData() async {
    while (FirebaseAuth.instance.currentUser == null) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      await _loadUserData();
      await _loadHealthData();
    } catch (e) {
      debugPrint('❌ Lỗi load data: $e');
      if (_healthData.isEmpty) _setDemoData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _authController.getUserProfile();
      if (!mounted) return;
      setState(() {
        _username = data?['username'] ?? 'Người dùng';
      });
    } catch (e) {
      debugPrint('❌ Lỗi load user: $e');
    }
  }

  Future<void> _loadHealthData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = await _healthController.getHealthData(user.uid);
      if (!mounted) return;

      if (data.isNotEmpty) {
        data.sort((a, b) => b.date.compareTo(a.date));
        final last7 = _getLast7DaysData(data);
        setState(() {
          _healthData.clear();
          _healthData.addAll(last7);
        });
      } else {
        _setDemoData();
      }
    } catch (e) {
      debugPrint('❌ Lỗi load health data: $e');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<HealthData> _getLast7DaysData(List<HealthData> allData) {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));
      final item = allData.firstWhere((d) => _isSameDay(d.date, day),
          orElse: () =>
              HealthData(date: day, steps: 0, weight: 0, sleepHours: 0));
      return item;
    });
  }

  void _setDemoData() {
    final today = DateTime.now();
    _healthData.clear();
    _healthData.addAll(List.generate(
      7,
      (index) => HealthData(
        date: today.subtract(Duration(days: 6 - index)),
        steps: _weeklySteps[index],
        weight: 65.0,
        sleepHours: 7.5,
      ),
    ));
  }

  Future<void> _refreshData() async => _loadAllData();

  void _logout() async {
    try {
      await _authController.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _showError('Không thể đăng xuất: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });

    switch (index) {
      case 0: // Trang chủ (current screen)
        break;
      case 1: // Sức khỏe
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HealthScreen()),
        );
        break;
      case 2: // Tâm trạng
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MoodScreen()),
        );
        break;
      case 3: // AI Calo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FoodRecognizerScreen()),
        );
        break;
    }
  }

  Widget _buildWaterIntakeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Water Intake',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Real time updates',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Column(
              children: _waterIntakeSlots.map((slot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        slot['completed']
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: slot['completed'] ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        slot['time'],
                        style: TextStyle(
                          fontSize: 14,
                          color: slot['completed'] ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sleep',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Calories',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '280°C',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTrackerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Tracker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Today Target',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTargetItem('Water Intake', Icons.water_drop, Colors.blue),
                const SizedBox(width: 16),
                _buildTargetItem(
                    'Foot Steps', Icons.directions_walk, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetItem(String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityProgressCard() {
    final List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final index = days.indexOf(day);
                final isToday = index == DateTime.now().weekday % 7;
                return Column(
                  children: [
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? Colors.blue : Colors.grey,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue
                            .withValues(alpha: _weeklySteps[index] / 10000),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutProgressCard() {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final index = days.indexOf(day);
                final isToday = index == (DateTime.now().weekday - 1) % 6;
                return Column(
                  children: [
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? Colors.orange : Colors.grey,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.orange
                            .withValues(alpha: _weeklyWorkout[index] / 100),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestActivityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'See more',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: _latestActivities.map((activity) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activity['action'].contains('Water')
                              ? Icons.water_drop
                              : Icons.restaurant,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['action'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              activity['time'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Xin chào, $_username',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          // Nội dung chính có thể cuộn
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // First row: Water Intake and Sleep
                    Row(
                      children: [
                        Expanded(child: _buildWaterIntakeCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSleepCard()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Activity Tracker
                    _buildActivityTrackerCard(),
                    const SizedBox(height: 16),

                    // Second row: Activity Progress and Workout Progress
                    Row(
                      children: [
                        Expanded(child: _buildActivityProgressCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildWorkoutProgressCard()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Latest Activity
                    _buildLatestActivityCard(),
                    const SizedBox(height: 16),

                    // Thêm khoảng trống phía dưới để không bị bottom navigation che
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation cố định phía dưới
          Container(
            width: double.infinity,
            color: Colors.grey[50],
            child: CustomBottomNavigationBar(
              currentIndex: _selectedBottomIndex,
              onTap: _onBottomNavTap,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
