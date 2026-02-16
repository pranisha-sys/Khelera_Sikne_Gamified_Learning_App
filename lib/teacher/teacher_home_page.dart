import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'all_students_page.dart';
import 'teacher_analytics_page.dart';
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
  int _totalEnrolledStudents = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  List<String> _assignedGrades = [];
  List<Map<String, dynamic>> _allStudents = [];

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

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _teacherName = (data?['name'] as String?) ?? 'Teacher';
        });
        debugPrint('📚 Teacher Name: $_teacherName');

        Set<String> assignedGradesSet = {};

        if (data?.containsKey('assignedGrades') == true) {
          final gradesData = data!['assignedGrades'];
          if (gradesData is List) {
            for (var grade in gradesData) {
              if (grade is String && grade.isNotEmpty) {
                assignedGradesSet.add(grade);
              }
            }
          }
        }

        for (int i = 5; i <= 10; i++) {
          final gradeKey = 'grade${i}Access';
          if (data?.containsKey(gradeKey) == true && data![gradeKey] == true) {
            assignedGradesSet.add('Grade $i');
          }
        }

        setState(() {
          _assignedGrades = assignedGradesSet.toList();
        });

        debugPrint('📚 Assigned Grades: $_assignedGrades');
      }

      await _loadAssignedClasses(user.uid);
      await _loadAllStudents();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading teacher data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load Classes Assigned to Teacher and count their quizzes
  Future<void> _loadAssignedClasses(String teacherId) async {
    try {
      debugPrint('\n🔍 ============ LOADING CLASSES ============');
      debugPrint('Assigned Grades Count: ${_assignedGrades.length}');
      debugPrint('Assigned Grades List: $_assignedGrades');

      if (_assignedGrades.isEmpty) {
        debugPrint('⚠️ No assigned grades found for this teacher');
        setState(() {
          _classes = [];
          _totalClasses = 0;
        });
        return;
      }

      List<Map<String, dynamic>> classList = [];

      // Loop through each assigned grade
      for (String grade in _assignedGrades) {
        debugPrint('\n✅ Processing grade: $grade');

        // Extract grade number (e.g., "Grade 5" -> "5")
        final gradeNumber = grade.replaceAll('Grade ', '').trim();
        debugPrint('   Looking for quizzes in: $grade');

        try {
          // Count quizzes assigned by this teacher for this grade
          // FIXED: Query using 'teacherId' to match the saved field
          final quizzesSnapshot = await _firestore
              .collection('quizzes')
              .where('teacherId', isEqualTo: teacherId)
              .where('grade', isEqualTo: grade)
              .get();

          int quizCount = quizzesSnapshot.docs.length;
          debugPrint(
              '   ✅ Found $quizCount quizzes assigned by teacher for $grade');

          // Count students enrolled in this grade
          int studentCount = 0;
          try {
            final studentsSnapshot = await _firestore
                .collection('users')
                .where('role', isEqualTo: 'student')
                .where('grade', isEqualTo: grade)
                .get();
            studentCount = studentsSnapshot.docs.length;
            debugPrint('   Found $studentCount students in $grade');
          } catch (e) {
            debugPrint('   ⚠️ Error counting students: $e');
          }

          classList.add({
            'id': 'grade$gradeNumber',
            'name': grade,
            'grade': grade,
            'students': studentCount,
            'quizzes': quizCount,
            'section': 'All',
          });
        } catch (e) {
          debugPrint('   ❌ Error loading quizzes for grade $grade: $e');

          // Still add the class even if no quizzes found yet
          classList.add({
            'id': 'grade$gradeNumber',
            'name': grade,
            'grade': grade,
            'students': 0,
            'quizzes': 0,
            'section': 'All',
          });
        }
      }

      debugPrint('\n📊 FINAL STATISTICS:');
      debugPrint('   Classes found: ${classList.length}');

      setState(() {
        _classes = classList;
        _totalClasses = classList.length;
      });

      debugPrint('   Total Classes (Grades): $_totalClasses');
      debugPrint('   Enrolled Students: $_totalEnrolledStudents');
    } catch (e) {
      debugPrint('❌ Error loading assigned classes: $e');
    }
  }

  /// Load All Enrolled Students from Firebase
  Future<void> _loadAllStudents() async {
    try {
      debugPrint('\n🔍 ============ LOADING ALL STUDENTS ============');

      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      debugPrint(
          '📋 Found ${studentsSnapshot.docs.length} students in the system');

      List<Map<String, dynamic>> studentsList = [];

      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        studentsList.add({
          'id': studentId,
          'name': (studentData['name'] as String?) ?? 'Unknown Student',
          'email': (studentData['email'] as String?) ?? '',
          'grade': (studentData['grade'] as String?) ?? 'Not Assigned',
          'phone': (studentData['phone'] as String?) ?? '',
          'createdAt': studentData['createdAt'] ?? '',
        });
      }

      studentsList
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      setState(() {
        _allStudents = studentsList;
        _totalEnrolledStudents = studentsList.length;
      });

      debugPrint('✅ Loaded ${_totalEnrolledStudents} enrolled students');
    } catch (e) {
      debugPrint('❌ Error loading students: $e');
      setState(() {
        _totalEnrolledStudents = 0;
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

    // Get current user for StreamBuilder
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // Top Header
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
                    // Welcome Header
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
                                "Track your students' progress",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white, size: 24),
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  _loadTeacherData();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
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
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Assigned Classes Section
                    if (_classes.isNotEmpty) ...[
                      const Text(
                        'My Assigned Classes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _classes.map((classItem) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${classItem['grade']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${classItem['quizzes']} quizzes',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ] else if (_assignedGrades.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Assigned: ${_assignedGrades.join(", ")}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 8),
                    // ✅ STAT CARDS WITH REAL-TIME QUIZ UPDATES
                    // FIXED: Changed query to use 'teacherId' instead of 'assignedBy'
                    if (user != null)
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('quizzes')
                            .where('teacherId', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          // Show loading state or actual count
                          final quizCount =
                              snapshot.hasData ? snapshot.data!.docs.length : 0;

                          debugPrint('📊 Real-time quiz count: $quizCount');

                          return SizedBox(
                            height: 140,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildStatCard(
                                  icon: Icons.groups_outlined,
                                  count: _totalClasses.toString(),
                                  label: 'My Classes',
                                  color: const Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 16),
                                _buildStatCard(
                                  icon: Icons.school,
                                  count: _totalEnrolledStudents.toString(),
                                  label: 'Enrolled Students',
                                  color: const Color(0xFF0EA5E9),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TeacherQuizzesPage(),
                                      ),
                                    );
                                  },
                                  child: _buildStatCard(
                                    icon: Icons.assignment_outlined,
                                    count: quizCount.toString(),
                                    label: 'Quizzes',
                                    color: const Color(0xFF1E40AF),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Enrollment Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Student Enrollment',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_totalEnrolledStudents student${_totalEnrolledStudents == 1 ? "" : "s"} enrolled',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      if (_allStudents.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AllStudentsPage(students: _allStudents),
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

                  // Students List - Vertical Layout
                  _allStudents.isEmpty
                      ? _buildNoStudentsWidget()
                      : Column(
                          children: _allStudents.map((student) {
                            return _buildStudentCardVertical(
                              studentName:
                                  (student['name'] as String?) ?? 'Unknown',
                              studentGrade: (student['grade'] as String?) ??
                                  'Not Assigned',
                              studentEmail: (student['email'] as String?) ?? '',
                              studentPhone: (student['phone'] as String?) ?? '',
                              onTap: () {},
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherAnalyticsPage(),
                      ),
                    );
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

  // Stat Card Widget
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

  // No Students Widget
  Widget _buildNoStudentsWidget() {
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
              Icons.people_outline,
              color: Color(0xFF3B82F6),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Students Enrolled',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No students have enrolled in the system yet',
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

  // Student Card Widget - Vertical Version
  Widget _buildStudentCardVertical({
    required String studentName,
    required String studentGrade,
    required String studentEmail,
    required String studentPhone,
    required VoidCallback onTap,
  }) {
    Color gradeColor = const Color(0xFF3B82F6);
    if (studentGrade.contains('5')) gradeColor = const Color(0xFF3B82F6);
    if (studentGrade.contains('6')) gradeColor = const Color(0xFF0EA5E9);
    if (studentGrade.contains('7')) gradeColor = const Color(0xFF8B5CF6);
    if (studentGrade.contains('8')) gradeColor = const Color(0xFFF59E0B);
    if (studentGrade.contains('9')) gradeColor = const Color(0xFFDC2626);
    if (studentGrade.contains('10')) gradeColor = const Color(0xFFEC4899);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradeColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          studentGrade,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: gradeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (studentEmail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: gradeColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            studentEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (studentPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: gradeColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          studentPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Nav Item
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
