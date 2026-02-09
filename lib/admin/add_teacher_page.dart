import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddTeacherPage extends StatefulWidget {
  const AddTeacherPage({Key? key}) : super(key: key);

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Selected classes and grades for assignment
  List<String> _selectedClassIds = [];
  List<String> _selectedGrades = []; // NEW: Selected grades
  List<Map<String, dynamic>> _availableClasses = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Only Grade 5 available
  final List<Map<String, dynamic>> _availableGrades = [
    {'grade': 'Grade 5', 'color': Color(0xFF3B82F6), 'icon': '📘'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableClasses() async {
    try {
      final snapshot = await _firestore.collection('classes').get();

      setState(() {
        _availableClasses = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unnamed Class',
            'studentCount': data['studentCount'] ?? 0,
            'currentTopic': data['currentTopic'] ?? 'No topic',
            'teacherId': data['teacherId'],
            'teacherName': data['teacherName'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading classes: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTeacher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least one grade is selected
    if (_selectedGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign Grade 5 to the teacher'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Generate unique teacher ID
      final teacherId = 'TCH-${DateTime.now().millisecondsSinceEpoch}';

      // Create teacher document with assigned grades
      final teacherData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text, // In production, hash this!
        'role': 'teacher',
        'uniqueId': teacherId,
        'isActive': true,
        'assignedGrades': _selectedGrades, // NEW: Store assigned grades
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add teacher to Firestore
      final docRef = await _firestore.collection('users').add(teacherData);
      final newTeacherId = docRef.id;
      final teacherName = _nameController.text.trim();

      // Assign selected classes to the teacher
      for (String classId in _selectedClassIds) {
        await _firestore.collection('classes').doc(classId).update({
          'teacherId': newTeacherId,
          'teacherName': teacherName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Log activity
      await _firestore.collection('activities').add({
        'type': 'teacher_creation',
        'action': 'created',
        'teacherId': newTeacherId,
        'teacherName': teacherName,
        'assignedClasses': _selectedClassIds.length,
        'assignedGrades': _selectedGrades,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Teacher created successfully! Grade 5 access granted and ${_selectedClassIds.length} ${_selectedClassIds.length == 1 ? 'class' : 'classes'} assigned.',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error creating teacher: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating teacher: $e'),
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
        elevation: 0,
        backgroundColor: const Color(0xFF8B5CF6),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Teacher',
          style: TextStyle(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
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
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                '👨‍🏫',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Teacher Account',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Fill in details and assign Grade 5 & classes',
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
                      ),

                      const SizedBox(height: 24),

                      // Personal Information Section
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter teacher\'s full name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter teacher\'s name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'teacher@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email address';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Phone Field
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+1 234 567 8900',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Create a strong password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Grade Assignment Section - Only Grade 5
                      Row(
                        children: [
                          const Text(
                            'Assign Grade 5 Access',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedGrades.isNotEmpty
                                  ? 'Granted'
                                  : 'Not granted',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Teacher will only be able to edit Grade 5 Matter Topics',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Grade 5 Selection Card
                      ..._availableGrades.map((gradeData) {
                        final isSelected =
                            _selectedGrades.contains(gradeData['grade']);
                        return _buildGradeCard(gradeData, isSelected);
                      }).toList(),

                      const SizedBox(height: 32),

                      // Class Assignment Section
                      Row(
                        children: [
                          const Text(
                            'Assign Classes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_selectedClassIds.length} selected',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_availableClasses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Center(
                            child: Text(
                              'No classes available. Create classes first.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._availableClasses.map((classData) {
                          final isSelected =
                              _selectedClassIds.contains(classData['id']);
                          final isAssigned = classData['teacherId'] != null;

                          return _buildClassCheckbox(
                            classData: classData,
                            isSelected: isSelected,
                            isAssigned: isAssigned,
                          );
                        }).toList(),

                      const SizedBox(height: 32),

                      // Create Teacher Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _createTeacher,
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
                                  'Create Teacher Account',
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
            ),
    );
  }

  // Build Grade Card Widget - Only Grade 5
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
              color: color.withOpacity(0.2),
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
              _selectedGrades.add(grade);
            } else {
              _selectedGrades.remove(grade);
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
          'Teacher can manage Grade 5 Matter Topics',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.1)
                : const Color(0xFF6B7280).withOpacity(0.1),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassCheckbox({
    required Map<String, dynamic> classData,
    required bool isSelected,
    required bool isAssigned,
  }) {
    final className = classData['name'];
    final studentCount = classData['studentCount'];
    final currentTopic = classData['currentTopic'];
    final teacherName = classData['teacherName'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: isAssigned
            ? null
            : (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedClassIds.add(classData['id']);
                  } else {
                    _selectedClassIds.remove(classData['id']);
                  }
                });
              },
        activeColor: const Color(0xFF0EA5E9),
        title: Row(
          children: [
            Text(
              className,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            if (isAssigned) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Assigned',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  '$studentCount students',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Topic: $currentTopic',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0EA5E9),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isAssigned) ...[
              const SizedBox(height: 4),
              Text(
                'Assigned to: $teacherName',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0EA5E9).withOpacity(0.1)
                : const Color(0xFF6B7280).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isSelected ? '✓' : '📚',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
