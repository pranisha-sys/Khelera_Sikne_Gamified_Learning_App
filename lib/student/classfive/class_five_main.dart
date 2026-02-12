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
  String selectedAvatar = '🐨';
  String nickname = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        nickname = prefs.getString('student_nickname') ?? '';
        selectedAvatar = prefs.getString('student_avatar') ?? '🐨';
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  String _getDisplayName() {
    if (nickname.isNotEmpty) {
      return nickname;
    }
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!.split(' ').first;
    }
    return 'Student';
  }

  String _getFullName() {
    return user?.displayName ?? 'Student';
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
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
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF81D4FA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  selectedAvatar,
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getDisplayName(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
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
            Divider(height: 1, color: Colors.grey.shade200),
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
                      try {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(),
                          ),
                        );
                        if (result == true && mounted) {
                          await _loadProfileData();
                        }
                      } catch (e) {
                        debugPrint('Navigation error: $e');
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
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Achievements page coming soon!'),
                          backgroundColor: Colors.amber,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildProfileOption(
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    title: 'Log Out',
                    subtitle: 'Log out from your account',
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Log Out'),
                          content:
                              const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        try {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          debugPrint('Logout error: $e');
                        }
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
                color: iconColor.withOpacity(0.1),
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
      backgroundColor: const Color(0xFFB2EBF2), // Light cyan background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () => _showProfileBottomSheet(context),
            child: Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF81D4FA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  selectedAvatar,
                  style: const TextStyle(fontSize: 28),
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

              // WELCOME HEADER
              Center(
                child: Column(
                  children: [
                    Text(
                      'Welcome, ${_getDisplayName()}!',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00838F), // Dark cyan for contrast
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Class ${widget.classNumber} • Let\'s start your science adventure',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF006064), // Darker cyan
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // STATS CARDS
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleStatCard(
                      icon: Icons.videogame_asset,
                      iconColor: const Color(0xFF7B1FA2), // Purple
                      title: '0',
                      subtitle: 'Games Played',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSimpleStatCard(
                      icon: Icons.stars,
                      iconColor: const Color(0xFF1976D2), // Blue
                      title: '8',
                      subtitle: 'Topics Mastered',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSimpleStatCard(
                      icon: Icons.emoji_events,
                      iconColor: const Color(0xFFF57C00), // Orange
                      title: '5',
                      subtitle: 'Achievements',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // 1. YOUR LEARNING HUB HEADER
              const Row(
                children: [
                  Icon(
                    Icons.rocket_launch,
                    color: Color(0xFF6A1B9A), // Deep purple
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Your Learning Hub',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C), // Very dark purple
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 2. PLAY AND LEARN CARD - UPDATED WITH NAVIGATION
              GestureDetector(
                onTap: () {
                  // Navigate to MissionOnePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlayAndLearnPage(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(
                            0xFF7ED957), // Fresh Green – energetic and kid-friendly
                        Color(0xFFA78BFA), // Light Purple – creative and fun
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B8C85).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Game emoji in a circle
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '🎮',
                          style: TextStyle(fontSize: 36),
                        ),
                      ),
                      const SizedBox(width: 28),
                      // Text
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Play and Learn',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Explore fun Matter Learning',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // 3. KEEP LEARNING, KEEP GROWING CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF9C27B0), // Purple
                      Color(0xFFE91E63), // Pink
                      Color(0xFF8E24AA), // Purple variant
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      right: 80,
                      bottom: 5,
                      child: Text('⭐', style: TextStyle(fontSize: 22)),
                    ),
                    const Positioned(
                      right: 15,
                      bottom: 15,
                      child: Text('⭐', style: TextStyle(fontSize: 16)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('🏆', style: TextStyle(fontSize: 25)),
                            SizedBox(width: 30),
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
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.95),
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

  // SIMPLIFIED STAT CARD
  Widget _buildSimpleStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.15),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
