import 'package:flutter/material.dart';
import '../controllers/health_controller.dart';
import '../models/health_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/charts/health_chart.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

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
        backgroundColor: Colors.red,
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
          backgroundColor: Colors.green,
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
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName phải là số';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Giám sát sức khỏe'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Thêm biểu đồ ở đây
                if (_healthData.isNotEmpty)
                  HealthChart(
                    data: _healthData,
                    title: 'Số bước chân 7 ngày qua',
                    lineColor: Colors.teal,
                  ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nhập dữ liệu mới',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _stepsCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Số bước chân',
                                  prefixIcon: const Icon(Icons.directions_walk),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    _validateNumber(value, 'số bước'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _weightCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Cân nặng (kg)',
                                  prefixIcon: const Icon(Icons.monitor_weight),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    _validateNumber(value, 'cân nặng'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _sleepCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Giờ ngủ',
                                  prefixIcon: const Icon(Icons.bedtime),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    _validateNumber(value, 'giờ ngủ'),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _saveData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
                                          style: TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Lịch sử giám sát',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.teal[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _healthData.length,
                        itemBuilder: (context, index) {
                          final data = _healthData[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.teal[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(data.date),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  _buildDataRow(
                                    Icons.directions_walk,
                                    'Số bước:',
                                    '${data.steps}',
                                  ),
                                  _buildDataRow(
                                    Icons.monitor_weight,
                                    'Cân nặng:',
                                    '${data.weight} kg',
                                  ),
                                  _buildDataRow(
                                    Icons.bedtime,
                                    'Giấc ngủ:',
                                    '${data.sleepHours}h',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
