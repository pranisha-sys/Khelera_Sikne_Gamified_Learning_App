import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'teacher_my_classes_page.dart';
import 'teacher_quizzes_page.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isEditing = false;

  // Form Controllers
  late TextEditingController _phoneController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _joiningDateController;

  Map<String, dynamic> _teacherData = {};
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadTeacherProfile();
  }

  void _initializeControllers() {
    _phoneController = TextEditingController();
    _qualificationController = TextEditingController();
    _experienceController = TextEditingController();
    _joiningDateController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final teacherDoc =
          await _firestore.collection('teachers').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final teacherData = teacherDoc.data();

        setState(() {
          _teacherData = {
            'name': userData?['name'] ?? 'Teacher Name',
            'email': user.email ?? 'No email',
            'phone': userData?['phone'] ?? '+977 9800000000',
            'department': teacherData?['department'] ?? 'Science',
            'qualification': teacherData?['qualification'] ?? 'M.Sc.',
            'experience': teacherData?['experience'] ?? '5 years',
            'joiningDate': teacherData?['joiningDate'] ?? 'Jan 2020',
            'employeeId': teacherData?['employeeId'] ?? 'TCH001',
          };
          _photoUrl = userData?['photoUrl'] ?? teacherData?['photoUrl'];
          _isLoading = false;

          _phoneController.text = _teacherData['phone'];
          _qualificationController.text = _teacherData['qualification'];
          _experienceController.text = _teacherData['experience'];
          _joiningDateController.text = _teacherData['joiningDate'];
        });
      } else {
        setState(() {
          _teacherData = {
            'name': 'Teacher Name',
            'email': user.email ?? 'teacher@school.com',
            'phone': '+977 9800000000',
            'department': 'Science',
            'qualification': 'M.Sc. in Physics',
            'experience': '5 years',
            'joiningDate': 'January 2020',
            'employeeId': 'TCH001',
          };
          _photoUrl = null;
          _isLoading = false;

          _phoneController.text = _teacherData['phone'];
          _qualificationController.text = _teacherData['qualification'];
          _experienceController.text = _teacherData['experience'];
          _joiningDateController.text = _teacherData['joiningDate'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not authenticated. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final phone = _phoneController.text.trim();
      final qualification = _qualificationController.text.trim();
      final experience = _experienceController.text.trim();
      final joiningDate = _joiningDateController.text.trim();

      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (qualification.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Qualification cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (experience.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experience cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (joiningDate.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joining date cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving changes...'),
                ],
              ),
            ),
          ),
        );
      }

      await _saveToFirestore(
        user.uid,
        phone,
        qualification,
        experience,
        joiningDate,
      );
    } catch (e) {
      debugPrint('❌ Error in save profile changes: $e');

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Failed to save profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(e.toString()),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfileChanges,
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveToFirestore(
    String userId,
    String phone,
    String qualification,
    String experience,
    String joiningDate,
  ) async {
    try {
      Map<String, dynamic> userData = {
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      Map<String, dynamic> teacherData = {
        'qualification': qualification,
        'experience': experience,
        'joiningDate': joiningDate,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('💾 Saving to Firestore...');

      await _firestore.collection('users').doc(userId).set(
            userData,
            SetOptions(merge: true),
          );

      await _firestore.collection('teachers').doc(userId).set(
            teacherData,
            SetOptions(merge: true),
          );

      debugPrint('✅ Profile saved to Firestore successfully');

      if (mounted) {
        setState(() {
          _teacherData['phone'] = phone;
          _teacherData['qualification'] = qualification;
          _teacherData['experience'] = experience;
          _teacherData['joiningDate'] = joiningDate;
          _isEditing = false;
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Firestore save error: $e');
      rethrow;
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _phoneController.text = _teacherData['phone'];
      _qualificationController.text = _teacherData['qualification'];
      _experienceController.text = _teacherData['experience'];
      _joiningDateController.text = _teacherData['joiningDate'];
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await _auth.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isEditing) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Discard Changes?'),
              content: const Text(
                'You have unsaved changes. Do you want to discard them?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continue Editing'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );

          if (shouldDiscard == true) {
            _cancelEditing();
            return true;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            // ── Header with Gradient ──
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              if (_isEditing) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text('Discard Changes?'),
                                    content: const Text(
                                      'You have unsaved changes. Do you want to discard them?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Continue Editing'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _cancelEditing();
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Discard'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_isEditing) {
                                _saveProfileChanges();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isEditing ? 'Save' : 'Edit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Profile Avatar (NOT EDITABLE)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (_photoUrl != null && _photoUrl!.isNotEmpty
                                  ? NetworkImage(_photoUrl!)
                                  : null) as ImageProvider?,
                          child: (_photoUrl == null || _photoUrl!.isEmpty)
                              ? Text(
                                  _teacherData['name']
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B82F6),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _teacherData['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_teacherData['department']} Department',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _teacherData['email'],
                      isEditable: false,
                    ),
                    _buildInfoCard(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: _teacherData['phone'],
                      isEditable: _isEditing,
                      controller: _phoneController,
                      color: const Color(0xFF10B981),
                    ),
                    _buildInfoCard(
                      icon: Icons.badge_outlined,
                      label: 'Employee ID',
                      value: _teacherData['employeeId'],
                      isEditable: false,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Professional Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.school_outlined,
                      label: 'Qualification',
                      value: _teacherData['qualification'],
                      isEditable: _isEditing,
                      controller: _qualificationController,
                      color: const Color(0xFFF59E0B),
                    ),
                    _buildInfoCard(
                      icon: Icons.work_outline,
                      label: 'Experience',
                      value: _teacherData['experience'],
                      isEditable: _isEditing,
                      controller: _experienceController,
                      color: const Color(0xFFEC4899),
                    ),
                    _buildInfoCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'Joining Date',
                      value: _teacherData['joiningDate'],
                      isEditable: _isEditing,
                      controller: _joiningDateController,
                      color: const Color(0xFF06B6D4),
                    ),
                    const SizedBox(height: 32),
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _cancelEditing,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9CA3AF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProfileChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleLogout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.logout, color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),

        /// ── Shared Bottom Navigation Bar ──
        bottomNavigationBar: _buildSharedNavBar(
          context: context,
          activeIndex: 4, // Profile tab
        ),
      ),
    );
  }

  /// Shared Navigation Bar Widget
  Widget _buildSharedNavBar({
    required BuildContext context,
    required int activeIndex,
  }) {
    return Container(
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
                isActive: activeIndex == 0,
                onTap: () => Navigator.pop(context),
              ),
              _buildNavItem(
                icon: Icons.school_outlined,
                label: 'My Classes',
                isActive: activeIndex == 1,
                onTap: () {
                  if (activeIndex != 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherMyClassesPage(),
                      ),
                    );
                  }
                },
              ),
              _buildNavItem(
                icon: Icons.assignment_outlined,
                label: 'Quizzes',
                isActive: activeIndex == 2,
                onTap: () {
                  if (activeIndex != 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherQuizzesPage(),
                      ),
                    );
                  }
                },
              ),
              _buildNavItem(
                icon: Icons.trending_up,
                label: 'Progress',
                isActive: activeIndex == 3,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Progress page - Coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isActive: activeIndex == 4,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditable,
    TextEditingController? controller,
    Color color = const Color(0xFF3B82F6),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isEditable && controller != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Enter $label',
                          hintStyle: const TextStyle(
                            color: Color(0xFFD1D5DB),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: color,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller?.text ?? value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
