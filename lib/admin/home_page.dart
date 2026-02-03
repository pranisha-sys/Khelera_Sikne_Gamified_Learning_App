import 'package:flutter/material.dart';

import 'admin_login_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ==================== SIDEBAR ====================
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0)),
              ],
            ),
            child: Column(
              children: [
                // ===== LOGO in Sidebar =====
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ===== MENU ITEMS =====
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildMenuItem(
                          icon: Icons.dashboard, title: 'Dashboard', index: 0),
                      _buildMenuItem(
                          icon: Icons.people, title: 'Users', index: 1),
                      _buildMenuItem(
                          icon: Icons.school, title: 'Teachers', index: 2),
                      _buildMenuItem(
                          icon: Icons.book, title: 'Courses', index: 3),
                      _buildMenuItem(
                          icon: Icons.assignment,
                          title: 'Assignments',
                          index: 4),
                      _buildMenuItem(
                          icon: Icons.analytics, title: 'Analytics', index: 5),
                      _buildMenuItem(
                          icon: Icons.settings, title: 'Settings', index: 6),
                    ],
                  ),
                ),

                // ===== LOGOUT =====
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFE74C3C)),
                    title: const Text('Logout',
                        style: TextStyle(color: Color(0xFFE74C3C))),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminLoginPage()),
                      );
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // ==================== MAIN CONTENT ====================
          Expanded(
            child: Column(
              children: [
                // ===== TOP BAR =====
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('Dashboard',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50))),
                      const Spacer(),
                      // Search Bar
                      Container(
                        width: 300,
                        height: 40,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(20)),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: const TextStyle(
                                color: Color(0xFF95A5A6), fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF95A5A6), size: 20),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {}),
                      const SizedBox(width: 8),
                      const CircleAvatar(
                          backgroundColor: Color(0xFF2196F3),
                          child: Icon(Icons.person, color: Colors.white)),
                    ],
                  ),
                ),

                // ===== DASHBOARD BODY =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back, Admin! 👋',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        const Text(
                            "Here's what's happening with your platform today.",
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF7F8C8D))),
                        const SizedBox(height: 32),

                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard(
                                    title: 'Total Students',
                                    value: '1,248',
                                    change: '+12%',
                                    icon: Icons.people,
                                    color: const Color(0xFF3498DB))),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard(
                                    title: 'Active Teachers',
                                    value: '48',
                                    change: '+5%',
                                    icon: Icons.school,
                                    color: const Color(0xFF2ECC71))),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard(
                                    title: 'Total Courses',
                                    value: '156',
                                    change: '+8%',
                                    icon: Icons.book,
                                    color: const Color(0xFFF39C12))),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard(
                                    title: 'Assignments',
                                    value: '432',
                                    change: '+15%',
                                    icon: Icons.assignment,
                                    color: const Color(0xFF9B59B6))),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Activity + Quick Actions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recent Activity
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Recent Activity',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50))),
                                    const SizedBox(height: 24),
                                    _buildActivityItem(
                                        title: 'New student registered',
                                        subtitle:
                                            'Ramesh Kumar joined Grade 10',
                                        time: '5 mins ago',
                                        icon: Icons.person_add,
                                        color: const Color(0xFF3498DB)),
                                    _buildActivityItem(
                                        title: 'Assignment submitted',
                                        subtitle:
                                            'Math Assignment by Sita Sharma',
                                        time: '15 mins ago',
                                        icon: Icons.assignment_turned_in,
                                        color: const Color(0xFF2ECC71)),
                                    _buildActivityItem(
                                        title: 'New course created',
                                        subtitle:
                                            'Advanced Physics by Mr. Thapa',
                                        time: '1 hour ago',
                                        icon: Icons.book_online,
                                        color: const Color(0xFFF39C12)),
                                    _buildActivityItem(
                                        title: 'Teacher approved',
                                        subtitle:
                                            'Ms. Gurung - Science Teacher',
                                        time: '2 hours ago',
                                        icon: Icons.check_circle,
                                        color: const Color(0xFF9B59B6)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Quick Actions
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Quick Actions',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50))),
                                    const SizedBox(height: 24),
                                    _buildQuickActionButton(
                                        'Add New Course',
                                        Icons.add_circle,
                                        const Color(0xFF3498DB)),
                                    const SizedBox(height: 12),
                                    _buildQuickActionButton('Manage Users',
                                        Icons.people, const Color(0xFF2ECC71)),
                                    const SizedBox(height: 12),
                                    _buildQuickActionButton(
                                        'View Reports',
                                        Icons.analytics,
                                        const Color(0xFFF39C12)),
                                    const SizedBox(height: 12),
                                    _buildQuickActionButton(
                                        'Send Announcement',
                                        Icons.campaign,
                                        const Color(0xFF9B59B6)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildMenuItem(
      {required IconData icon, required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon,
            color:
                isSelected ? const Color(0xFF2196F3) : const Color(0xFF7F8C8D)),
        title: Text(title,
            style: TextStyle(
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF2C3E50),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        selected: isSelected,
        selectedTileColor: const Color(0xFF2196F3).withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => setState(() {
          _selectedIndex = index;
        }),
      ),
    );
  }

  Widget _buildStatCard(
      {required String title,
      required String value,
      required String change,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(change,
                    style: const TextStyle(
                        color: Color(0xFF2ECC71),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50))),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D))),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      {required String title,
      required String subtitle,
      required String time,
      required IconData icon,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF7F8C8D))),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(fontSize: 12, color: Color(0xFF95A5A6))),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
