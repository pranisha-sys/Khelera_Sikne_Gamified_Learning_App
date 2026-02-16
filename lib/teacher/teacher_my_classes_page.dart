import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/content_management.dart'; // Import from admin folder

class TeacherMyClassesPage extends StatefulWidget {
  const TeacherMyClassesPage({super.key});

  @override
  State<TeacherMyClassesPage> createState() => _TeacherMyClassesPageState();
}

class _TeacherMyClassesPageState extends State<TeacherMyClassesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _assignedGrades = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _teacherName = '';
  String _teacherEmail = '';

  final Map<String, Map<String, dynamic>> _gradeInfo = {
    'Grade 5': {
      'grade': 'Grade 5',
      'color': const Color(0xFF3B82F6),
      'icon': '📘',
      'description': 'Basic fundamentals'
    },
    'Grade 6': {
      'grade': 'Grade 6',
      'color': const Color(0xFF0EA5E9),
      'icon': '📘',
      'description': 'Matter fundamentals'
    },
    'Grade 7': {
      'grade': 'Grade 7',
      'color': const Color(0xFF8B5CF6),
      'icon': '📗',
      'description': 'States of matter'
    },
    'Grade 8': {
      'grade': 'Grade 8',
      'color': const Color(0xFFF59E0B),
      'icon': '📙',
      'description': 'Atomic structure'
    },
    'Grade 9': {
      'grade': 'Grade 9',
      'color': const Color(0xFFDC2626),
      'icon': '📕',
      'description': 'Chemical reactions'
    },
    'Grade 10': {
      'grade': 'Grade 10',
      'color': const Color(0xFFEC4899),
      'icon': '📔',
      'description': 'Advanced chemistry'
    },
  };

  @override
  void initState() {
    super.initState();
    _loadAssignedGrades();
  }

  Future<void> _loadAssignedGrades() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      debugPrint('🔍 Loading grades for teacher UID: ${user.uid}');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        setState(() {
          _assignedGrades = [];
          _isLoading = false;
          _errorMessage = 'User profile not found';
        });
        return;
      }

      final data = userDoc.data()!;
      _teacherName = data['name'] ?? 'Unknown';
      _teacherEmail = data['email'] ?? user.email ?? '';

      Set<String> assignedGradesSet = {};

      // Check 'assignedGrades' array
      if (data.containsKey('assignedGrades') &&
          data['assignedGrades'] is List) {
        for (var grade in data['assignedGrades'] as List) {
          if (grade is String && grade.isNotEmpty) {
            assignedGradesSet.add(grade);
          }
        }
      }

      // Check individual grade access fields
      for (int i = 5; i <= 10; i++) {
        final gradeKey = 'grade${i}Access';
        if (data.containsKey(gradeKey) && data[gradeKey] == true) {
          assignedGradesSet.add('Grade $i');
        }
      }

      debugPrint('📚 Assigned grades: $assignedGradesSet');

      List<Map<String, dynamic>> gradesList = [];
      for (String gradeName in assignedGradesSet) {
        if (_gradeInfo.containsKey(gradeName)) {
          gradesList.add(_gradeInfo[gradeName]!);
        }
      }

      gradesList.sort((a, b) {
        final numA = int.tryParse(
                (a['grade'] as String).replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
        final numB = int.tryParse(
                (b['grade'] as String).replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
        return numA.compareTo(numB);
      });

      setState(() {
        _assignedGrades = gradesList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading grades: $e');
      setState(() {
        _errorMessage = 'Error loading grades: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0EA5E9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Classes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAssignedGrades,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0EA5E9),
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _assignedGrades.isEmpty
                  ? _buildNoGradesWidget()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    '🎓',
                                    style: TextStyle(fontSize: 40),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your Assigned Grades',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_assignedGrades.length} grade${_assignedGrades.length == 1 ? '' : 's'} assigned',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Teacher Info Card
                          if (_teacherName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0EA5E9)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text('👨‍🏫',
                                          style: TextStyle(fontSize: 28)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _teacherName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _teacherEmail,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Grades Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _assignedGrades.length,
                            itemBuilder: (context, index) {
                              final gradeData = _assignedGrades[index];
                              return _buildGradeCard(gradeData);
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Classes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAssignedGrades,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGradesWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 80,
              color: Color(0xFF0EA5E9),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Grades Assigned Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contact admin to assign grades to you',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAssignedGrades,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> gradeData) {
    final grade = gradeData['grade'] as String;
    final color = gradeData['color'] as Color;
    final icon = gradeData['icon'] as String;
    final description = gradeData['description'] as String;

    return GestureDetector(
      onTap: () {
        // Navigate to Content Management
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ContentManagementPage(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              grade,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Manage Content',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
