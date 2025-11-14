import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_controller.dart';
import '../models/health_model.dart';
import '../widgets/common/bottom_navigation_bar.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/section_header.dart';
import '../utils/constants.dart';
import 'health_screen.dart';
import 'mood_screen.dart';
import 'food_recognizer_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

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
    {
      'action': 'Uống 300ml nước',
      'time': 'Cách đây 3 phút',
      'icon': Icons.water_drop
    },
    {
      'action': 'Ăn nhẹ (Fitbar)',
      'time': 'Cách đây 10 phút',
      'icon': Icons.restaurant
    },
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
      backgroundColor: AppColors.error,
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
    final completedCount =
        _waterIntakeSlots.where((s) => s['completed'] == true).length;
    final totalCount = _waterIntakeSlots.length;
    final progress = completedCount / totalCount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.water.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: AppColors.water,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lượng nước uống',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Cập nhật thời gian thực',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.water),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$completedCount/$totalCount khung giờ hoàn thành',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: _waterIntakeSlots.map((slot) {
              final isCompleted = slot['completed'] == true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      slot['time'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            isCompleted ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    final todayData = _healthData.isNotEmpty
        ? _healthData.firstWhere(
            (d) => _isSameDay(d.date, DateTime.now()),
            orElse: () => HealthData(
                date: DateTime.now(), steps: 0, weight: 0, sleepHours: 0),
          )
        : HealthData(date: DateTime.now(), steps: 0, weight: 0, sleepHours: 0);

    return StatCard(
      title: 'Giấc ngủ',
      subtitle: 'Giờ ngủ hôm nay',
      value: '${todayData.sleepHours.toStringAsFixed(1)}h',
      icon: Icons.bedtime,
      color: AppColors.sleep,
    );
  }

  Widget _buildActivityTrackerCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mục tiêu hôm nay',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTargetItem(
                  'Lượng nước',
                  Icons.water_drop,
                  AppColors.water,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTargetItem(
                  'Số bước',
                  Icons.directions_walk,
                  AppColors.steps,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetItem(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityProgressCard() {
    final List<String> days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final todayIndex = DateTime.now().weekday % 7;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ hoạt động',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final isToday = index == todayIndex;
              final steps =
                  index < _weeklySteps.length ? _weeklySteps[index] : 0;
              final height = (steps / 10000 * 40).clamp(8.0, 40.0);

              return Column(
                children: [
                  Text(
                    day,
                    style: AppTextStyles.caption.copyWith(
                      color:
                          isToday ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 6,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: (steps / 10000).clamp(0.3, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutProgressCard() {
    final List<String> days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final todayIndex = (DateTime.now().weekday - 1) % 6;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ tập luyện',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final isToday = index == todayIndex;
              final minutes =
                  index < _weeklyWorkout.length ? _weeklyWorkout[index] : 0;
              final height = (minutes / 100 * 40).clamp(8.0, 40.0);

              return Column(
                children: [
                  Text(
                    day,
                    style: AppTextStyles.caption.copyWith(
                      color:
                          isToday ? AppColors.warning : AppColors.textSecondary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 6,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(
                        alpha: (minutes / 100).clamp(0.3, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestActivityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Hoạt động gần đây',
            onSeeMore: () {},
            seeMoreText: 'Xem thêm',
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: _latestActivities.map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activity['icon'] ?? Icons.info,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['action'],
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            activity['time'],
                            style: AppTextStyles.caption,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Xin chào, $_username',
        actions: [
          AppIconButton(
            icon: Icons.notifications_none,
            onPressed: () {},
            tooltip: 'Thông báo',
          ),
          const SizedBox(width: AppSpacing.sm),
          AppIconButton(
            icon: Icons.logout,
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // Nội dung chính có thể cuộn
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // First row: Water Intake and Sleep
                    Row(
                      children: [
                        Expanded(child: _buildWaterIntakeCard()),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildSleepCard()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Activity Tracker
                    _buildActivityTrackerCard(),
                    const SizedBox(height: AppSpacing.md),

                    // Second row: Activity Progress and Workout Progress
                    Row(
                      children: [
                        Expanded(child: _buildActivityProgressCard()),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildWorkoutProgressCard()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Latest Activity
                    _buildLatestActivityCard(),
                    const SizedBox(height: AppSpacing.md),

                    // Quick Actions
                    SectionHeader(title: 'Tính năng khác'),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Hồ sơ',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppCard(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReportsScreen(),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.assessment,
                                    size: 32,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Báo cáo',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

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
            color: AppColors.background,
            child: CustomBottomNavigationBar(
              currentIndex: _selectedBottomIndex,
              onTap: _onBottomNavTap,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
