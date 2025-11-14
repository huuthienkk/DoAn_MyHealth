import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../controllers/health_controller.dart';
import '../controllers/mood_controller.dart';
import '../models/health_model.dart';
import '../models/mood_model.dart';
import '../services/report_service.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/bottom_navigation_bar.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'health_screen.dart';
import 'mood_screen.dart';
import 'food_recognizer_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final HealthController _healthController = HealthController();
  final MoodController _moodController = MoodController();
  final ReportService _reportService = ReportService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _loading = false;
  List<HealthData> _healthData = [];
  List<MoodData> _moodData = [];
  int _selectedBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      _healthData = await _healthController.getHealthData(uid);
      _moodData = await _moodController.getMood(uid);
    } catch (e) {
      _showError('Không thể tải dữ liệu: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      await _loadData();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      await _loadData();
    }
  }

  Future<void> _exportToCSV() async {
    setState(() => _loading = true);
    try {
      final healthFile = await _reportService.exportHealthToCSV(
        _healthData,
        _startDate,
        _endDate,
      );
      final moodFile = await _reportService.exportMoodToCSV(
        _moodData,
        _startDate,
        _endDate,
      );

      if (!mounted) return;
      _showSuccess(
        'Đã xuất CSV thành công!\nSức khỏe: ${healthFile.path}\nTâm trạng: ${moodFile.path}',
      );
    } catch (e) {
      _showError('Lỗi xuất CSV: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportToPDF() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final file = await _reportService.generatePDFReport(
        healthData: _healthData,
        moodData: _moodData,
        startDate: _startDate,
        endDate: _endDate,
        userName: user?.displayName ?? user?.email ?? 'Người dùng',
      );

      if (!mounted) return;
      _showSuccess('Đã tạo báo cáo PDF: ${file.path}');
      
      // Mở file
      await OpenFile.open(file.path);
    } catch (e) {
      _showError('Lỗi tạo PDF: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HealthScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MoodScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FoodRecognizerScreen()),
        );
        break;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: AppTextStyles.h4.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHealth = _healthData.where((d) {
      return d.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          d.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Filtered mood data (có thể dùng sau)
    // final filteredMood = _moodData.where((d) {
    //   return d.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
    //       d.date.isBefore(_endDate.add(const Duration(days: 1)));
    // }).toList();

    final avgSteps = filteredHealth.isNotEmpty
        ? filteredHealth.map((e) => e.steps).reduce((a, b) => a + b) /
            filteredHealth.length
        : 0.0;
    final avgWeight = filteredHealth.isNotEmpty
        ? filteredHealth.map((e) => e.weight).reduce((a, b) => a + b) /
            filteredHealth.length
        : 0.0;
    final avgSleep = filteredHealth.isNotEmpty
        ? filteredHealth.map((e) => e.sleepHours).reduce((a, b) => a + b) /
            filteredHealth.length
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Báo cáo & Xuất dữ liệu',
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Chọn khoảng thời gian
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Khoảng thời gian', style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectStartDate,
                                child: AppCard(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  backgroundColor: AppColors.background,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Từ ngày',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_startDate),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: InkWell(
                                onTap: _selectEndDate,
                                child: AppCard(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  backgroundColor: AppColors.background,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Đến ngày',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_endDate),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Thống kê tổng quan
                  Text('Thống kê tổng quan', style: AppTextStyles.h4),
                  const SizedBox(height: AppSpacing.md),
                  _buildStatCard(
                    'Số bước trung bình',
                    avgSteps.toStringAsFixed(0),
                    Icons.directions_walk,
                    AppColors.steps,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatCard(
                    'Cân nặng trung bình',
                    '${avgWeight.toStringAsFixed(1)} kg',
                    Icons.monitor_weight,
                    AppColors.weight,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatCard(
                    'Giờ ngủ trung bình',
                    '${avgSleep.toStringAsFixed(1)} giờ',
                    Icons.bedtime,
                    AppColors.sleep,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Xuất dữ liệu
                  Text('Xuất dữ liệu', style: AppTextStyles.h4),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: 'XUẤT CSV',
                    onPressed: _loading ? null : _exportToCSV,
                    isLoading: _loading,
                    icon: Icons.table_chart,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    text: 'XUẤT PDF',
                    onPressed: _loading ? null : _exportToPDF,
                    isLoading: _loading,
                    icon: Icons.picture_as_pdf,
                    backgroundColor: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
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
    );
  }
}

