import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'teacher_my_classes_page.dart';
import 'teacher_profile_page.dart';
import 'teacher_quizzes_page.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _teacherName = 'Teacher';
  int _totalClasses = 0;
  int _assignedTopics = 0;
  int _activeStudents = 0;
  int _overallQuizScore = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _quizResults = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  /// Load Teacher Name and Stats from Firebase
  Future<void> _loadTeacherData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('\n🔍 ============ LOADING TEACHER DATA ============');
      debugPrint('Teacher User ID: ${user.uid}');

      // Get teacher's name from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _teacherName = (data?['name'] as String?) ?? 'Teacher';
        });
        debugPrint('📚 Teacher Name: $_teacherName');
      }

      // Load teacher's assigned classes from Firebase
      await _loadAssignedClasses(user.uid);

      // Load quiz results
      await _loadQuizResults(user.uid);
    } catch (e) {
      debugPrint('❌ Error loading teacher data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load Classes Assigned to Teacher
  /// Queries classes where teacherId field matches current teacher's uid
  Future<void> _loadAssignedClasses(String teacherId) async {
    try {
      debugPrint('\n🔍 ============ LOADING CLASSES ============');
      debugPrint('Searching for classes with teacherId: $teacherId');

      // Query classes by teacherId
      final classesSnapshot = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      debugPrint(
          '📋 Found ${classesSnapshot.docs.length} classes assigned to this teacher');

      if (classesSnapshot.docs.isEmpty) {
        debugPrint('⚠️ No classes found with teacherId = $teacherId');
        debugPrint(
            '   Make sure classes in Firebase have a "teacherId" field set to: $teacherId');
      }

      List<Map<String, dynamic>> classList = [];
      int totalStudents = 0;
      Set<String> uniqueTopics = {};

      for (var classDoc in classesSnapshot.docs) {
        final classData = classDoc.data();
        final classId = classDoc.id;

        debugPrint('\n✅ Class found: $classId');
        debugPrint('   Name: ${classData['name']}');
        debugPrint('   Grade: ${classData['grade']}');
        debugPrint('   Section: ${classData['section']}');
        debugPrint('   Topic: ${classData['topic']}');
        debugPrint('   Teacher ID: ${classData['teacherId']}');

        final className = (classData['name'] as String?) ?? 'Unnamed Class';
        final topic = (classData['topic'] as String?) ?? 'No topic assigned';
        final classGrade = (classData['grade'] as String?) ?? 'Unknown Grade';
        final section = (classData['section'] as String?) ?? 'A';

        // Count students in this class
        int studentCount = 0;
        try {
          final studentsSnapshot = await _firestore
              .collection('classes')
              .doc(classId)
              .collection('students')
              .get();
          studentCount = studentsSnapshot.docs.length;
          debugPrint('   Students enrolled: $studentCount');
        } catch (e) {
          debugPrint('   ⚠️ Error counting students: $e');
        }

        totalStudents += studentCount;

        // Track unique topics
        if (topic != 'No topic assigned' && topic.isNotEmpty) {
          uniqueTopics.add(topic);
        }

        classList.add({
          'id': classId,
          'name': className,
          'grade': classGrade,
          'students': studentCount,
          'topic': topic,
          'section': section,
        });
      }

      setState(() {
        _classes = classList;
        _totalClasses = classList.length;
        _activeStudents = totalStudents;
        _assignedTopics = uniqueTopics.length;
        _isLoading = false;
      });

      debugPrint('\n📊 TEACHER STATISTICS SUMMARY:');
      debugPrint('   Total Classes Assigned: $_totalClasses');
      debugPrint('   Total Active Students: $_activeStudents');
      debugPrint('   Unique Topics Assigned: $_assignedTopics');

      if (_totalClasses > 0) {
        debugPrint('\n📚 CLASS LIST:');
        for (var classInfo in classList) {
          debugPrint(
              '   - ${classInfo['name']} (${classInfo['grade']}, Section ${classInfo['section']})');
          debugPrint(
              '     Students: ${classInfo['students']}, Topic: ${classInfo['topic']}');
        }
      }

      debugPrint('==========================================\n');
    } catch (e) {
      debugPrint('❌ Error loading assigned classes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load Quiz Results from Firebase
  Future<void> _loadQuizResults(String teacherId) async {
    try {
      // Get recent quiz results for teacher's classes
      final quizSnapshot = await _firestore
          .collection('quizzes')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> quizList = [];

      if (quizSnapshot.docs.isNotEmpty) {
        for (var doc in quizSnapshot.docs) {
          final quizData = doc.data();

          // Calculate completion stats
          final resultsSnapshot = await _firestore
              .collection('quizzes')
              .doc(doc.id)
              .collection('results')
              .get();

          int completedCount = resultsSnapshot.docs.length;
          double averageScore = 0;

          if (completedCount > 0) {
            double totalScore = 0;
            for (var result in resultsSnapshot.docs) {
              totalScore += ((result.data()['score'] as num?) ?? 0).toDouble();
            }
            averageScore = totalScore / completedCount;
          }

          quizList.add({
            'title': (quizData['title'] as String?) ?? 'Untitled Quiz',
            'topic': (quizData['topic'] as String?) ?? '',
            'completedCount': completedCount,
            'averageScore': averageScore.round(),
          });
        }
      }

      setState(() {
        _quizResults = quizList;

        // Calculate overall average quiz score
        if (quizList.isNotEmpty) {
          double totalScore = 0;
          for (var quiz in quizList) {
            totalScore += (quiz['averageScore'] as int? ?? 0).toDouble();
          }
          _overallQuizScore = (totalScore / quizList.length).round();
        } else {
          _overallQuizScore = 0;
        }
      });
    } catch (e) {
      debugPrint('❌ Error loading quiz results: $e');
      setState(() {
        _overallQuizScore = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // ── Top Header with Gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Welcome Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome $_teacherName 👋',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Track your students\' progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── Profile Button ──
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.person,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TeacherProfilePage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Stats Cards - Horizontal Scroll ──
                    SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // My Classes Count
                          _buildStatCard(
                            icon: Icons.groups_outlined,
                            count: _totalClasses.toString(),
                            label: 'My Classes',
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 16),
                          // Active Students Count
                          _buildStatCard(
                            icon: Icons.school,
                            count: _activeStudents.toString(),
                            label: 'Active Students',
                            color: const Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 16),
                          // Assigned Topics Count
                          _buildStatCard(
                            icon: Icons.menu_book,
                            count: _assignedTopics.toString(),
                            label: 'Assigned Topics',
                            color: const Color(0xFF1E40AF),
                          ),
                          const SizedBox(width: 16),
                          // Quiz Results Score
                          _buildStatCard(
                            icon: Icons.check_circle,
                            count: '$_overallQuizScore%',
                            label: 'Quiz Results',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable Content ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── My Classes Section ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Classes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_totalClasses class${_totalClasses == 1 ? '' : 'es'} assigned',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      // View All Button - Only show if there are classes
                      if (_classes.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TeacherMyClassesPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Classes List or Empty State ──
                  _classes.isEmpty
                      ? _buildNoClassesWidget()
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _classes.length,
                            itemBuilder: (context, index) {
                              final classData = _classes[index];
                              return _buildCompactClassCard(
                                className:
                                    (classData['name'] as String?) ?? 'Unnamed',
                                grade: (classData['grade'] as String?) ??
                                    'Unknown',
                                studentCount:
                                    (classData['students'] as int?) ?? 0,
                                currentTopic: (classData['topic'] as String?) ??
                                    'No topic',
                                section:
                                    (classData['section'] as String?) ?? 'A',
                                onTap: () {
                                  debugPrint(
                                      'Navigating to ${classData['name']}');
                                  // TODO: Navigate to class details
                                },
                              );
                            },
                          ),
                        ),

                  const SizedBox(height: 32),

                  // ── Recent Quiz Results Section ──
                  if (_quizResults.isNotEmpty) ...[
                    const Text(
                      'Recent Quiz Results',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Quiz Results List ──
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quizResults.length,
                      itemBuilder: (context, index) {
                        final quiz = _quizResults[index];
                        return _buildQuizResultCard(
                          title: (quiz['title'] as String?) ?? 'Untitled',
                          topic: (quiz['topic'] as String?) ?? '',
                          completedCount: (quiz['completedCount'] as int?) ?? 0,
                          averageScore: (quiz['averageScore'] as int?) ?? 0,
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ] else
                    _buildNoQuizzesWidget(),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Navigation Bar ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isActive: true,
                  onTap: () {},
                ),
                _buildNavItem(
                  icon: Icons.school_outlined,
                  label: 'My Classes',
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherMyClassesPage(),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.assignment_outlined,
                  label: 'Quizzes',
                  isActive: false,
                  onTap: () {
                    debugPrint('Quizzes button tapped!');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherQuizzesPage(),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.trending_up,
                  label: 'Progress',
                  isActive: false,
                  onTap: () {
                    // TODO: Navigate to progress page
                  },
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isActive: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherProfilePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stat Card Widget ──
  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Compact Class Card Widget for Horizontal Scrolling ──
  Widget _buildCompactClassCard({
    required String className,
    required String grade,
    required int studentCount,
    required String currentTopic,
    required String section,
    required VoidCallback onTap,
  }) {
    // Get color based on grade
    Color gradeColor = const Color(0xFF3B82F6);
    if (grade.contains('5')) gradeColor = const Color(0xFF3B82F6);
    if (grade.contains('6')) gradeColor = const Color(0xFF0EA5E9);
    if (grade.contains('7')) gradeColor = const Color(0xFF8B5CF6);
    if (grade.contains('8')) gradeColor = const Color(0xFFF59E0B);
    if (grade.contains('9')) gradeColor = const Color(0xFFDC2626);
    if (grade.contains('10')) gradeColor = const Color(0xFFEC4899);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradeColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: gradeColor.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Section - Grade Badge and Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Grade Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.class_,
                        color: Color(0xFF1F2937),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        grade,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Section Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sec $section',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Class Name
            Text(
              className,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Student Count
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: gradeColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$studentCount student${studentCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Current Topic
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Topic',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTopic,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── No Classes Widget ──
  Widget _buildNoClassesWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Color(0xFF3B82F6),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Classes Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Admin hasn\'t assigned any classes to you yet.\n\nTo assign classes, admin needs to:\n1. Create classes in Firebase\n2. Set the "teacherId" field to your user ID',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadTeacherData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── No Quizzes Widget ──
  Widget _buildNoQuizzesWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              color: Color(0xFFF59E0B),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Quiz Results Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quiz results will appear here once students complete quizzes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quiz Result Card Widget ──
  Widget _buildQuizResultCard({
    required String title,
    required String topic,
    required int completedCount,
    required int averageScore,
  }) {
    Color scoreColor;
    Color progressColor;

    if (averageScore >= 85) {
      scoreColor = const Color(0xFF10B981);
      progressColor = const Color(0xFF10B981);
    } else if (averageScore >= 70) {
      scoreColor = const Color(0xFFF59E0B);
      progressColor = const Color(0xFFF59E0B);
    } else {
      scoreColor = const Color(0xFFEF4444);
      progressColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Text(
                '$averageScore%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount student${completedCount == 1 ? '' : 's'} completed',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: averageScore > 0 ? (averageScore / 100) : 0,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav Item Widget ──
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isActive ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
