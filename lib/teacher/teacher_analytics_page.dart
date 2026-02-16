import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TeacherAnalyticsPage extends StatefulWidget {
  const TeacherAnalyticsPage({super.key});

  @override
  State<TeacherAnalyticsPage> createState() => _TeacherAnalyticsPageState();
}

class _TeacherAnalyticsPageState extends State<TeacherAnalyticsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedPeriod = 'Daily'; // Daily, Weekly, Monthly
  bool _isLoading = true;

  // Analytics Data
  int _totalStudents = 0;
  int _activeUsers = 0;
  double _quizPerformance = 0.0;
  double _completionRate = 0.0;

  // Charts Data
  Map<String, int> _userActivityData = {};
  Map<String, double> _subjectPerformance = {};
  Map<String, double> _courseProgress = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await Future.wait([
        _loadStudentStats(),
        _loadUserActivity(),
        _loadQuizPerformance(),
        _loadCourseProgress(),
      ]);
    } catch (e) {
      debugPrint('❌ Error loading analytics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load Total Students and Active Users
  Future<void> _loadStudentStats() async {
    try {
      // Get all students
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      _totalStudents = studentsSnapshot.docs.length;

      // Get active users (students who have attempted quizzes in last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentAttemptsSnapshot = await _firestore
          .collection('quiz_attempts')
          .where('submittedAt', isGreaterThan: sevenDaysAgo)
          .get();

      Set<String> activeStudentIds = {};
      for (var doc in recentAttemptsSnapshot.docs) {
        final data = doc.data();
        if (data['studentId'] != null) {
          activeStudentIds.add(data['studentId']);
        }
      }

      _activeUsers = activeStudentIds.length;

      debugPrint('📊 Total Students: $_totalStudents');
      debugPrint('📊 Active Users: $_activeUsers');
    } catch (e) {
      debugPrint('❌ Error loading student stats: $e');
    }
  }

  /// Load User Activity Data (Last 7 days)
  Future<void> _loadUserActivity() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Get quiz attempts from last 7 days
      final attemptsSnapshot = await _firestore
          .collection('quiz_attempts')
          .where('submittedAt', isGreaterThan: sevenDaysAgo)
          .get();

      // Initialize data for last 7 days
      Map<String, int> activityMap = {};
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = _getDayName(date.weekday);
        activityMap[dayName] = 0;
      }

      // Count attempts per day
      for (var doc in attemptsSnapshot.docs) {
        final data = doc.data();
        if (data['submittedAt'] != null) {
          DateTime attemptDate;
          if (data['submittedAt'] is Timestamp) {
            attemptDate = (data['submittedAt'] as Timestamp).toDate();
          } else {
            continue;
          }

          final dayName = _getDayName(attemptDate.weekday);
          if (activityMap.containsKey(dayName)) {
            activityMap[dayName] = (activityMap[dayName] ?? 0) + 1;
          }
        }
      }

      setState(() {
        _userActivityData = activityMap;
      });

      debugPrint('📊 User Activity Data: $_userActivityData');
    } catch (e) {
      debugPrint('❌ Error loading user activity: $e');
    }
  }

  /// Load Quiz Performance by Subject
  Future<void> _loadQuizPerformance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get teacher's assigned grades
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      List<String> assignedGrades = [];

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data?.containsKey('assignedGrades') == true) {
          final gradesData = data!['assignedGrades'];
          if (gradesData is List) {
            assignedGrades = gradesData.map((g) => g.toString()).toList();
          }
        }
      }

      // Get quizzes created by this teacher
      final quizzesSnapshot = await _firestore
          .collection('quizzes')
          .where('teacherId', isEqualTo: user.uid)
          .get();

      Map<String, List<double>> subjectScores = {
        'Math': [],
        'Science': [],
        'English': [],
        'History': [],
      };

      double totalScore = 0;
      int totalAttempts = 0;

      // Get quiz attempts for teacher's quizzes
      for (var quizDoc in quizzesSnapshot.docs) {
        final quizId = quizDoc.id;
        final quizData = quizDoc.data();
        final subject = (quizData['subject'] as String?) ?? 'Other';

        final attemptsSnapshot = await _firestore
            .collection('quiz_attempts')
            .where('quizId', isEqualTo: quizId)
            .get();

        for (var attemptDoc in attemptsSnapshot.docs) {
          final attemptData = attemptDoc.data();
          final score = (attemptData['score'] as num?)?.toDouble() ?? 0.0;
          final totalQuestions =
              (attemptData['totalQuestions'] as num?)?.toInt() ?? 1;

          final percentage = (score / totalQuestions) * 100;

          // Add to subject scores
          if (subjectScores.containsKey(subject)) {
            subjectScores[subject]!.add(percentage);
          }

          totalScore += percentage;
          totalAttempts++;
        }
      }

      // Calculate average for each subject
      Map<String, double> averageScores = {};
      subjectScores.forEach((subject, scores) {
        if (scores.isNotEmpty) {
          final avg = scores.reduce((a, b) => a + b) / scores.length;
          averageScores[subject] = avg;
        }
      });

      // Calculate overall quiz performance
      _quizPerformance = totalAttempts > 0 ? totalScore / totalAttempts : 0.0;

      setState(() {
        _subjectPerformance = averageScores;
      });

      debugPrint('📊 Subject Performance: $_subjectPerformance');
      debugPrint('📊 Overall Quiz Performance: $_quizPerformance%');
    } catch (e) {
      debugPrint('❌ Error loading quiz performance: $e');
    }
  }

  /// Load Course Completion Progress
  Future<void> _loadCourseProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get teacher's quizzes grouped by subject
      final quizzesSnapshot = await _firestore
          .collection('quizzes')
          .where('teacherId', isEqualTo: user.uid)
          .get();

      Map<String, int> totalQuizzesBySubject = {};
      Map<String, Set<String>> completedStudentsBySubject = {};

      for (var quizDoc in quizzesSnapshot.docs) {
        final quizData = quizDoc.data();
        final subject = (quizData['subject'] as String?) ?? 'Other';
        final quizId = quizDoc.id;

        // Count total quizzes per subject
        totalQuizzesBySubject[subject] =
            (totalQuizzesBySubject[subject] ?? 0) + 1;

        // Get completed attempts for this quiz
        final attemptsSnapshot = await _firestore
            .collection('quiz_attempts')
            .where('quizId', isEqualTo: quizId)
            .get();

        if (!completedStudentsBySubject.containsKey(subject)) {
          completedStudentsBySubject[subject] = {};
        }

        for (var attemptDoc in attemptsSnapshot.docs) {
          final attemptData = attemptDoc.data();
          final studentId = attemptData['studentId'] as String?;
          if (studentId != null) {
            completedStudentsBySubject[subject]!.add(studentId);
          }
        }
      }

      // Calculate completion percentage for each subject
      Map<String, double> completionPercentages = {};
      totalQuizzesBySubject.forEach((subject, totalQuizzes) {
        final studentsCompleted =
            completedStudentsBySubject[subject]?.length ?? 0;
        // Calculate based on average completion across all students
        final percentage = _totalStudents > 0
            ? (studentsCompleted / _totalStudents) * 100
            : 0.0;
        completionPercentages[subject] = percentage > 100 ? 100 : percentage;
      });

      // Calculate overall completion rate
      if (completionPercentages.isNotEmpty) {
        final totalCompletion =
            completionPercentages.values.reduce((a, b) => a + b);
        _completionRate = totalCompletion / completionPercentages.length;
      }

      setState(() {
        _courseProgress = completionPercentages;
      });

      debugPrint('📊 Course Progress: $_courseProgress');
      debugPrint('📊 Overall Completion Rate: $_completionRate%');
    } catch (e) {
      debugPrint('❌ Error loading course progress: $e');
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalyticsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(),
                    const SizedBox(height: 24),

                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),

                    // Stats Cards
                    _buildStatsCards(),
                    const SizedBox(height: 24),

                    // User Activity Chart
                    _buildUserActivityChart(),
                    const SizedBox(height: 24),

                    // Quiz Performance by Subject
                    _buildQuizPerformanceChart(),
                    const SizedBox(height: 24),

                    // Course Completion Progress
                    _buildCourseProgressSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 32,
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
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
          _loadAnalyticsData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF3B82F6),
            value: _totalStudents.toString(),
            label: 'Total Students',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.person_add_alt_1,
            iconColor: const Color(0xFF10B981),
            value: _activeUsers.toString(),
            label: 'Active Users',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivityChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _userActivityData.isEmpty
                ? const Center(
                    child: Text(
                      'No activity data available',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                : LineChart(
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
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 20,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B7280),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = _userActivityData.keys.toList();
                              if (value.toInt() >= 0 &&
                                  value.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[value.toInt()],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_userActivityData.length - 1).toDouble(),
                      minY: 0,
                      maxY: 80,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _userActivityData.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((e) {
                            return FlSpot(
                                e.key.toDouble(), e.value.value.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF3B82F6),
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: const Color(0xFF3B82F6),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                'Quiz Performance by Subject',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 16,
                      color: Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_quizPerformance.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _subjectPerformance.isEmpty
                ? const Center(
                    child: Text(
                      'No quiz performance data available',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 25,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B7280),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final subjects =
                                  _subjectPerformance.keys.toList();
                              if (value.toInt() >= 0 &&
                                  value.toInt() < subjects.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    subjects[value.toInt()],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
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
                      borderData: FlBorderData(show: false),
                      barGroups: _subjectPerformance.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value,
                              color: const Color(0xFF3B82F6),
                              width: 40,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                'Course Completion Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.track_changes,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_completionRate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _courseProgress.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No course progress data available',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              : Column(
                  children: _courseProgress.entries.map((entry) {
                    Color progressColor;
                    switch (entry.key) {
                      case 'Mathematics':
                        progressColor = const Color(0xFF3B82F6);
                        break;
                      case 'Science':
                        progressColor = const Color(0xFF10B981);
                        break;
                      case 'English':
                        progressColor = const Color(0xFF8B5CF6);
                        break;
                      case 'History':
                        progressColor = const Color(0xFFF59E0B);
                        break;
                      default:
                        progressColor = const Color(0xFF6B7280);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                '${entry.value.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: entry.value / 100,
                              backgroundColor:
                                  progressColor.withValues(alpha: 0.2),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(progressColor),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
