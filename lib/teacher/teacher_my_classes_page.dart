import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import your MatterContentEditorPage
import 'matter_content_editor.dart'; // Adjust path as needed

class TeacherMyClassesPage extends StatefulWidget {
  const TeacherMyClassesPage({Key? key}) : super(key: key);

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

  // Complete grade information with all details
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

  /// Load grades assigned to this teacher from Firebase
  /// Checks both 'assignedGrades' and 'grade5Access' fields for compatibility
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
      debugPrint('📧 Teacher email: ${user.email}');

      // Get teacher's document from 'users' collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        debugPrint('❌ User document not found in Firestore');
        setState(() {
          _assignedGrades = [];
          _isLoading = false;
          _errorMessage = 'User profile not found. Please contact admin.';
        });
        return;
      }

      final data = userDoc.data();
      if (data == null) {
        debugPrint('❌ User document exists but has no data');
        setState(() {
          _assignedGrades = [];
          _isLoading = false;
          _errorMessage = 'User profile is empty. Please contact admin.';
        });
        return;
      }

      // Get teacher info
      _teacherName = data['name'] ?? 'Unknown';
      _teacherEmail = data['email'] ?? user.email ?? '';

      debugPrint('👤 Teacher Name: $_teacherName');
      debugPrint('📊 User Data: $data');

      // Collect assigned grades from different possible fields
      Set<String> assignedGradesSet = {};

      // Method 1: Check 'assignedGrades' array field
      if (data.containsKey('assignedGrades')) {
        debugPrint('✅ Found assignedGrades field');
        final gradesData = data['assignedGrades'];
        debugPrint('📦 assignedGrades data type: ${gradesData.runtimeType}');
        debugPrint('📦 assignedGrades value: $gradesData');

        if (gradesData is List) {
          for (var grade in gradesData) {
            if (grade is String && grade.isNotEmpty) {
              assignedGradesSet.add(grade);
            }
          }
        }
      }

      // Method 2: Check 'grade5Access' boolean field (legacy support)
      if (data.containsKey('grade5Access') && data['grade5Access'] == true) {
        debugPrint('✅ Found grade5Access = true');
        assignedGradesSet.add('Grade 5');
      }

      // Method 3: Check individual grade access fields
      for (int i = 5; i <= 10; i++) {
        final gradeKey = 'grade${i}Access';
        if (data.containsKey(gradeKey) && data[gradeKey] == true) {
          debugPrint('✅ Found $gradeKey = true');
          assignedGradesSet.add('Grade $i');
        }
      }

      debugPrint('📚 Total assigned grades found: ${assignedGradesSet.length}');
      debugPrint('📚 Assigned grades: $assignedGradesSet');

      // Build the list of grade data to display
      List<Map<String, dynamic>> gradesList = [];
      for (String gradeName in assignedGradesSet) {
        if (_gradeInfo.containsKey(gradeName)) {
          gradesList.add(_gradeInfo[gradeName]!);
          debugPrint('✅ Added grade to display: $gradeName');
        } else {
          debugPrint('⚠️ Grade not found in gradeInfo map: $gradeName');
        }
      }

      // Sort grades by number
      gradesList.sort((a, b) {
        final gradeA = a['grade'] as String;
        final gradeB = b['grade'] as String;
        final numA =
            int.tryParse(gradeA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB =
            int.tryParse(gradeB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });

      setState(() {
        _assignedGrades = gradesList;
        _isLoading = false;
        _errorMessage = '';
      });

      if (gradesList.isEmpty) {
        debugPrint('⚠️ No grades assigned to this teacher');
      } else {
        debugPrint('✅ Successfully loaded ${gradesList.length} grade(s)');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading grades: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error loading grades: $e';
        _isLoading = false;
        _assignedGrades = [];
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
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showDebugInfo,
            tooltip: 'Debug Info',
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
                          // Header with grade count
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

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }

  /// Widget shown when there's an error
  Widget _buildErrorWidget() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Error Loading Classes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadAssignedGrades,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget shown when teacher has no assigned grades
  Widget _buildNoGradesWidget() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty State Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 60,
                color: Color(0xFF0EA5E9),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              'No Grades Assigned Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 12),

            // Description
            const Text(
              'Your administrator hasn\'t assigned any grades to you yet. Once grades are assigned, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to get grades assigned',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '1. Contact your administrator\n2. Request access to Grades 5-10\n3. Wait for admin approval\n4. Refresh this page',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Refresh Button
            ElevatedButton.icon(
              onPressed: _loadAssignedGrades,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual grade card with navigation
  Widget _buildGradeCard(Map<String, dynamic> gradeData) {
    final grade = gradeData['grade'] as String;
    final color = gradeData['color'] as Color;
    final icon = gradeData['icon'] as String;
    final description = gradeData['description'] as String;

    return GestureDetector(
      onTap: () {
        // Navigate to MatterContentEditorPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatterContentEditor(
              grade: grade,
              topicId: 'what_is_matter', // You can make this dynamic if needed
            ),
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
            // Icon
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

            // Grade Label
            Text(
              grade,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 6),

            // Description
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
          ],
        ),
      ),
    );
  }

  /// Show grade details in a dialog
  void _showGradeDetailsDialog(Map<String, dynamic> gradeData) {
    final grade = gradeData['grade'] as String;
    final color = gradeData['color'] as Color;
    final icon = gradeData['icon'] as String;
    final description = gradeData['description'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have been assigned to teach $grade. You can now manage students, assign topics, and track progress for this grade.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to MatterContentEditorPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatterContentEditor(
                    grade: grade,
                    topicId: 'what_is_matter',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Edit Content'),
          ),
        ],
      ),
    );
  }

  /// Show debug information dialog
  void _showDebugInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('User ID: ${user.uid}'),
                const SizedBox(height: 8),
                Text('Email: ${user.email}'),
                const SizedBox(height: 8),
                Text('Document Exists: ${userDoc.exists}'),
                const SizedBox(height: 8),
                const Text('User Data:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data.toString()),
                const SizedBox(height: 8),
                const Text('Assigned Grades:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_assignedGrades.map((g) => g['grade']).join(', ')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error in debug info: $e');
    }
  }
}
