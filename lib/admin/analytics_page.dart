import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Selected time period
  String _selectedPeriod = 'Daily';

  // Real-time data streams
  Stream<QuerySnapshot>? _studentsStream;
  Stream<QuerySnapshot>? _teachersStream;
  Stream<QuerySnapshot>? _quizzesStream;
  Stream<QuerySnapshot>? _activitiesStream;

  // Data variables
  int _totalStudents = 0;
  int _activeUsers = 0;
  int _totalTeachers = 0;
  double _quizPerformance = 0.0;
  double _completionRate = 0.0;

  // User activity data (last 7 days)
  Map<String, int> _userActivityData = {};

  // Matter topics quiz performance
  Map<String, double> _matterTopicPerformance = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeStreams();
    _loadUserActivityData();
    _loadMatterTopicPerformance();
  }

  void _initializeAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  void _initializeStreams() {
    // Stream for students
    _studentsStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots();

    // Stream for teachers
    _teachersStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots();

    // Stream for quizzes
    _quizzesStream =
        FirebaseFirestore.instance.collection('quizzes').snapshots();

    // Stream for recent activities (if you have an activities collection)
    _activitiesStream = FirebaseFirestore.instance
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> _loadUserActivityData() async {
    try {
      // Get the last 7 days of activity
      final now = DateTime.now();
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      Map<String, int> activityData = {};

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = days[date.weekday - 1];

        // Query activities for this day
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final snapshot = await FirebaseFirestore.instance
            .collection('activities')
            .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
            .where('timestamp', isLessThan: endOfDay)
            .get();

        activityData[dayName] = snapshot.docs.length;
      }

      setState(() {
        _userActivityData = activityData;
      });
    } catch (e) {
      print('Error loading activity data: $e');
    }
  }

  Future<void> _loadMatterTopicPerformance() async {
    try {
      // Get all Matter topics
      final topicsSnapshot =
          await FirebaseFirestore.instance.collection('Matter_subtopics').get();

      Map<String, double> performanceMap = {};

      for (var topicDoc in topicsSnapshot.docs) {
        final topicId = topicDoc.id;
        final topicData = topicDoc.data();
        final topicName = topicData['name'] ?? 'Unknown';

        // Get all quiz attempts for this Matter topic
        final attemptsSnapshot = await FirebaseFirestore.instance
            .collection('quiz_attempts')
            .where('matterTopicId', isEqualTo: topicId)
            .get();

        if (attemptsSnapshot.docs.isEmpty) {
          // No attempts yet, set to 0
          performanceMap[topicName] = 0.0;
          continue;
        }

        // Calculate average score for this topic
        double totalScore = 0;
        for (var attemptDoc in attemptsSnapshot.docs) {
          final attemptData = attemptDoc.data();
          totalScore += (attemptData['score'] as num?)?.toDouble() ?? 0.0;
        }

        final averageScore = totalScore / attemptsSnapshot.docs.length;
        performanceMap[topicName] = averageScore;
      }

      setState(() {
        _matterTopicPerformance = performanceMap;
      });

      // Also update overall quiz performance
      if (performanceMap.isNotEmpty) {
        final overallPerformance =
            performanceMap.values.reduce((a, b) => a + b) /
                performanceMap.values.length;
        setState(() {
          _quizPerformance = overallPerformance;
        });
      }
    } catch (e) {
      print('Error loading Matter topic performance: $e');
    }
  }

  Future<void> _calculateQuizPerformance() async {
    try {
      // Get all quiz attempts
      final quizAttempts =
          await FirebaseFirestore.instance.collection('quiz_attempts').get();

      if (quizAttempts.docs.isEmpty) {
        setState(() {
          _quizPerformance = 0.0;
        });
        return;
      }

      double totalScore = 0;
      for (var doc in quizAttempts.docs) {
        final data = doc.data();
        totalScore += (data['score'] as num?)?.toDouble() ?? 0.0;
      }

      setState(() {
        _quizPerformance = (totalScore / quizAttempts.docs.length);
      });
    } catch (e) {
      print('Error calculating quiz performance: $e');
    }
  }

  Future<void> _calculateCompletionRate() async {
    try {
      // Get total enrolled students
      final students = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      if (students.docs.isEmpty) {
        setState(() {
          _completionRate = 0.0;
        });
        return;
      }

      // Get students who completed at least one course/topic
      final completions = await FirebaseFirestore.instance
          .collection('course_completions')
          .get();

      // Count unique students who completed something
      Set<String> studentsWithCompletions = {};
      for (var doc in completions.docs) {
        studentsWithCompletions.add(doc.data()['userId'] ?? '');
      }

      setState(() {
        _completionRate =
            (studentsWithCompletions.length / students.docs.length) * 100;
      });
    } catch (e) {
      print('Error calculating completion rate: $e');
    }
  }

  void _onPeriodSelected(String period) {
    setState(() {
      _selectedPeriod = period;
    });

    // Reset and replay animations
    _scaleController.reset();
    _scaleController.forward();

    // Reload data based on selected period
    _loadUserActivityData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0EA5E9),
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadUserActivityData();
              _loadMatterTopicPerformance();
              _calculateQuizPerformance();
              _calculateCompletionRate();

              // Replay animations
              _fadeController.reset();
              _scaleController.reset();
              _fadeController.forward();
              _scaleController.forward();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),

                const SizedBox(height: 24),

                // Period Selection
                _buildPeriodSelector(),

                const SizedBox(height: 24),

                // Statistics Cards with real-time data
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildStatisticsCards(),
                ),

                const SizedBox(height: 24),

                // User Activity Chart
                _buildUserActivityChart(),

                const SizedBox(height: 24),

                // Quiz Performance by Matter Topics
                _buildQuizPerformanceChart(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.trending_up,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track user activity and learning progress',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton('Daily'),
        const SizedBox(width: 12),
        _buildPeriodButton('Weekly'),
        const SizedBox(width: 12),
        _buildPeriodButton('Monthly'),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodSelected(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              period,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildRealTimeStatCard(
                icon: Icons.people_outline,
                iconColor: const Color(0xFF0EA5E9),
                label: 'Total Students',
                stream: _studentsStream,
                builder: (snapshot) {
                  if (snapshot.hasData) {
                    _totalStudents = snapshot.data!.docs.length;
                    return _formatNumber(_totalStudents);
                  }
                  return '0';
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRealTimeStatCard(
                icon: Icons.person_add_outlined,
                iconColor: const Color(0xFF10B981),
                label: 'Total Teachers',
                stream: _teachersStream,
                builder: (snapshot) {
                  if (snapshot.hasData) {
                    _totalTeachers = snapshot.data!.docs.length;
                    return _formatNumber(_totalTeachers);
                  }
                  return '0';
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedStatCard(
                icon: Icons.emoji_events_outlined,
                iconColor: const Color(0xFF8B5CF6),
                label: 'Quiz Performance',
                value: '${_quizPerformance.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedStatCard(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFFF59E0B),
                label: 'Completion Rate',
                value: '${_completionRate.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRealTimeStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Stream<QuerySnapshot>? stream,
    required String Function(AsyncSnapshot<QuerySnapshot>) builder,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final value = builder(snapshot);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFE5E7EB),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Opacity(
                opacity: animValue,
                child: Transform.scale(
                  scale: 0.8 + (animValue * 0.2),
                  child: child,
                ),
              );
            },
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivityChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE5E7EB),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 80,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      days.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        (_userActivityData[days[index]] ?? 0).toDouble(),
                      ),
                    ),
                    isCurved: true,
                    color: const Color(0xFF0EA5E9),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF0EA5E9),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizPerformanceChart() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('Matter_subtopics').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0EA5E9),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text('No Matter topics found'),
            ),
          );
        }

        // Get Matter topics
        final matterTopics = snapshot.data!.docs;
        final limitedTopics =
            matterTopics.take(6).toList(); // Show max 6 topics

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quiz Performance by Matter Topics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Color(0xFF0EA5E9),
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => const Color(0xFF1F2937),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final topicData = limitedTopics[groupIndex].data()
                              as Map<String, dynamic>;
                          final topicName = topicData['name'] ?? 'Topic';
                          return BarTooltipItem(
                            '$topicName\n${rod.toY.toInt()}%',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < limitedTopics.length) {
                              final topicData = limitedTopics[value.toInt()]
                                  .data() as Map<String, dynamic>;
                              final topicName = topicData['name'] ??
                                  'Topic ${value.toInt() + 1}';

                              // Truncate long names
                              final displayName = topicName.length > 10
                                  ? '${topicName.substring(0, 10)}...'
                                  : topicName;

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 35,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 25,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: const Color(0xFFE5E7EB),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: List.generate(
                      limitedTopics.length,
                      (index) {
                        final topicData =
                            limitedTopics[index].data() as Map<String, dynamic>;
                        final topicName = topicData['name'] ?? 'Unknown';

                        // Get real performance data from the map, default to 0 if not found
                        final performance =
                            _matterTopicPerformance[topicName] ?? 0.0;

                        return _buildBarGroup(index, performance);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF0EA5E9),
          width: 40,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
