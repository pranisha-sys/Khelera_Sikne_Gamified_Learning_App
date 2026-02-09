import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Import necessary pages for navigation
import 'add_teacher_page.dart';
import 'content_management.dart';
import 'developer_tools_page.dart';
import 'manage_teacher_grades_page.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 1; // Users tab selected
  String _searchQuery = '';
  String _selectedRoleFilter = 'All'; // Role filter options
  final List<String> _roleFilters = ['All', 'Student', 'Teacher', 'Admin'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate back to Dashboard
        Navigator.pop(context);
        break;
      case 1:
        // Already on Users - just update the view
        break;
      case 2:
        // Show Content Management inline
        break;
      case 3:
        // Navigate to Analytics - Coming soon
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analytics page - Coming soon!')),
        );
        setState(() {
          _selectedIndex = 1;
        });
        break;
      case 4:
        // Navigate to Tools
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeveloperToolsPage(),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _selectedIndex = 1;
            });
          }
        });
        break;
    }
  }

  // Get avatar emoji based on role
  String _getAvatarEmoji(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return '🎓';
      case 'teacher':
        return '👨‍🏫';
      case 'admin':
        return '👑';
      default:
        return '👤';
    }
  }

  // Get role color
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return const Color(0xFF3B82F6); // Blue
      case 'teacher':
        return const Color(0xFF8B5CF6); // Purple
      case 'admin':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Get role background color
  Color _getRoleBackgroundColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return const Color(0xFFDBEAFE); // Light Blue
      case 'teacher':
        return const Color(0xFFEDE9FE); // Light Purple
      case 'admin':
        return const Color(0xFFFEF3C7); // Light Amber
      default:
        return const Color(0xFFF3F4F6); // Light Gray
    }
  }

  // Stream of users with search and filter
  Stream<QuerySnapshot> _getUsersStream() {
    Query query = _firestore.collection('users');
    // Apply role filter
    if (_selectedRoleFilter != 'All') {
      query = query.where('role', isEqualTo: _selectedRoleFilter.toLowerCase());
    }
    return query.snapshots();
  }

  // Filter users by search query
  List<DocumentSnapshot> _filterUsers(List<DocumentSnapshot> users) {
    if (_searchQuery.isEmpty) return users;
    return users.where((user) {
      final data = user.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          role.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Toggle user active status
  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus ? 'User deactivated' : 'User activated',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: currentStatus
                ? const Color(0xFFDC2626)
                : const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user status: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Show edit user dialog
  void _showEditUserDialog(DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;
    final TextEditingController nameController =
        TextEditingController(text: data['name']);
    final TextEditingController emailController =
        TextEditingController(text: data['email']);
    String selectedRole = data['role'] ?? 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit User',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                const Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter name',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
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
                      borderSide:
                          const BorderSide(color: Color(0xFF2196F3), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Email Field
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Email cannot be changed',
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Role Selection
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF6B7280)),
                      items:
                          ['student', 'teacher', 'admin'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Text(_getAvatarEmoji(value),
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                value[0].toUpperCase() + value.substring(1),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedRole = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateUser(
                  userDoc.id,
                  nameController.text,
                  selectedRole,
                );
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update user
  Future<void> _updateUser(String userId, String name, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'User updated successfully',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog(DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'User';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete User',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$name"?',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFBBF24)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
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
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteUser(userDoc.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Delete user
  Future<void> _deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'User deleted successfully',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // View user details
  void _showUserDetailsDialog(DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getRoleBackgroundColor(data['role'] ?? 'student'),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getAvatarEmoji(data['role'] ?? 'student'),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'User Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', data['name'] ?? 'N/A'),
              const SizedBox(height: 16),
              _buildDetailRow('Email', data['email'] ?? 'N/A'),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Role',
                (data['role'] ?? 'student')[0].toUpperCase() +
                    (data['role'] ?? 'student').substring(1),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Student ID',
                data['studentId'] ?? data['uniqueId'] ?? 'N/A',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Status',
                (data['isActive'] ?? true) ? 'Active' : 'Inactive',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Created',
                data['createdAt'] != null
                    ? _formatTimestamp(data['createdAt'])
                    : 'N/A',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final Timestamp ts = timestamp as Timestamp;
      final DateTime date = ts.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If Content tab (index 2) is selected, show ContentManagementPage inline
    if (_selectedIndex == 2) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF0EA5E9),
          title: const Text(
            'Content Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedIndex = 1; // Go back to Users view
              });
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {});
              },
            ),
          ],
        ),
        body: const ContentManagementPage(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    // Otherwise show User Management
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF8B5CF6)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTeacherPage(),
                ),
              ).then((_) {
                // Refresh the page when returning
                setState(() {});
              });
            },
            tooltip: 'Add Teacher',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
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
                      borderSide:
                          const BorderSide(color: Color(0xFF2196F3), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Role Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roleFilters.length,
                    itemBuilder: (context, index) {
                      final role = _roleFilters[index];
                      final isSelected = _selectedRoleFilter == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            role,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedRoleFilter = role;
                            });
                          },
                          backgroundColor: const Color(0xFFF3F4F6),
                          selectedColor: const Color(0xFF2196F3),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2196F3),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedRoleFilter == 'All'
                              ? 'No users found'
                              : 'No ${_selectedRoleFilter.toLowerCase()}s found',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter users based on search query
                final filteredUsers = _filterUsers(snapshot.data!.docs);
                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No users match your search',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try different keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final userDoc = filteredUsers[index];
                    final data = userDoc.data() as Map<String, dynamic>;
                    return _buildUserCard(userDoc, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                label: 'Dashboard',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                selectedIcon: Icons.people,
                label: 'Users',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.description_outlined,
                selectedIcon: Icons.description,
                label: 'Content',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'Analytics',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Tools',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavBarTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(DocumentSnapshot userDoc, Map<String, dynamic> data) {
    final name = data['name'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';
    final role = data['role'] ?? 'student';
    final isActive = data['isActive'] ?? true;
    final isTeacher = role.toLowerCase() == 'teacher';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getRoleBackgroundColor(role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getAvatarEmoji(role),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleBackgroundColor(role),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role[0].toUpperCase() + role.substring(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(role),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons Column
                Column(
                  children: [
                    // Active/Inactive Toggle
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        onChanged: (value) {
                          _toggleUserStatus(userDoc.id, isActive);
                        },
                        activeColor: const Color(0xFF10B981),
                        inactiveThumbColor: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Action Buttons Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View Button
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined),
                          color: const Color(0xFF0EA5E9),
                          onPressed: () => _showUserDetailsDialog(userDoc),
                          tooltip: 'View Details',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        // Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: const Color(0xFF2196F3),
                          onPressed: () => _showEditUserDialog(userDoc),
                          tooltip: 'Edit User',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: const Color(0xFFDC2626),
                          onPressed: () =>
                              _showDeleteConfirmationDialog(userDoc),
                          tooltip: 'Delete User',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Manage Grade 5 Access Button (only for teachers)
            if (isTeacher) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageTeacherGradesPage(
                          teacherId: userDoc.id,
                          teacherName: name,
                        ),
                      ),
                    ).then((_) {
                      // Refresh when returning
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  },
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: const Text(
                    'Manage Grade 5 Access',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
