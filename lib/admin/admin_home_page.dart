import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  // Sample user data
  final String _userName = "Admin User";
  final String _userEmail = "admin@khelerasikne.com";

  // Variables to store counts
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalTopics = 0;
  int _totalQuizzes = 0;
  bool _isLoading = true;

  // Recent activities list
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchRecentActivities();
  }

  // Fetch all dashboard data from Firebase
  Future<void> _fetchDashboardData() async {
    try {
      // Fetch total students
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // Fetch total teachers
      final teachersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      // Fetch total science topics
      final topicsSnapshot =
          await FirebaseFirestore.instance.collection('Matter_subtopics').get();

      // Fetch total quizzes
      final quizzesSnapshot =
          await FirebaseFirestore.instance.collection('quizzes').get();

      setState(() {
        _totalStudents = studentsSnapshot.docs.length;
        _totalTeachers = teachersSnapshot.docs.length;
        _totalTopics = topicsSnapshot.docs.length;
        _totalQuizzes = quizzesSnapshot.docs.length;
        _isLoading = false;
      });

      print(
          "✅ Students: $_totalStudents, Teachers: $_totalTeachers, Topics: $_totalTopics, Quizzes: $_totalQuizzes");
    } catch (e) {
      print("❌ Error fetching dashboard data: $e");
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fetch recent activities from Firebase
  Future<void> _fetchRecentActivities() async {
    try {
      List<Map<String, dynamic>> activities = [];

      // Fetch recent teacher registrations
      final teachersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in teachersSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'teacher_registered',
          'title': 'New teacher registered',
          'subtitle': data['name'] ?? 'Unknown',
          'timestamp': data['createdAt'] ?? Timestamp.now(),
          'icon': Icons.check_circle,
          'iconColor': const Color(0xFF10B981),
          'iconBgColor': const Color(0xFFD1FAE5),
        });
      }

      // Fetch recent quizzes created by teachers
      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in quizzesSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'quiz_created',
          'title': 'Quiz created by teacher',
          'subtitle': data['title'] ?? 'Quiz',
          'timestamp': data['createdAt'] ?? Timestamp.now(),
          'icon': Icons.quiz,
          'iconColor': const Color(0xFF3B82F6),
          'iconBgColor': const Color(0xFFDBEAFE),
        });
      }

      // Fetch recent quiz completions
      final completionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_results')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .get();

      for (var doc in completionsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'quiz_completed',
          'title': 'Quiz completed',
          'subtitle': '${data['studentCount'] ?? 1} students',
          'timestamp': data['completedAt'] ?? Timestamp.now(),
          'icon': Icons.bar_chart,
          'iconColor': const Color(0xFF3B82F6),
          'iconBgColor': const Color(0xFFDBEAFE),
        });
      }

      // Fetch recent topic updates by teachers
      final topicsSnapshot = await FirebaseFirestore.instance
          .collection('Matter_subtopics')
          .orderBy('updatedAt', descending: true)
          .limit(5)
          .get();

      for (var doc in topicsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'topic_updated',
          'title': 'Science topic updated',
          'subtitle': data['name'] ?? 'Topic',
          'timestamp': data['updatedAt'] ?? Timestamp.now(),
          'icon': Icons.science,
          'iconColor': const Color(0xFF8B5CF6),
          'iconBgColor': const Color(0xFFEDE9FE),
        });
      }

      // Fetch recent badges awarded
      final badgesSnapshot = await FirebaseFirestore.instance
          .collection('badges_awarded')
          .orderBy('awardedAt', descending: true)
          .limit(5)
          .get();

      for (var doc in badgesSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'badge_awarded',
          'title': 'New badge awarded',
          'subtitle': data['badgeName'] ?? 'Badge',
          'timestamp': data['awardedAt'] ?? Timestamp.now(),
          'icon': Icons.emoji_events,
          'iconColor': const Color(0xFFF59E0B),
          'iconBgColor': const Color(0xFFFEF3C7),
        });
      }

      // Sort all activities by timestamp
      activities.sort((a, b) {
        Timestamp timeA = a['timestamp'] as Timestamp;
        Timestamp timeB = b['timestamp'] as Timestamp;
        return timeB.compareTo(timeA);
      });

      // Keep only the 10 most recent activities
      setState(() {
        _recentActivities = activities.take(10).toList();
      });

      print("✅ Fetched ${_recentActivities.length} recent activities");
    } catch (e) {
      print("❌ Error fetching recent activities: $e");

      // Set default activities if there's an error
      setState(() {
        _recentActivities = [
          {
            'type': 'info',
            'title': 'No recent activities',
            'subtitle': 'Activities will appear here',
            'timestamp': Timestamp.now(),
            'icon': Icons.info_outline,
            'iconColor': const Color(0xFF6B7280),
            'iconBgColor': const Color(0xFFF3F4F6),
          }
        ];
      });
    }
  }

  // Helper function to format timestamp to relative time
  String _getRelativeTime(Timestamp timestamp) {
    final now = DateTime.now();
    final dateTime = timestamp.toDate();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Users page - Coming soon!')),
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content page - Coming soon!')),
        );
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analytics page - Coming soon!')),
        );
        break;
      case 4:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings page - Coming soon!')),
        );
        break;
    }
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF0EA5E9),
                  child: Text(
                    _userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.person_outline,
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile page - Coming soon!')),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.settings_outlined,
              title: 'Account Settings',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings page - Coming soon!')),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help page - Coming soon!')),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildProfileMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: const Color(0xFFDC2626),
              textColor: const Color(0xFFDC2626),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? const Color(0xFF6B7280),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor ?? const Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF9CA3AF),
      ),
      onTap: onTap,
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0EA5E9),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section with Stats Container
                    _buildHeaderSection(),

                    const SizedBox(height: 24),

                    // Quick Actions Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActionCards(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Recent Activity Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                onPressed: _fetchRecentActivities,
                                color: const Color(0xFF0EA5E9),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRecentActivity(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and profile
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Welcome Admin 👋',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showProfileMenu(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage your science platform',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),

            // Scrollable Stats Cards
            SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildScrollableStatCard(
                    icon: '🎓',
                    count: _totalStudents.toString(),
                    label: 'Total Students',
                    color: const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 12),
                  _buildScrollableStatCard(
                    icon: '👨‍🏫',
                    count: _totalTeachers.toString(),
                    label: 'Total Teachers',
                    color: const Color(0xFF1E40AF),
                  ),
                  const SizedBox(width: 12),
                  _buildScrollableStatCard(
                    icon: '🔬',
                    count: _totalTopics.toString(),
                    label: 'Science Topics',
                    color: const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 10),
                  _buildScrollableStatCard(
                    icon: '📝',
                    count: _totalQuizzes.toString(),
                    label: 'Total Quizzes',
                    color: const Color(0xFF1E40AF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableStatCard({
    required String icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 42),
          ),
          const Spacer(),
          Text(
            count,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: '👥',
                title: 'Manage Users',
                subtitle: 'Add or edit users',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Manage Users - Coming soon!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: '🔬',
                title: 'Matter Topics',
                subtitle: 'Manage sub topics',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Science Topics - Coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: '📝',
                title: 'Create Quiz',
                subtitle: 'New assessment',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create Quiz - Coming soon!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: '🏆',
                title: 'Rewards',
                subtitle: 'Manage badges',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rewards - Coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 12),
              Text(
                'No recent activities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentActivities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = _recentActivities[index];
          return _buildActivityItem(
            icon: activity['icon'],
            iconColor: activity['iconColor'],
            iconBgColor: activity['iconBgColor'],
            title: activity['title'],
            subtitle: activity['subtitle'],
            time: _getRelativeTime(activity['timestamp']),
          );
        },
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
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
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                index: 0,
                isSelected: _selectedIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                label: 'Users',
                index: 1,
                isSelected: _selectedIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.description_outlined,
                label: 'Content',
                index: 2,
                isSelected: _selectedIndex == 2,
              ),
              _buildNavItem(
                icon: Icons.bar_chart_outlined,
                label: 'Analytics',
                index: 3,
                isSelected: _selectedIndex == 3,
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                index: 4,
                isSelected: _selectedIndex == 4,
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
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0EA5E9).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
}
