import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageTeacherGradesPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const ManageTeacherGradesPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<ManageTeacherGradesPage> createState() =>
      _ManageTeacherGradesPageState();
}

class _ManageTeacherGradesPageState extends State<ManageTeacherGradesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Only Grade 5 available
  final List<Map<String, dynamic>> _availableGrades = [
    {'grade': 'Grade 5', 'color': const Color(0xFF3B82F6), 'icon': '📘'},
  ];

  List<String> _assignedGrades = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAssignedGrades();
  }

  Future<void> _loadAssignedGrades() async {
    try {
      final doc =
          await _firestore.collection('users').doc(widget.teacherId).get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _assignedGrades = List<String>.from(data?['assignedGrades'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
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

  Future<void> _saveGrades() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('users').doc(widget.teacherId).update({
        'assignedGrades': _assignedGrades,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Grades updated successfully! ${widget.teacherName} can now access ${_assignedGrades.length} ${_assignedGrades.length == 1 ? 'grade' : 'grades'}.',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating grades: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Grades - ${widget.teacherName}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Grade 5 Permission',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _assignedGrades.contains('Grade 5')
                                      ? 'Grade 5 access granted'
                                      : 'No grade access',
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

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Teacher can only edit Grade 5 Matter Topics when granted access',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Grade Selection
                    const Text(
                      'Grant Access',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grade 5 Card
                    ..._availableGrades.map((gradeData) {
                      final isSelected =
                          _assignedGrades.contains(gradeData['grade']);
                      return _buildGradeCard(gradeData, isSelected);
                    }),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveGrades,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> gradeData, bool isSelected) {
    final grade = gradeData['grade'];
    final color = gradeData['color'] as Color;
    final icon = gradeData['icon'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _assignedGrades.add(grade);
            } else {
              _assignedGrades.remove(grade);
            }
          });
        },
        activeColor: color,
        title: Text(
          grade,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: const Text(
          'Teacher can manage Matter Topics for Grade 5',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : const Color(0xFF6B7280).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isSelected ? '✓' : icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
