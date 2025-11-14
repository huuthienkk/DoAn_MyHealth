import 'package:flutter/material.dart';
import '../controllers/health_controller.dart';
import '../models/health_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/charts/health_chart.dart';
import '../services/notification_service.dart';
import '../widgets/common/bottom_navigation_bar.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/empty_state.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'mood_screen.dart';
import 'food_recognizer_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _controller = HealthController();
  final _stepsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _sleepCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _systolicBPCtrl = TextEditingController();
  final _diastolicBPCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _waterIntakeCtrl = TextEditingController();
  final _caloriesInCtrl = TextEditingController();
  final _caloriesOutCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  List<HealthData> _healthData = [];
  bool _showAdvancedFields = false;

  // Nhắc nhở uống nước
  int _selectedInterval = 0;
  final List<int> _intervalOptions = [0, 30, 45, 60];
  int _selectedBottomIndex = 1; // Index 1 cho Sức khỏe

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      _healthData = await _controller.getHealthData(uid);
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

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final data = HealthData(
        date: DateTime.now(),
        steps: int.tryParse(_stepsCtrl.text) ?? 0,
        weight: double.tryParse(_weightCtrl.text) ?? 0,
        sleepHours: double.tryParse(_sleepCtrl.text) ?? 0,
        height: _heightCtrl.text.isNotEmpty
            ? double.tryParse(_heightCtrl.text)
            : null,
        systolicBP: _systolicBPCtrl.text.isNotEmpty
            ? int.tryParse(_systolicBPCtrl.text)
            : null,
        diastolicBP: _diastolicBPCtrl.text.isNotEmpty
            ? int.tryParse(_diastolicBPCtrl.text)
            : null,
        heartRate: _heartRateCtrl.text.isNotEmpty
            ? int.tryParse(_heartRateCtrl.text)
            : null,
        waterIntake: _waterIntakeCtrl.text.isNotEmpty
            ? double.tryParse(_waterIntakeCtrl.text)
            : null,
        caloriesIn: _caloriesInCtrl.text.isNotEmpty
            ? double.tryParse(_caloriesInCtrl.text)
            : null,
        caloriesOut: _caloriesOutCtrl.text.isNotEmpty
            ? double.tryParse(_caloriesOutCtrl.text)
            : null,
      );
      await _controller.addHealthData(uid, data);
      _clearAllFields();
      await _loadData();

      if (!mounted) return;
      _showSuccess('Đã lưu dữ liệu thành công!');
    } catch (e) {
      _showError('Không thể lưu dữ liệu: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _clearAllFields() {
    _stepsCtrl.clear();
    _weightCtrl.clear();
    _sleepCtrl.clear();
    _heightCtrl.clear();
    _systolicBPCtrl.clear();
    _diastolicBPCtrl.clear();
    _heartRateCtrl.clear();
    _waterIntakeCtrl.clear();
    _caloriesInCtrl.clear();
    _caloriesOutCtrl.clear();
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập $fieldName';
    if (double.tryParse(value) == null) return '$fieldName phải là số';
    return null;
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });

    switch (index) {
      case 0: // Trang chủ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1: // Sức khỏe (current screen)
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

  Widget _buildNotificationCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h4.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Kích hoạt',
            onPressed: onPressed,
            backgroundColor: color,
            height: 44,
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
        title: 'Giám sát sức khỏe',
        centerTitle: true,
        onBackPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        actions: [
          AppIconButton(
            icon: Icons.refresh,
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Biểu đồ sức khỏe
                    if (_healthData.isNotEmpty)
                      AppCard(
                        child: HealthChart(
                          data: _healthData,
                          title: 'Số bước chân 7 ngày qua',
                          lineColor: AppColors.primary,
                        ),
                      ),
                    if (_healthData.isNotEmpty)
                      const SizedBox(height: AppSpacing.md),

                    // Form nhập liệu
                    AppCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thêm dữ liệu mới', style: AppTextStyles.h4),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _stepsCtrl,
                              labelText: 'Số bước chân',
                              prefixIcon: Icons.directions_walk,
                              iconColor: AppColors.steps,
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  _validateNumber(value, 'Số bước chân'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _weightCtrl,
                              labelText: 'Cân nặng (kg)',
                              prefixIcon: Icons.monitor_weight,
                              iconColor: AppColors.weight,
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  _validateNumber(value, 'Cân nặng'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _sleepCtrl,
                              labelText: 'Giờ ngủ',
                              prefixIcon: Icons.bedtime,
                              iconColor: AppColors.sleep,
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  _validateNumber(value, 'Giờ ngủ'),
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Nút hiển thị thêm trường
                            InkWell(
                              onTap: () {
                                setState(() =>
                                    _showAdvancedFields = !_showAdvancedFields);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _showAdvancedFields
                                        ? 'Ẩn các trường nâng cao'
                                        : 'Hiển thị thêm trường',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Icon(
                                    _showAdvancedFields
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),

                            // Các trường nâng cao
                            if (_showAdvancedFields) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _heightCtrl,
                                labelText: 'Chiều cao (cm)',
                                prefixIcon: Icons.height,
                                iconColor: AppColors.info,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _systolicBPCtrl,
                                      labelText: 'Huyết áp tâm thu',
                                      prefixIcon: Icons.favorite,
                                      iconColor: AppColors.error,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _diastolicBPCtrl,
                                      labelText: 'Huyết áp tâm trương',
                                      prefixIcon: Icons.favorite_border,
                                      iconColor: AppColors.error,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _heartRateCtrl,
                                labelText: 'Nhịp tim (bpm)',
                                prefixIcon: Icons.favorite,
                                iconColor: AppColors.error,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _waterIntakeCtrl,
                                labelText: 'Lượng nước (ml)',
                                prefixIcon: Icons.water_drop,
                                iconColor: AppColors.water,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _caloriesInCtrl,
                                      labelText: 'Calo nạp vào',
                                      prefixIcon: Icons.restaurant,
                                      iconColor: AppColors.warning,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _caloriesOutCtrl,
                                      labelText: 'Calo tiêu thụ',
                                      prefixIcon: Icons.local_fire_department,
                                      iconColor: AppColors.warning,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              text: 'LƯU DỮ LIỆU',
                              onPressed: _loading ? null : _saveData,
                              isLoading: _loading,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Cài đặt nhắc nhở uống nước
                    AppCard(
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
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child: const Icon(
                                  Icons.water_drop,
                                  color: AppColors.water,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  '💧 Nhắc uống nước',
                                  style: AppTextStyles.h4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Chọn tần suất nhắc uống nước:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedInterval,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            items: _intervalOptions
                                .map(
                                  (val) => DropdownMenuItem<int>(
                                    value: val,
                                    child: Text(
                                      val == 0
                                          ? 'Tắt nhắc nhở'
                                          : 'Mỗi $val phút',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) async {
                              setState(() => _selectedInterval = val ?? 0);
                              if (val != null && val > 0) {
                                await NotificationService.instance
                                    .scheduleWaterReminders(val);
                                if (mounted) {
                                  _showSuccess(
                                      'Đã bật nhắc uống nước mỗi $val phút');
                                }
                              } else {
                                await NotificationService.instance
                                    .showInstantNotification(
                                  '💧 Nhắc uống nước',
                                  'Đã tắt nhắc nhở.',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Các tính năng nhắc nhở khác
                    _buildNotificationCard(
                      '😴 Nhắc ngủ đúng giờ',
                      'Nhắc bạn đi ngủ lúc 22:00 mỗi ngày',
                      Icons.nightlight_round,
                      AppColors.weight,
                      () async {
                        await NotificationService.instance
                            .scheduleSleepReminder(22);
                        if (mounted) {
                          _showSuccess('Đã đặt nhắc ngủ lúc 22:00 mỗi ngày');
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _buildNotificationCard(
                      '🚶 Nhắc vận động',
                      'Nhắc bạn vận động mỗi 2 giờ trong giờ làm việc',
                      Icons.directions_walk,
                      AppColors.steps,
                      () async {
                        await NotificationService.instance
                            .scheduleMoveReminders(120);
                        if (mounted) {
                          _showSuccess('Đã đặt nhắc vận động mỗi 2 giờ');
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _buildNotificationCard(
                      '😊 Nhắc ghi tâm trạng',
                      'Nhắc bạn ghi lại cảm xúc vào buổi sáng và tối',
                      Icons.mood,
                      AppColors.primary,
                      () async {
                        await NotificationService.instance
                            .scheduleMoodReminders();
                        if (mounted) {
                          _showSuccess('Đã đặt nhắc ghi tâm trạng (9h & 20h)');
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Lịch sử giám sát
                    SectionHeader(title: 'Lịch sử giám sát'),
                    const SizedBox(height: AppSpacing.md),

                    // Danh sách dữ liệu
                    _healthData.isEmpty
                        ? EmptyState(
                            icon: Icons.health_and_safety,
                            title: 'Chưa có dữ liệu sức khỏe',
                            message: 'Hãy thêm dữ liệu mới để bắt đầu theo dõi',
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _healthData.length,
                            itemBuilder: (context, index) {
                              final data = _healthData[index];
                              return AppCard(
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    DateFormat('dd/MM/yyyy').format(data.date),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: AppSpacing.xs),
                                      _buildDataRow(
                                        Icons.directions_walk,
                                        '${data.steps} bước',
                                        AppColors.steps,
                                      ),
                                      _buildDataRow(
                                        Icons.monitor_weight,
                                        '${data.weight} kg',
                                        AppColors.weight,
                                      ),
                                      _buildDataRow(
                                        Icons.bedtime,
                                        '${data.sleepHours.toStringAsFixed(1)} giờ',
                                        AppColors.sleep,
                                      ),
                                      if (data.height != null)
                                        _buildDataRow(
                                          Icons.height,
                                          '${data.height!.toStringAsFixed(0)} cm',
                                          AppColors.info,
                                        ),
                                      if (data.systolicBP != null &&
                                          data.diastolicBP != null)
                                        _buildDataRow(
                                          Icons.favorite,
                                          '${data.systolicBP}/${data.diastolicBP} mmHg',
                                          AppColors.error,
                                        ),
                                      if (data.heartRate != null)
                                        _buildDataRow(
                                          Icons.favorite,
                                          '${data.heartRate} bpm',
                                          AppColors.error,
                                        ),
                                      if (data.waterIntake != null)
                                        _buildDataRow(
                                          Icons.water_drop,
                                          '${data.waterIntake!.toStringAsFixed(0)} ml',
                                          AppColors.water,
                                        ),
                                      if (data.caloriesIn != null ||
                                          data.caloriesOut != null)
                                        _buildDataRow(
                                          Icons.local_fire_department,
                                          'Nạp: ${data.caloriesIn ?? 0} | Tiêu: ${data.caloriesOut ?? 0}',
                                          AppColors.warning,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    // Thêm khoảng trống phía dưới
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation
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

  Widget _buildDataRow(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stepsCtrl.dispose();
    _weightCtrl.dispose();
    _sleepCtrl.dispose();
    _heightCtrl.dispose();
    _systolicBPCtrl.dispose();
    _diastolicBPCtrl.dispose();
    _heartRateCtrl.dispose();
    _waterIntakeCtrl.dispose();
    _caloriesInCtrl.dispose();
    _caloriesOutCtrl.dispose();
    super.dispose();
  }
}
