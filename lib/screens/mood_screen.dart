import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/mood_controller.dart';
import '../models/mood_model.dart';
import 'package:intl/intl.dart';
import '../widgets/common/bottom_navigation_bar.dart';
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
      'color': Colors.green,
      'emoji': '😊'
    },
    'Bình thường': {
      'icon': Icons.sentiment_neutral,
      'color': Colors.blue,
      'emoji': '😐'
    },
    'Buồn': {
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.orange,
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

  Color _getStressColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 7) return Colors.orange;
    return Colors.red;
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: moodInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                moodInfo['icon'],
                color: moodInfo['color'],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tâm trạng hôm nay',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${moodInfo['emoji']} ${latestMood.mood}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mức stress: ${_getStressLabel(latestMood.stressLevel)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getStressColor(latestMood.stressLevel),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
          'Theo dõi tâm trạng',
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
            onPressed: _loadMood,
          ),
        ],
      ),
      body: Column(
        children: [
          // Nội dung chính có thể cuộn
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMood,
              color: const Color(0xFF2575FC),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Thống kê tâm trạng hôm nay
                    _buildMoodStats(),
                    if (_history.isNotEmpty) const SizedBox(height: 16),

                    // Card chọn tâm trạng
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
                              'Bạn cảm thấy thế nào?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? moodInfo['color'].withOpacity(0.1)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
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
                                                    .withOpacity(0.2),
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
                                        const SizedBox(height: 8),
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? moodInfo['color']
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          moodInfo['emoji'],
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // Thanh trượt stress level
                            const Text(
                              'Mức độ stress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Thư giãn',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '$_stress - ${_getStressLabel(_stress)}',
                                  style: TextStyle(
                                    color: _getStressColor(_stress),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Căng thẳng',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: _getStressColor(_stress),
                                inactiveTrackColor: Colors.grey[300],
                                thumbColor: _getStressColor(_stress),
                                overlayColor:
                                    _getStressColor(_stress).withAlpha(1),
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
                            const SizedBox(height: 16),

                            // Ghi chú
                            TextFormField(
                              controller: _noteCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Ghi chú cảm xúc',
                                hintText: 'Hãy chia sẻ cảm xúc của bạn...',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              // Cấu hình nâng cao cho tiếng Việt
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.done,
                              enableSuggestions: true,
                              autocorrect: true,
                              enableInteractiveSelection: true,
                              textCapitalization: TextCapitalization.sentences,
                              // Quan trọng: cấu hình input formatters
                              inputFormatters: [],
                            ),
                            const SizedBox(height: 20),

                            // Nút lưu
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveMood,
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
                                        'LƯU TÂM TRẠNG',
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
                    const SizedBox(height: 16),

                    // Lịch sử tâm trạng
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Lịch sử tâm trạng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF2575FC),
                          ),
                        ),
                      )
                    else if (_history.isEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Chưa có dữ liệu tâm trạng nào.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
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

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: moodInfo['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  moodInfo['icon'],
                                  color: moodInfo['color'],
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                DateFormat('dd/MM/yyyy - HH:mm')
                                    .format(data.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${moodInfo['emoji']} ${data.mood}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'Stress: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '${data.stressLevel} - ${_getStressLabel(data.stressLevel)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              _getStressColor(data.stressLevel),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (data.note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      data.note,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
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

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }
}
