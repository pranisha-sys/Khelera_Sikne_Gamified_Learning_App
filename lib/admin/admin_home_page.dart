import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedBottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ===== BLUE HEADER =====
          _buildHeader(),

          // ===== SCROLLABLE BODY =====
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ===== STAT CARDS (Horizontal Scroll) =====
                    _buildStatCards(),

                    const SizedBox(height: 24),

                    // ===== QUICK ACTIONS =====
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(),

                    const SizedBox(height: 24),

                    // ===== RECENT ACTIVITY =====
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentActivity(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ===== BOTTOM NAVIGATION BAR =====
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 56, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0), // dark blue
            Color(0xFF42A5F5), // light blue
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Welcome text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Welcome Admin ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your science platform',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          // Right: Profile icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_outlined,
                color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  // ===================== STAT CARDS (Horizontal Scroll) =====================
  Widget _buildStatCards() {
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Total Students',
        'value': '856',
        'emoji': '🎓',
        'color1': Color(0xFF1565C0),
        'color2': Color(0xFF1976D2),
      },
      {
        'title': 'Total Teachers',
        'value': '42',
        'emoji': '👨‍🏫',
        'color1': Color(0xFF283593),
        'color2': Color(0xFF3949AB),
      },
      {
        'title': 'Science Courses',
        'value': '24',
        'emoji': '🔬',
        'color1': Color(0xFF1565C0),
        'color2': Color(0xFF42A5F5),
      },
      {
        'title': 'Active Quizzes',
        'value': '18',
        'emoji': '📝',
        'color1': Color(0xFF283593),
        'color2': Color(0xFF5C6BC0),
      },
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Padding(
            padding: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [stat['color1'], stat['color2']],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Emoji icon
                  Text(stat['emoji'], style: const TextStyle(fontSize: 28)),

                  // Value + Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat['value'],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        stat['title'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== QUICK ACTIONS (2x2 Grid) =====================
  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Manage Users',
        'subtitle': 'Add or edit users',
        'emoji': '👥',
        'color': Color(0xFFE8EAF6)
      },
      {
        'title': 'Science Topics',
        'subtitle': 'Manage topics',
        'emoji': '🔬',
        'color': Color(0xFFE3F2FD)
      },
      {
        'title': 'Create Quiz',
        'subtitle': 'New assessment',
        'emoji': '📝',
        'color': Color(0xFFFCE4EC)
      },
      {
        'title': 'Rewards',
        'subtitle': 'Manage badges',
        'emoji': '🏆',
        'color': Color(0xFFFFF3E0)
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji in colored circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(action['emoji'],
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const Spacer(),
              // Title
              Text(
                action['title'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                action['subtitle'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== RECENT ACTIVITY =====================
  Widget _buildRecentActivity() {
    final List<Map<String, dynamic>> activities = [
      {
        'title': 'New teacher registered',
        'time': '2 min ago',
        'emoji': '✅',
        'color': Color(0xFFE8F5E9)
      },
      {
        'title': 'Quiz completed by 23 students',
        'time': '15 min ago',
        'emoji': '📊',
        'color': Color(0xFFE3F2FD)
      },
      {
        'title': 'New badge awarded',
        'time': '1 hour ago',
        'emoji': '🎯',
        'color': Color(0xFFFCE4EC)
      },
      {
        'title': 'Science topic updated',
        'time': '2 hours ago',
        'emoji': '📚',
        'color': Color(0xFFE8EAF6)
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Emoji in colored circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: activity['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(activity['emoji'],
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),

                // Title + Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activity['time'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================== BOTTOM NAV BAR =====================
  Widget _buildBottomNavBar() {
    final List<Map<String, dynamic>> navItems = [
      {'label': 'Dashboard', 'icon': Icons.grid_view_rounded},
      {'label': 'Users', 'icon': Icons.people_outlined},
      {'label': 'Content', 'icon': Icons.description_outlined},
      {'label': 'Analytics', 'icon': Icons.bar_chart_rounded},
      {'label': 'Settings', 'icon': Icons.settings_outlined},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isSelected = _selectedBottomIndex == index;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedBottomIndex = index;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(0xFF2196F3).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'],
                      color: isSelected
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF9CA3AF),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
