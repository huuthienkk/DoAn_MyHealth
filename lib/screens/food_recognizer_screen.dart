import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/food_ai_service.dart';
import '../services/food_ai_service_tflite.dart';
import '../widgets/common/bottom_navigation_bar.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/loading_state.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'health_screen.dart';
import 'mood_screen.dart';

class FoodRecognizerScreen extends StatefulWidget {
  const FoodRecognizerScreen({super.key});

  @override
  State<FoodRecognizerScreen> createState() => _FoodRecognizerScreenState();
}

class _FoodRecognizerScreenState extends State<FoodRecognizerScreen> {
  File? _image;
  List<dynamic> _recognitions = [];
  bool _isLoading = false;
  int _selectedBottomIndex = 3; // Index 3 cho AI Calo
  final FoodAIServiceTFLite _tfliteService = FoodAIServiceTFLite();
  bool _useTFLite = true; // Ưu tiên dùng TFLite

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _recognitions = [];
      _isLoading = true;
    });

    try {
      List<dynamic> results;

      // Thử dùng TFLite trước, nếu không được thì fallback về mock
      if (_useTFLite && _tfliteService.isModelLoaded) {
        results = await _tfliteService.predictMultiple(_image!, numResults: 3);
      } else {
        // Fallback về service cũ (mock)
        results = await FoodAIService().predictMultiple(_image!, numResults: 3);
      }

      if (mounted) {
        setState(() {
          _recognitions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi nhận diện: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
      case 2: // Tâm trạng
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MoodScreen()),
        );
        break;
      case 3: // AI Calo (current screen)
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      // Khởi tạo cả 2 service
      await FoodAIService().loadModel();
      await _tfliteService.loadModel();

      // Kiểm tra xem TFLite có load được không
      if (_tfliteService.isModelLoaded) {
        debugPrint('✅ TFLite model loaded successfully');
      } else {
        debugPrint('⚠️ TFLite model not loaded, using mock service');
        _useTFLite = false;
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize AI: $e');
      _useTFLite = false;
    }
  }

  Widget _buildFoodCard(String label, double confidence, int rank,
      {double? calories}) {
    final confidencePercent = (confidence * 100);
    final color = _getConfidenceColor(confidencePercent);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: AppTextStyles.h4.copyWith(color: color),
              ),
              Text(
                '${confidencePercent.toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(color: color),
              ),
            ],
          ),
        ),
        title: Text(
          _formatFoodLabel(label),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (calories != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.local_fire_department,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Khoảng ${calories.toStringAsFixed(0)} calo',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: confidence,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Độ tin cậy: ${confidencePercent.toStringAsFixed(1)}%',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  String _formatFoodLabel(String label) {
    return label.split('_').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).join(' ');
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 70) return AppColors.success;
    if (confidence >= 50) return AppColors.warning;
    return AppColors.error;
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hướng dẫn sử dụng', style: AppTextStyles.h4),
        content: Text(
          '• Chọn ảnh món ăn từ thư viện\n'
          '• AI sẽ phân tích và nhận diện món ăn\n'
          '• Kết quả hiển thị độ tin cậy từ cao đến thấp\n'
          '• Màu xanh: Độ tin cậy cao (>70%)\n'
          '• Màu cam: Độ tin cậy trung bình (50-70%)\n'
          '• Màu đỏ: Độ tin cậy thấp (<50%)',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
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
        title: 'AI Nhận diện thực phẩm',
        centerTitle: true,
        onBackPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        actions: [
          AppIconButton(
            icon: Icons.info_outline,
            onPressed: _showInfoDialog,
            tooltip: 'Hướng dẫn',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Card hướng dẫn
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nhận diện món ăn',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Tải lên ảnh món ăn để AI phân tích và nhận diện',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Hiển thị ảnh
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: _image == null
                          ? EmptyState(
                              icon: Icons.fastfood_rounded,
                              title: 'Chưa có ảnh được chọn',
                              message: 'Chọn ảnh từ thư viện để bắt đầu',
                              iconColor: AppColors.textTertiary,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Image.file(
                                _image!,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Nút chọn ảnh
                  AppButton(
                    text: 'CHỌN ẢNH MÓN ĂN',
                    onPressed: _isLoading ? null : _pickImage,
                    isLoading: _isLoading,
                    icon: Icons.photo_library,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Hiển thị kết quả
                  if (_isLoading)
                    AppCard(
                      child: LoadingState(
                        message: 'AI đang phân tích hình ảnh...',
                      ),
                    ),

                  if (_recognitions.isNotEmpty) ...[
                    SectionHeader(title: 'Kết quả nhận diện'),
                    const SizedBox(height: AppSpacing.md),
                    Column(
                      children: _recognitions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final recognition = entry.value;
                        final confidence = recognition['confidence'] ?? 0.0;
                        final calories = recognition['calories']?.toDouble();
                        return _buildFoodCard(
                          recognition['label']?.toString() ?? 'Unknown',
                          confidence,
                          index + 1,
                          calories: calories,
                        );
                      }).toList(),
                    ),
                  ],

                  if (_recognitions.isEmpty && !_isLoading && _image != null)
                    EmptyState(
                      icon: Icons.search_off,
                      title: 'Không nhận diện được món ăn',
                      message: 'Hãy thử với ảnh rõ hơn hoặc món ăn khác',
                      iconColor: AppColors.textTertiary,
                    ),

                  // Thêm khoảng trống phía dưới
                  const SizedBox(height: 80),
                ],
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
    FoodAIService().closeModel();
    _tfliteService.closeModel();
    super.dispose();
  }
}
