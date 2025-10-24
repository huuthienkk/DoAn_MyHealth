import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/mood_controller.dart';
import '../models/mood_model.dart';
import 'package:intl/intl.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({Key? key}) : super(key: key);

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

  final Map<String, IconData> _moodIcons = {
    'Vui': Icons.sentiment_very_satisfied,
    'Bình thường': Icons.sentiment_neutral,
    'Buồn': Icons.sentiment_very_dissatisfied,
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveMood() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu tâm trạng thành công!'),
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

  Color _getStressColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 7) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Theo dõi tâm trạng'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMood),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMood,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
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
                        'Bạn cảm thấy thế nào?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _moodIcons.entries.map((entry) {
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedMood = entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedMood == entry.key
                                    ? Colors.teal.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    entry.value,
                                    size: 40,
                                    color: _selectedMood == entry.key
                                        ? Colors.teal
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(entry.key),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Mức độ stress (1-10):',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _getStressColor(_stress),
                          thumbColor: _getStressColor(_stress),
                        ),
                        child: Slider(
                          value: _stress.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: 'Stress: $_stress',
                          onChanged: (val) =>
                              setState(() => _stress = val.toInt()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Ghi chú',
                          hintText: 'Bạn muốn chia sẻ điều gì không?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _saveMood,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'LƯU TÂM TRẠNG',
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
                'Lịch sử tâm trạng',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.teal[900]),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final data = _history[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        _moodIcons[data.mood] ?? Icons.mood,
                        size: 32,
                        color: Colors.teal,
                      ),
                      title: Row(
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(data.date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStressColor(
                                data.stressLevel,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Stress: ${data.stressLevel}',
                              style: TextStyle(
                                color: _getStressColor(data.stressLevel),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: data.note.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(data.note),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }
}
