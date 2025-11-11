import 'package:flutter/material.dart';
import '../controllers/health_controller.dart';
import '../models/health_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/charts/health_chart.dart';
import '../services/notification_service.dart';
import '../widgets/common/bottom_navigation_bar.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  List<HealthData> _healthData = [];

  // 🟢 Nhắc nhở uống nước
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
        backgroundColor: Colors.redAccent,
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
      );
      await _controller.addHealthData(uid, data);
      _stepsCtrl.clear();
      _weightCtrl.clear();
      _sleepCtrl.clear();
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu dữ liệu thành công!'),
          backgroundColor: Color(0xFF2575FC),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showError('Không thể lưu dữ liệu: $e');
    } finally {
      setState(() => _loading = false);
    }
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

    // Xử lý navigation dựa trên index
    switch (index) {
      case 0: // Trang chủ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1: // Sức khỏe (current screen)
        // Đã ở trang sức khỏe, không cần navigation
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

  Widget _buildNotificationCard(String title, String description, IconData icon,
      Color color, VoidCallback onPressed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Kích hoạt',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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
        title: const Text(
          'Giám sát sức khỏe',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Nội dung chính có thể cuộn
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2575FC),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Biểu đồ sức khỏe
                    if (_healthData.isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: HealthChart(
                            data: _healthData,
                            title: 'Số bước chân 7 ngày qua',
                            lineColor: const Color(0xFF2575FC),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Form nhập liệu
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thêm dữ liệu mới',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                controller: _stepsCtrl,
                                label: 'Số bước chân',
                                icon: Icons.directions_walk,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                controller: _weightCtrl,
                                label: 'Cân nặng (kg)',
                                icon: Icons.monitor_weight,
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                controller: _sleepCtrl,
                                label: 'Giờ ngủ',
                                icon: Icons.bedtime,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _saveData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2575FC),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    elevation: 3,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'LƯU DỮ LIỆU',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cài đặt nhắc nhở
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '💧 Nhắc uống nước',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Chọn tần suất nhắc uống nước:',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _selectedInterval,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
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
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) async {
                                setState(() => _selectedInterval = val ?? 0);
                                if (val != null && val > 0) {
                                  await NotificationService.instance
                                      .scheduleWaterReminders(val);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã bật nhắc uống nước mỗi $val phút',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                            const Color(0xFF2575FC),
                                      ),
                                    );
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
                    ),
                    const SizedBox(height: 16),

                    // Các tính năng nhắc nhở khác
                    _buildNotificationCard(
                      '😴 Nhắc ngủ đúng giờ',
                      'Nhắc bạn đi ngủ lúc 22:00 mỗi ngày',
                      Icons.nightlight_round,
                      Colors.purple,
                      () async {
                        await NotificationService.instance
                            .scheduleSleepReminder(22);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Đã đặt nhắc ngủ lúc 22:00 mỗi ngày'),
                              backgroundColor: Color(0xFF2575FC),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildNotificationCard(
                      '🚶 Nhắc vận động',
                      'Nhắc bạn vận động mỗi 2 giờ trong giờ làm việc',
                      Icons.directions_walk,
                      Colors.orange,
                      () async {
                        await NotificationService.instance
                            .scheduleMoveReminders(120);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đặt nhắc vận động mỗi 2 giờ'),
                              backgroundColor: Color(0xFF2575FC),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildNotificationCard(
                      '😊 Nhắc ghi tâm trạng',
                      'Nhắc bạn ghi lại cảm xúc vào buổi sáng và tối',
                      Icons.mood,
                      Colors.blue,
                      () async {
                        await NotificationService.instance
                            .scheduleMoodReminders();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Đã đặt nhắc ghi tâm trạng (9h & 20h)'),
                              backgroundColor: Color(0xFF2575FC),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lịch sử giám sát
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Lịch sử giám sát',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Danh sách dữ liệu
                    _healthData.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Chưa có dữ liệu sức khỏe',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _healthData.length,
                            itemBuilder: (context, index) {
                              final data = _healthData[index];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF2575FC).withAlpha(1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.calendar_today,
                                        color: Color(0xFF2575FC), size: 20),
                                  ),
                                  title: Text(
                                    DateFormat('dd/MM/yyyy').format(data.date),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      _buildDataRow(Icons.directions_walk,
                                          '${data.steps} bước'),
                                      _buildDataRow(Icons.monitor_weight,
                                          '${data.weight} kg'),
                                      _buildDataRow(Icons.bedtime,
                                          '${data.sleepHours} giờ'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: TextInputType.number,
      validator: (value) => _validateNumber(value, label),
    );
  }

  Widget _buildDataRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stepsCtrl.dispose();
    _weightCtrl.dispose();
    _sleepCtrl.dispose();
    super.dispose();
  }
}
