import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/mood_controller.dart';
import '../models/mood_model.dart';
import 'package:intl/intl.dart';

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
        backgroundColor: Colors.redAccent,
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
    final gradientColors = [const Color(0xFF6A11CB), const Color(0xFF2575FC)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi tâm trạng'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadMood,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Theo dõi tâm trạng',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Card nhập tâm trạng
                  Card(
                    color: Colors.white.withValues(alpha: 0.9),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bạn cảm thấy thế nào hôm nay?',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _moodIcons.entries.map((entry) {
                              final isSelected = _selectedMood == entry.key;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? gradientColors[1]
                                          .withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? gradientColors[1]
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedMood = entry.key),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    children: [
                                      Icon(
                                        entry.value,
                                        size: 42,
                                        color: isSelected
                                            ? gradientColors[0]
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(entry.key),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Mức độ stress (1–10)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Thư giãn'),
                              Text('Căng thẳng'),
                            ],
                          ),
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
                              label: '$_stress',
                              onChanged: (val) =>
                                  setState(() => _stress = val.toInt()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _noteCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Ghi chú cảm xúc',
                              hintText: 'Bạn muốn chia sẻ điều gì không?',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveMood,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: gradientColors[0],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
                                      'LƯU TÂM TRẠNG',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lịch sử tâm trạng
                  Text(
                    'Lịch sử tâm trạng gần đây',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else if (_history.isEmpty)
                    Center(
                      child: Text(
                        'Chưa có dữ liệu tâm trạng nào.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final data = _history[index];
                        return Card(
                          color: Colors.white.withValues(alpha: 0.9),
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Icon(
                              _moodIcons[data.mood] ?? Icons.mood,
                              size: 36,
                              color: gradientColors[0],
                            ),
                            title: Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(data.date),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text('Tâm trạng: ${data.mood}',
                                    style: const TextStyle(fontSize: 14)),
                                Text(
                                  'Stress: ${data.stressLevel}',
                                  style: TextStyle(
                                    color: _getStressColor(data.stressLevel),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (data.note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      data.note,
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),
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
