import 'package:flutter/material.dart';
import '../controllers/health_controller.dart';
import '../models/health_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/charts/health_chart.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Giám sát sức khỏe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
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
            onRefresh: _loadData,
            color: const Color(0xFF2575FC),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_healthData.isNotEmpty)
                    Card(
                      elevation: 6,
                      shadowColor: Colors.white.withOpacity(0.2),
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(height: 25),

                  // 🔹 Form nhập liệu
                  Card(
                    elevation: 6,
                    shadowColor: Colors.black26,
                    color: Colors.white.withOpacity(0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Thêm dữ liệu mới',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2575FC),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              controller: _stepsCtrl,
                              label: 'Số bước chân',
                              icon: Icons.directions_walk,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _weightCtrl,
                              label: 'Cân nặng (kg)',
                              icon: Icons.monitor_weight,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _sleepCtrl,
                              label: 'Giờ ngủ',
                              icon: Icons.bedtime,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loading ? null : _saveData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2575FC),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lịch sử giám sát',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Danh sách dữ liệu
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _healthData.length,
                    itemBuilder: (context, index) {
                      final data = _healthData[index];
                      return Card(
                        color: Colors.white.withOpacity(0.95),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF2575FC), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(data.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _buildDataRow(Icons.directions_walk, 'Số bước:',
                                  '${data.steps}'),
                              _buildDataRow(Icons.monitor_weight, 'Cân nặng:',
                                  '${data.weight} kg'),
                              _buildDataRow(Icons.bedtime, 'Giấc ngủ:',
                                  '${data.sleepHours}h'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2575FC)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) => _validateNumber(value, label),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2575FC)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.black87)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black)),
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
