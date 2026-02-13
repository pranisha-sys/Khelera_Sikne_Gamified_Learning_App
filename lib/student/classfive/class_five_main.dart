import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedAvatar = '🐨';
  String nickname = '';

  // Quiz statistics
  int totalQuizzes = 0;
  int totalCoins = 0;
  int totalQuestions = 0;
  int lastQuizScore = 0;
  int lastQuizPercentage = 0;
  int completedTopicsCount = 0;

  // Total number of topics available - 10 topics total (10% each)
  static const int totalTopics = 10;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    await _loadProfileData();
    await _loadQuizStatsFromFirestore();

    setState(() => _isLoading = false);
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load from local first for quick display
      setState(() {
        nickname = prefs.getString('student_nickname_${user!.uid}') ?? '';
        selectedAvatar = prefs.getString('student_avatar_${user!.uid}') ?? '🐨';
      });

      // Then load from Firestore
      final userDoc = await _firestore.collection('users').doc(user!.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          nickname = data['nickname'] ?? '';
          selectedAvatar = data['avatar'] ?? '🐨';
        });

        // Update local storage
        await prefs.setString('student_nickname_${user!.uid}', nickname);
        await prefs.setString('student_avatar_${user!.uid}', selectedAvatar);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadQuizStatsFromFirestore() async {
    if (user == null) return;

    try {
      // Get user's quiz stats from Firestore
      final userStatsDoc = await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('quiz_stats')
          .doc('stats')
          .get();

      if (userStatsDoc.exists) {
        final data = userStatsDoc.data()!;

        setState(() {
          totalQuizzes = data['total_quizzes'] ?? 0;
          totalCoins = data['total_coins'] ?? 0;
          totalQuestions = data['total_questions'] ?? 0;
          lastQuizScore = data['last_quiz_score'] ?? 0;
          lastQuizPercentage = data['last_quiz_percentage'] ?? 0;
          completedTopicsCount =
              (data['completed_topics'] as List?)?.length ?? 0;
        });

        debugPrint('✅ Loaded quiz stats from Firestore for user ${user!.uid}:');
        debugPrint('  - Total Quizzes: $totalQuizzes');
        debugPrint('  - Total Coins: $totalCoins');
        debugPrint(
            '  - Completed Topics: $completedTopicsCount / $totalTopics');
      } else {
        // New user - initialize with zeros
        debugPrint('🆕 New user detected - initializing with zero stats');
        await _initializeNewUserStats();
      }

      // Also sync to SharedPreferences for offline access
      await _syncToSharedPreferences();
    } catch (e) {
      debugPrint('Error loading quiz stats from Firestore: $e');
      // Fallback to SharedPreferences if Firestore fails
      await _loadQuizStatsFromSharedPreferences();
    }
  }

  Future<void> _initializeNewUserStats() async {
    if (user == null) return;

    try {
      // Create initial document for new user
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('quiz_stats')
          .doc('stats')
          .set({
        'total_quizzes': 0,
        'total_coins': 0,
        'total_questions': 0,
        'last_quiz_score': 0,
        'last_quiz_percentage': 0,
        'completed_topics': [],
        'created_at': FieldValue.serverTimestamp(),
        'last_updated': FieldValue.serverTimestamp(),
      });

      setState(() {
        totalQuizzes = 0;
        totalCoins = 0;
        totalQuestions = 0;
        lastQuizScore = 0;
        lastQuizPercentage = 0;
        completedTopicsCount = 0;
      });

      debugPrint('✅ Initialized new user stats in Firestore');
    } catch (e) {
      debugPrint('Error initializing new user stats: $e');
    }
  }

  Future<void> _loadQuizStatsFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = user?.uid ?? 'default';

      setState(() {
        totalQuizzes = prefs.getInt('total_quizzes_$uid') ?? 0;
        totalCoins = prefs.getInt('total_coins_$uid') ?? 0;
        totalQuestions = prefs.getInt('total_questions_$uid') ?? 0;
        lastQuizScore = prefs.getInt('last_quiz_score_$uid') ?? 0;
        lastQuizPercentage = prefs.getInt('last_quiz_percentage_$uid') ?? 0;

        final completedTopics =
            prefs.getStringList('completed_topics_$uid') ?? [];
        completedTopicsCount = completedTopics.length;
      });

      debugPrint('📱 Loaded from SharedPreferences (offline mode)');
    } catch (e) {
      debugPrint('Error loading from SharedPreferences: $e');
    }
  }

  Future<void> _syncToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = user?.uid ?? 'default';

      await prefs.setInt('total_quizzes_$uid', totalQuizzes);
      await prefs.setInt('total_coins_$uid', totalCoins);
      await prefs.setInt('total_questions_$uid', totalQuestions);
      await prefs.setInt('last_quiz_score_$uid', lastQuizScore);
      await prefs.setInt('last_quiz_percentage_$uid', lastQuizPercentage);

      debugPrint('💾 Synced stats to SharedPreferences');
    } catch (e) {
      debugPrint('Error syncing to SharedPreferences: $e');
    }
  }

  // Calculate achievement percentage based on completed topics (10% per topic)
  int _getAchievementPercentage() {
    if (totalTopics == 0) return 0;
    return ((completedTopicsCount / totalTopics) * 100).round();
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

  void _showAchievementsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F9FF),
              Color(0xFFFDF4FF),
              Color(0xFFFFF7ED),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text('🏆', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Achievements',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Keep up the great work!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Overall Stats
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('📊', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              const Text(
                                'Overall Statistics',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  '🎯',
                                  '$totalQuizzes',
                                  'Quizzes Taken',
                                  const Color(0xFF8B5CF6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatItem(
                                  '🪙',
                                  '$totalCoins',
                                  'Total Coins',
                                  const Color(0xFFFBBF24),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  '📝',
                                  '$totalQuestions',
                                  'Total Questions',
                                  const Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatItem(
                                  '📈',
                                  '$completedTopicsCount/$totalTopics',
                                  'Topics Done',
                                  const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Last Quiz Performance
                    if (totalQuizzes > 0)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: lastQuizPercentage >= 80
                                ? [
                                    const Color(0xFFD1FAE5),
                                    const Color(0xFFA7F3D0)
                                  ]
                                : lastQuizPercentage >= 60
                                    ? [
                                        const Color(0xFFFEF3C7),
                                        const Color(0xFFFDE68A)
                                      ]
                                    : [
                                        const Color(0xFFFEE2E2),
                                        const Color(0xFFFECDCD)
                                      ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: lastQuizPercentage >= 80
                                ? const Color(0xFF10B981)
                                : lastQuizPercentage >= 60
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFEF4444),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  lastQuizPercentage >= 80
                                      ? '🎉'
                                      : lastQuizPercentage >= 60
                                          ? '👍'
                                          : '💪',
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Last Quiz Performance',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🪙',
                                    style: TextStyle(fontSize: 40)),
                                const SizedBox(width: 12),
                                Text(
                                  '$lastQuizScore',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFBBF24),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$lastQuizPercentage% Score',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lastQuizPercentage >= 80
                                  ? '🎉 Outstanding!'
                                  : lastQuizPercentage >= 60
                                      ? '👍 Great Job!'
                                      : '💪 Keep Practicing!',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Badges Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('🎖️', style: TextStyle(fontSize: 28)),
                              SizedBox(width: 12),
                              Text(
                                'Earned Badges',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (totalQuizzes >= 1)
                                _buildBadge('🎯', 'First Quiz',
                                    'Completed your first quiz!'),
                              if (totalQuizzes >= 5)
                                _buildBadge('🔥', 'Quiz Master',
                                    'Completed 5 quizzes!'),
                              if (totalQuizzes >= 10)
                                _buildBadge(
                                    '⭐', 'Super Star', 'Completed 10 quizzes!'),
                              if (lastQuizPercentage >= 80)
                                _buildBadge('🏆', 'Top Scorer',
                                    'Scored 80% or higher!'),
                              if (completedTopicsCount >= 5)
                                _buildBadge('💯', 'Halfway There',
                                    'Completed 5 topics!'),
                              if (completedTopicsCount >= 10)
                                _buildBadge('🌟', 'Topic Champion',
                                    'Completed all 10 topics!'),
                            ],
                          ),
                          if (totalQuizzes == 0)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      '🎯',
                                      style: TextStyle(fontSize: 48),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Complete quizzes to earn badges!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String emoji, String title, String description) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFBBF24),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
                      _showAchievementsBottomSheet(context);
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFB2EBF2),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00838F)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
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
                        color: Color(0xFF00838F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Class ${widget.classNumber} • Let\'s start your science adventure',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF006064),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // YOUR LEARNING HUB HEADER
              const Row(
                children: [
                  Icon(
                    Icons.rocket_launch,
                    color: Color(0xFF6A1B9A),
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Your Learning Hub',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // PLAY AND LEARN CARD
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlayAndLearnPage(),
                    ),
                  );
                  // Reload stats when returning from quiz if result is true
                  if (result == true && mounted) {
                    await _loadQuizStatsFromFirestore();
                    setState(() {}); // Force UI rebuild
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7ED957),
                        Color(0xFFA78BFA),
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
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // KEEP LEARNING, KEEP GROWING CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF9C27B0),
                      Color(0xFFE91E63),
                      Color(0xFF8E24AA),
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
                          'Complete all 10 topics to unlock special achievements and reach 100%!',
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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
