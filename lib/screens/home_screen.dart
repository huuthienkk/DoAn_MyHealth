import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'health_screen.dart';
import 'mood_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  String _email = '';
  String _username = 'Người dùng';
  String _currentMood = 'Bình thường';
  bool _isLoading = false;
  int _steps = 3500;

  // Add new state variables
  final List<String> _healthTips = [
    'Uống đủ 2 lít nước mỗi ngày',
    'Tập thể dục 30 phút mỗi ngày',
    'Ngủ đủ 7-8 tiếng mỗi ngày',
    'Ăn nhiều rau xanh và trái cây',
  ];

  int _selectedTipIndex = 0;
  bool _hasAchievedDailyGoal = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startTipRotation();
  }

  void _startTipRotation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _selectedTipIndex = (_selectedTipIndex + 1) % _healthTips.length;
        });
        _startTipRotation();
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authController.getUserProfile(); // có thể trả về null
      if (!mounted) return;
      setState(() {
        _email = (data != null && data['email'] != null)
            ? data['email'] as String
            : '';
        _username = (data != null && data['username'] != null)
            ? data['username'] as String
            : 'Người dùng';
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Không tải được dữ liệu: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      // Giả lập việc tải dữ liệu
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _steps = _steps + 100; // Giả lập cập nhật số bước
      });
    } catch (e) {
      _showError('Không thể cập nhật dữ liệu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _logout() async {
    try {
      await _authController.logout();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _showError('Không thể đăng xuất: $e');
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _isLoading ? 0.5 : 1.0,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Stack(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, size: 30, color: color),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.teal,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: Text('Chào, $_username', style: const TextStyle(fontSize: 20)),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Tip Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.teal[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates,
                        color: Colors.teal,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            _healthTips[_selectedTipIndex],
                            key: ValueKey(_selectedTipIndex),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Daily Progress
              Text(
                'Mục tiêu hôm nay',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _steps / 10000, // Assuming 10000 steps is the daily goal
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _steps >= 10000 ? Colors.green : Colors.orange,
                ),
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_steps / 10000 * 100).toInt()}% của mục tiêu',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Stat cards with new design
              _buildStatCard(
                'Bước hôm nay',
                '$_steps/10000',
                Icons.directions_walk,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Tâm trạng',
                _currentMood,
                Icons.mood,
                Colors.purple,
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Truy cập nhanh',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildNavigationButton('Sức khỏe', Icons.dashboard, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthScreen(),
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  _buildNavigationButton('Mood', Icons.mood, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MoodScreen(),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Achievements Section
              if (_hasAchievedDailyGoal)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.green[100],
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.green, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Chúc mừng! Bạn đã đạt mục tiêu hôm nay',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement quick add health data
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
