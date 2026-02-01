import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClassFiveMain extends StatefulWidget {
  final int classNumber;

  const ClassFiveMain({
    super.key,
    required this.classNumber,
  });

  @override
  State<ClassFiveMain> createState() => _ClassFiveMainState();
}

class _ClassFiveMainState extends State<ClassFiveMain> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Get first name from Firebase Auth display name
  String _getFirstName() {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!.split(' ').first;
    }
    return 'Student';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB2EBF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.notifications_outlined, color: Colors.grey.shade800),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey.shade800),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Welcome Header
              Center(
                child: Column(
                  children: [
                    Text(
                      'Welcome, ${_getFirstName()}!',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Class ${widget.classNumber} • Let\'s start your science adventure',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Cards with Hover
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.videogame_asset,
                      iconColor: Colors.purple.shade400,
                      title: '0',
                      subtitle: 'Games Played',
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.stars,
                      iconColor: Colors.blue.shade400,
                      title: '8',
                      subtitle: 'Topics Mastered',
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.emoji_events,
                      iconColor: Colors.amber.shade600,
                      title: '5',
                      subtitle: 'Achievements',
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Your Learning Hub
              Row(
                children: [
                  const Icon(Icons.rocket_launch,
                      color: Colors.purple, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Learning Hub',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Learning Hub Cards - Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildLearningCard(
                      title: 'Play & Learn',
                      emoji: '🎮',
                      subtitle: 'Start interactive science games',
                      backgroundColor: Color(0xFFE8D5F2),
                      icon: Icons.videogame_asset_outlined,
                      iconColor: Colors.purple.shade400,
                      onTap: () {
                        // Navigate to games
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLearningCard(
                      title: 'My Subjects',
                      emoji: '📚',
                      subtitle: 'Explore your science topics',
                      backgroundColor: Color(0xFFB3E5FC),
                      icon: Icons.menu_book_outlined,
                      iconColor: Colors.blue.shade600,
                      onTap: () {
                        // Navigate to subjects
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Learning Hub Cards - Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildLearningCard(
                      title: 'Science Gam...',
                      emoji: '🧪',
                      subtitle: 'Fun experiments & quizzes',
                      backgroundColor: Color(0xFFC8E6C9),
                      icon: Icons.science_outlined,
                      iconColor: Colors.green.shade600,
                      onTap: () {
                        // Navigate to science games
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLearningCard(
                      title: 'Progress & A...',
                      emoji: '⭐',
                      subtitle: 'Track your learning journey',
                      backgroundColor: Color(0xFFFFF9C4),
                      icon: Icons.emoji_events_outlined,
                      iconColor: Colors.amber.shade700,
                      onTap: () {
                        // Navigate to progress
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Motivation Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF9C27B0),
                      Color(0xFFE91E63),
                      Color(0xFFFF5722),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.shade200.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 80,
                      bottom: 5,
                      child: const Text('⭐', style: TextStyle(fontSize: 35)),
                    ),
                    Positioned(
                      right: 15,
                      bottom: 15,
                      child: const Text('⭐', style: TextStyle(fontSize: 30)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              '🏆',
                              style: TextStyle(fontSize: 28),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Keep Learning, Keep Growing!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re doing amazing! Complete more games to unlock special achievements and rewards.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color backgroundColor,
  }) {
    return _StatCardWithHover(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildLearningCard({
    required String title,
    required String emoji,
    required String subtitle,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return _LearningCardWithHover(
      title: title,
      emoji: emoji,
      subtitle: subtitle,
      backgroundColor: backgroundColor,
      icon: icon,
      iconColor: iconColor,
      onTap: onTap,
    );
  }
}

// Stat Card with Hover Effect
class _StatCardWithHover extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color backgroundColor;

  const _StatCardWithHover({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
  });

  @override
  State<_StatCardWithHover> createState() => _StatCardWithHoverState();
}

class _StatCardWithHoverState extends State<_StatCardWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.05 : 1.0, _isHovered ? 1.05 : 1.0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.iconColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _isHovered ? 15.0 : 8.0,
              offset: Offset(0, _isHovered ? 6 : 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(widget.icon, color: widget.iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Learning Card with Hover Effect
class _LearningCardWithHover extends StatefulWidget {
  final String title;
  final String emoji;
  final String subtitle;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _LearningCardWithHover({
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_LearningCardWithHover> createState() => _LearningCardWithHoverState();
}

class _LearningCardWithHoverState extends State<_LearningCardWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.05 : 1.0, _isHovered ? 1.05 : 1.0),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.iconColor.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: _isHovered ? 15.0 : 8.0,
                  offset: Offset(0, _isHovered ? 6 : 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(widget.icon, color: widget.iconColor, size: 20),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
