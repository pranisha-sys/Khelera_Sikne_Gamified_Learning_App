import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignGradesToTeacherPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const AssignGradesToTeacherPage({
    Key? key,
    required this.teacherId,
    required this.teacherName,
  }) : super(key: key);

  @override
  State<AssignGradesToTeacherPage> createState() =>
      _AssignGradesToTeacherPageState();
}

class _AssignGradesToTeacherPageState extends State<AssignGradesToTeacherPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of available grades
  final List<Map<String, dynamic>> _grades = [
    {
      'grade': '6',
      'color': const Color(0xFF0EA5E9),
      'icon': '📘',
    },
    {
      'grade': '7',
      'color': const Color(0xFF8B5CF6),
      'icon': '📗',
    },
    {
      'grade': '8',
      'color': const Color(0xFF10B981),
      'icon': '📙',
    },
    {
      'grade': '9',
      'color': const Color(0xFFF59E0B),
      'icon': '📕',
    },
    {
      'grade': '10',
      'color': const Color(0xFFEF4444),
      'icon': '📔',
    },
  ];

  Map<String, bool> _assignedGrades = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedGrades();
  }

  // Load already assigned grades for this teacher
  Future<void> _loadAssignedGrades() async {
    try {
      final teacherDoc =
          await _firestore.collection('teachers').doc(widget.teacherId).get();

      if (teacherDoc.exists) {
        final data = teacherDoc.data();
        final assignedGrades = data?['assignedGrades'] as List? ?? [];

        setState(() {
          for (var grade in _grades) {
            _assignedGrades[grade['grade']] =
                assignedGrades.contains(grade['grade']);
          }
          _isLoading = false;
        });
      } else {
        // Teacher document doesn't exist, create empty assignments
        setState(() {
          for (var grade in _grades) {
            _assignedGrades[grade['grade']] = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading assigned grades: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save assigned grades to Firestore
  Future<void> _saveAssignedGrades() async {
    try {
      final assignedGradesList = _assignedGrades.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await _firestore.collection('teachers').doc(widget.teacherId).set({
        'assignedGrades': assignedGradesList,
        'updatedAt': DateTime.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Grades assigned successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context, true); // Return true to indicate changes
      }
    } catch (e) {
      debugPrint('Error saving grades: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving grades: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        title: Text(
          'Assign Grades to ${widget.teacherName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0EA5E9),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Grades',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check the grades you want to assign to ${widget.teacherName}',
                                style: const TextStyle(
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

                  const SizedBox(height: 24),

                  // Grades Selection
                  const Text(
                    'Available Grades',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Grade Cards Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _grades.length,
                    itemBuilder: (context, index) {
                      final grade = _grades[index];
                      final gradeKey = grade['grade'] as String;
                      final isAssigned = _assignedGrades[gradeKey] ?? false;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _assignedGrades[gradeKey] = !isAssigned;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isAssigned ? grade['color'] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAssigned
                                  ? grade['color']
                                  : const Color(0xFFE5E7EB),
                              width: isAssigned ? 2 : 1,
                            ),
                            boxShadow: isAssigned
                                ? [
                                    BoxShadow(
                                      color: (grade['color'] as Color)
                                          .withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Text(
                                grade['icon'],
                                style: const TextStyle(fontSize: 40),
                              ),

                              const SizedBox(height: 12),

                              // Grade Label
                              Text(
                                'Grade ${grade['grade']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isAssigned
                                      ? Colors.white
                                      : grade['color'],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Checkbox indicator
                              if (isAssigned)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: grade['color'],
                                    size: 20,
                                  ),
                                )
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFF0EA5E9),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveAssignedGrades,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Save Grades',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
