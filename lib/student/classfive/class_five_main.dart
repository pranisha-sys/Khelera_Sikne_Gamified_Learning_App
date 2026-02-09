import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'play_and_learn_page.dart';
import 'student_edit_profile_page.dart';

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
  String selectedAvatar = '🐨'; // Default avatar
  String nickname = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nickname = prefs.getString('student_nickname') ?? '';
      selectedAvatar = prefs.getString('student_avatar') ?? '🐨';
    });
  }

  // Get display name - prioritize nickname over full name
  String _getDisplayName() {
    if (nickname.isNotEmpty) {
      return nickname;
    }
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!.split(' ').first;
    }
    return 'Student';
  }

  // Get full name for profile sheet
  String _getFullName() {
    return user?.displayName ?? 'Student';
  }

  // Show profile bottom sheet
  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Profile Avatar with cute emoji
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFF81D4FA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  selectedAvatar,
                  style: TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name (show nickname if available, otherwise full name)
            Text(
              _getDisplayName(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            // Show full name if nickname is being displayed
            if (nickname.isNotEmpty && _getFullName() != 'Student') ...[
              const SizedBox(height: 4),
              Text(
                _getFullName(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Divider
            Divider(height: 1, color: Colors.grey.shade200),
            // Profile Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    iconColor: Colors.blue,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(),
                        ),
                      );
                      // Refresh the UI after returning from edit profile
                      if (result == true) {
                        await _loadProfileData();
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildProfileOption(
                    icon: Icons.emoji_events_outlined,
                    iconColor: Colors.amber,
                    title: 'Achievements',
                    subtitle: 'View your earned badges',
                    onTap: () {
                      // Navigate to achievements
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildProfileOption(
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    title: 'Log Out',
                    subtitle: 'Log out from your account',
                    onTap: () async {
                      // Show confirmation dialog
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Log Out'),
                          content: Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: Text('Log Out'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await FirebaseAuth.instance.signOut();
                        // Close the bottom sheet first
                        Navigator.pop(context);
                        // Then navigate to the root screen
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB2EBF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Profile avatar - simple circle
          GestureDetector(
            onTap: () {
              _showProfileBottomSheet(context);
            },
            child: Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Color(0xFF81D4FA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  selectedAvatar,
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
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
                      'Welcome, ${_getDisplayName()}!',
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
              // Stats Cards
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
              const SizedBox(height: 60),
              // Your Learning Hub
              Row(
                children: [
                  const Icon(Icons.rocket_launch,
                      color: Colors.purple, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Learning Hub',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Play & Learn Card (Big Container)
              _buildLearningCard(
                title: 'Play & Learn',
                emoji: '🎮',
                subtitle: 'Start interactive science games',
                backgroundColor: Color(0xFFE8D5F2),
                icon: Icons.videogame_asset_outlined,
                iconColor: Colors.purple.shade400,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlayAndLearnPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // Motivation Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
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
                      child: const Text('⭐', style: TextStyle(fontSize: 20)),
                    ),
                    Positioned(
                      right: 15,
                      bottom: 15,
                      child: const Text('⭐', style: TextStyle(fontSize: 15)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              '🏆',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(width: 15),
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
                        const SizedBox(height: 10),
                        Text(
                          'Complete all games to unlock special achievements and rewards.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 30,
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

// Learning Card with Hover Effect (Big Container)
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
          ..scale(_isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(20),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 28),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            widget.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.grey.shade600,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
