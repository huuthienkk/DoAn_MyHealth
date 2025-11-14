import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/mood_controller.dart';
import '../models/mood_model.dart';
import 'package:intl/intl.dart';
import '../widgets/common/bottom_navigation_bar.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/loading_state.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'health_screen.dart';
import 'food_recognizer_screen.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final MoodController _controller = MoodController();
  final TextEditingController _noteCtrl = TextEditingController();
  String _selectedMood = 'Vui';
  int _stress = 5;
  bool _loading = false;
  List<MoodData> _history = [];
  int _selectedBottomIndex = 2; // Index 2 cho Tâm trạng

  final Map<String, Map<String, dynamic>> _moodData = {
    'Vui': {
      'icon': Icons.sentiment_very_satisfied,
      'color': AppColors.happy,
      'emoji': '😊'
    },
    'Bình thường': {
      'icon': Icons.sentiment_neutral,
      'color': AppColors.neutral,
      'emoji': '😐'
    },
    'Buồn': {
      'icon': Icons.sentiment_very_dissatisfied,
      'color': AppColors.sad,
      'emoji': '😔'
    },
  };

  @override
  void initState() {
    super.initState();
    _loadMood();
  }

  Future<void> _loadMood() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      _history = await _controller.getMood(uid);
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

  Future<void> _saveMood() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final data = MoodData(
        date: DateTime.now(),
        mood: _selectedMood,
        stressLevel: _stress,
        note: _noteCtrl.text.trim(),
      );
      await _controller.addMood(uid, data);
      _noteCtrl.clear();
      await _loadMood();

      if (!mounted) return;
      _showSuccess('Đã lưu tâm trạng thành công!');
    } catch (e) {
      _showError('Không thể lưu dữ liệu: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _getStressColor(int level) {
    if (level <= 3) return AppColors.success;
    if (level <= 7) return AppColors.warning;
    return AppColors.error;
  }

  String _getStressLabel(int level) {
    if (level <= 3) return 'Thư giãn';
    if (level <= 7) return 'Bình thường';
    return 'Căng thẳng';
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
      case 1: // Sức khỏe
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HealthScreen()),
        );
        break;
      case 2: // Tâm trạng (current screen)
        break;
      case 3: // AI Calo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FoodRecognizerScreen()),
        );
        break;
    }
  }

  Widget _buildMoodStats() {
    if (_history.isEmpty) return const SizedBox();

    final today = DateTime.now();
    final todayMoods = _history
        .where((mood) =>
            mood.date.year == today.year &&
            mood.date.month == today.month &&
            mood.date.day == today.day)
        .toList();

    if (todayMoods.isEmpty) return const SizedBox();

    final latestMood = todayMoods.last;
    final moodInfo = _moodData[latestMood.mood] ?? _moodData['Bình thường']!;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: moodInfo['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              moodInfo['icon'],
              color: moodInfo['color'],
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tâm trạng hôm nay',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${moodInfo['emoji']} ${latestMood.mood}',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Mức stress: ${_getStressLabel(latestMood.stressLevel)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _getStressColor(latestMood.stressLevel),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
        title: 'Theo dõi tâm trạng',
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
            onPressed: _loadMood,
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMood,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Thống kê tâm trạng hôm nay
                    _buildMoodStats(),
                    if (_history.isNotEmpty) const SizedBox(height: AppSpacing.md),

                    // Card chọn tâm trạng
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bạn cảm thấy thế nào?', style: AppTextStyles.h4),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _moodData.entries.map((entry) {
                              final isSelected = _selectedMood == entry.key;
                              final moodInfo = entry.value;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedMood = entry.key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? moodInfo['color'].withValues(alpha: 0.1)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(
                                      color: isSelected
                                          ? moodInfo['color']
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: moodInfo['color']
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        moodInfo['icon'],
                                        size: 36,
                                        color: moodInfo['color'],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        entry.key,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? moodInfo['color']
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        moodInfo['emoji'],
                                        style: AppTextStyles.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Thanh trượt stress level
                          Text('Mức độ stress', style: AppTextStyles.h4),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Thư giãn',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$_stress - ${_getStressLabel(_stress)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _getStressColor(_stress),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Căng thẳng',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _getStressColor(_stress),
                              inactiveTrackColor: AppColors.border,
                              thumbColor: _getStressColor(_stress),
                              overlayColor:
                                  _getStressColor(_stress).withValues(alpha: 0.1),
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                            ),
                            child: Slider(
                              value: _stress.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              onChanged: (val) =>
                                  setState(() => _stress = val.toInt()),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Ghi chú
                          AppTextField(
                            controller: _noteCtrl,
                            labelText: 'Ghi chú cảm xúc',
                            hintText: 'Hãy chia sẻ cảm xúc của bạn...',
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Nút lưu
                          AppButton(
                            text: 'LƯU TÂM TRẠNG',
                            onPressed: _saveMood,
                            isLoading: _loading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Lịch sử tâm trạng
                    SectionHeader(title: 'Lịch sử tâm trạng'),
                    const SizedBox(height: AppSpacing.md),

                    if (_loading)
                      const LoadingState(message: 'Đang tải dữ liệu...')
                    else if (_history.isEmpty)
                      EmptyState(
                        icon: Icons.mood,
                        title: 'Chưa có dữ liệu tâm trạng',
                        message: 'Hãy ghi lại cảm xúc của bạn để bắt đầu theo dõi',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final data = _history[index];
                          final moodInfo =
                              _moodData[data.mood] ?? _moodData['Bình thường']!;

                          return AppCard(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: moodInfo['color'].withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(
                                  moodInfo['icon'],
                                  color: moodInfo['color'],
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                DateFormat('dd/MM/yyyy - HH:mm').format(data.date),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${moodInfo['emoji']} ${data.mood}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Text(
                                        'Stress: ',
                                        style: AppTextStyles.caption,
                                      ),
                                      Text(
                                        '${data.stressLevel} - ${_getStressLabel(data.stressLevel)}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: _getStressColor(data.stressLevel),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (data.note.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      data.note,
                                      style: AppTextStyles.caption.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
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

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }
}
