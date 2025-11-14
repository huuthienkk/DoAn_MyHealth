import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/profile_model.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/bottom_navigation_bar.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'health_screen.dart';
import 'mood_screen.dart';
import 'food_recognizer_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _medicalHistoryCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();

  String? _selectedGender;
  File? _avatarFile;
  String? _avatarUrl;
  bool _loading = false;
  bool _biometricEnabled = false;
  int _selectedBottomIndex = 0;

  final List<String> _genders = ['Nam', 'Nữ', 'Khác'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load từ Firestore (cần implement getUserProfile trong FirebaseService)
      // Tạm thời load từ Auth
      setState(() {
        _nameCtrl.text = user.displayName ?? '';
        _avatarUrl = user.photoURL;
      });
    } catch (e) {
      debugPrint('❌ Load profile error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _avatarFile = File(picked.path);
    });
  }

  Future<String?> _uploadAvatar() async {
    if (_avatarFile == null) return _avatarUrl;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${user.uid}.jpg');

      await ref.putFile(_avatarFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Upload avatar error: $e');
      return _avatarUrl;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload avatar nếu có
      final avatarUrl = await _uploadAvatar();

      // Tạo profile
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        avatarUrl: avatarUrl,
        age: _ageCtrl.text.isNotEmpty ? int.tryParse(_ageCtrl.text) : null,
        gender: _selectedGender,
        height: _heightCtrl.text.isNotEmpty
            ? double.tryParse(_heightCtrl.text)
            : null,
        targetWeight: _targetWeightCtrl.text.isNotEmpty
            ? double.tryParse(_targetWeightCtrl.text)
            : null,
        medicalHistory: _medicalHistoryCtrl.text.trim().isEmpty
            ? null
            : _medicalHistoryCtrl.text.trim(),
        currentMedications: _medicationsCtrl.text.trim().isEmpty
            ? null
            : _medicationsCtrl.text.trim(),
        allergies: _allergiesCtrl.text.trim().isEmpty
            ? null
            : _allergiesCtrl.text.trim(),
        biometricEnabled: _biometricEnabled,
        updatedAt: DateTime.now(),
      );

      // Lưu vào Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profile.toMap(), SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã lưu hồ sơ thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Hồ sơ cá nhân',
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar section
                    AppCard(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  backgroundImage: _avatarFile != null
                                      ? FileImage(_avatarFile!)
                                      : (_avatarUrl != null
                                          ? NetworkImage(_avatarUrl!)
                                          : null) as ImageProvider?,
                                  child: _avatarFile == null && _avatarUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Chạm để thay đổi ảnh đại diện',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Thông tin cơ bản
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thông tin cơ bản', style: AppTextStyles.h4),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _nameCtrl,
                            labelText: 'Họ và tên',
                            prefixIcon: Icons.person,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _ageCtrl,
                            labelText: 'Tuổi',
                            prefixIcon: Icons.cake,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Giới tính',
                              prefixIcon: const Icon(Icons.wc),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _genders.map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedGender = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Thông tin sức khỏe
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thông tin sức khỏe', style: AppTextStyles.h4),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _heightCtrl,
                            labelText: 'Chiều cao (cm)',
                            prefixIcon: Icons.height,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _targetWeightCtrl,
                            labelText: 'Cân nặng mục tiêu (kg)',
                            prefixIcon: Icons.monitor_weight,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _medicalHistoryCtrl,
                            labelText: 'Tiền sử bệnh lý',
                            prefixIcon: Icons.medical_services,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _medicationsCtrl,
                            labelText: 'Thuốc đang dùng',
                            prefixIcon: Icons.medication,
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _allergiesCtrl,
                            labelText: 'Dị ứng',
                            prefixIcon: Icons.warning,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Cài đặt
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cài đặt', style: AppTextStyles.h4),
                          const SizedBox(height: AppSpacing.md),
                          SwitchListTile(
                            title: const Text('Xác thực sinh trắc học'),
                            subtitle: const Text('Sử dụng vân tay/Face ID để đăng nhập'),
                            value: _biometricEnabled,
                            onChanged: (value) {
                              setState(() => _biometricEnabled = value);
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Nút lưu
                    AppButton(
                      text: 'LƯU HỒ SƠ',
                      onPressed: _loading ? null : _saveProfile,
                      isLoading: _loading,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _medicalHistoryCtrl.dispose();
    _medicationsCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }
}

