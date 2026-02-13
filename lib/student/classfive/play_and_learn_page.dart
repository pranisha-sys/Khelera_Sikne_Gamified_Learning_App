import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mission_one_page.dart'; // Import the mission page

class PlayAndLearnPage extends StatefulWidget {
  const PlayAndLearnPage({super.key});

  @override
  State<PlayAndLearnPage> createState() => _PlayAndLearnPageState();
}

class _PlayAndLearnPageState extends State<PlayAndLearnPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Quiz statistics (loaded from Firebase)
  int totalQuizzes = 0; // Topic master - number of completed topics
  int totalCoins = 0;
  int completedTopicsCount = 0;

  // Progress tracking
  int completedLessons = 0;
  final int totalLessons = 9;
  static const int totalTopics = 10;

  // List of lesson topics/IDs to track completion
  final List<String> lessonTopics = [
    'what_is_matter',
    'properties_of_matter',
    'molecules',
    'states_of_matter',
    'effect_of_heat',
    'water_dissolve',
    'impurities_of_water',
    'removal_insoluble',
    'removal_soluble',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadQuizStatsFromFirestore();
    await _syncToSharedPreferences();
  }

  // FIXED: Load stats from Firebase (source of truth)
  Future<void> _loadQuizStatsFromFirestore() async {
    if (user == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    try {
      final userStatsDoc = await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('quiz_stats')
          .doc('stats')
          .get();

      if (userStatsDoc.exists) {
        final data = userStatsDoc.data()!;

        // Get completed topics from Firebase
        final completedTopicsList =
            List<String>.from(data['completed_topics'] ?? []);

        setState(() {
          // Topic master = count of completed topics from Firebase
          totalQuizzes = completedTopicsList.length;
          // Total coins
          totalCoins = data['total_coins'] ?? 0;
          // For achievement calculation
          completedTopicsCount = completedTopicsList.length;
          // Count how many of our lesson topics are completed
          completedLessons = lessonTopics
              .where((topic) => completedTopicsList.contains(topic))
              .length;
        });

        debugPrint('✅ Loaded quiz stats from Firebase:');
        debugPrint('  - Topic Master (Completed Topics): $totalQuizzes');
        debugPrint('  - Total Coins: $totalCoins');
        debugPrint('  - Achievement: ${_getAchievementPercentage()}%');
        debugPrint('  - Completed Lessons: $completedLessons / $totalLessons');
      } else {
        debugPrint('⚠️ No stats document found, starting fresh');
        setState(() {
          totalQuizzes = 0;
          totalCoins = 0;
          completedTopicsCount = 0;
          completedLessons = 0;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading quiz stats from Firebase: $e');
    }
  }

  // Sync Firebase data to SharedPreferences as backup
  Future<void> _syncToSharedPreferences() async {
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = user!.uid;

      // Get data from Firebase
      final userStatsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('quiz_stats')
          .doc('stats')
          .get();

      if (userStatsDoc.exists) {
        final data = userStatsDoc.data()!;
        final completedTopics =
            List<String>.from(data['completed_topics'] ?? []);

        // Sync to SharedPreferences
        await prefs.setInt('total_quizzes_$uid', data['total_quizzes'] ?? 0);
        await prefs.setInt('total_coins_$uid', data['total_coins'] ?? 0);
        await prefs.setInt(
            'total_questions_$uid', data['total_questions'] ?? 0);
        await prefs.setStringList('completed_topics_$uid', completedTopics);

        debugPrint('💾 Synced Firebase data to SharedPreferences');
      }
    } catch (e) {
      debugPrint('❌ Error syncing to SharedPreferences: $e');
    }
  }

  // Achievement percentage: 10% per topic (10 topics = 100%)
  int _getAchievementPercentage() {
    if (totalTopics == 0) return 0;
    // Each topic is worth 10% (10 topics × 10% = 100%)
    return ((completedTopicsCount / totalTopics) * 100).round();
  }

  bool _isLessonUnlocked(int index) {
    // First lesson is always unlocked
    if (index == 0) return true;

    // Other lessons unlock when previous lesson is completed
    return completedLessons >= index;
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage =
        totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00838F)),
          onPressed: () =>
              Navigator.pop(context, true), // Return true to refresh main page
        ),
      ),
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // COMBINED STATS AND PROGRESS CONTAINER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF9C27B0), // Purple
                          Color(0xFFE91E63), // Pink
                          Color(0xFF8E24AA), // Deep Purple
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative stars
                        Positioned(
                          top: 10,
                          right: 20,
                          child: Opacity(
                            opacity: 0.3,
                            child:
                                const Text('⭐', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 40,
                          child: Opacity(
                            opacity: 0.4,
                            child:
                                const Text('✨', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          left: 20,
                          child: Opacity(
                            opacity: 0.3,
                            child: const Text('🌟',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ),

                        Column(
                          children: [
                            // STATS CARDS ROW
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPurpleStatCard(
                                    icon: Icons.quiz,
                                    title: '$totalQuizzes',
                                    subtitle: 'Topic master',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPurpleStatCard(
                                    icon: Icons.monetization_on,
                                    title: '$totalCoins',
                                    subtitle: 'Total Coin',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPurpleStatCard(
                                    icon: Icons.emoji_events,
                                    title: '${_getAchievementPercentage()}%',
                                    subtitle: 'Achievements',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // PROGRESS BAR
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Progress',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '$completedLessons/$totalLessons',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progressPercentage,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.3),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    minHeight: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // WHAT YOU'LL LEARN SECTION
                  const Text(
                    'What You\'ll Learn',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lesson List
                  _buildLessonItem(
                    icon: Icons.science_outlined,
                    title: 'What is Matter?',
                    isUnlocked: _isLessonUnlocked(0),
                    topicId: lessonTopics[0],
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MissionOnePage(),
                        ),
                      );
                      // Reload progress when returning
                      if (result == true && mounted) {
                        _loadAllData();
                      }
                    },
                  ),

                  _buildLessonItem(
                    icon: Icons.straighten,
                    title: 'Properties of Matter',
                    isUnlocked: _isLessonUnlocked(1),
                    topicId: lessonTopics[1],
                  ),

                  _buildLessonItem(
                    icon: Icons.bubble_chart,
                    title: 'Molecules',
                    isUnlocked: _isLessonUnlocked(2),
                    topicId: lessonTopics[2],
                  ),

                  _buildLessonItem(
                    icon: Icons.gas_meter,
                    title: 'States of Matter',
                    isUnlocked: _isLessonUnlocked(3),
                    topicId: lessonTopics[3],
                  ),

                  _buildLessonItem(
                    icon: Icons.whatshot,
                    title: 'Effect of Heat on Matter',
                    isUnlocked: _isLessonUnlocked(4),
                    topicId: lessonTopics[4],
                  ),

                  _buildLessonItem(
                    icon: Icons.water_drop,
                    title: 'Water can Dissolve Many Substances',
                    isUnlocked: _isLessonUnlocked(5),
                    topicId: lessonTopics[5],
                  ),

                  _buildLessonItem(
                    icon: Icons.filter_alt,
                    title: 'Impurities of Water',
                    isUnlocked: _isLessonUnlocked(6),
                    topicId: lessonTopics[6],
                  ),

                  _buildLessonItem(
                    icon: Icons.cleaning_services,
                    title: 'Removal of Insoluble Impurities',
                    isUnlocked: _isLessonUnlocked(7),
                    topicId: lessonTopics[7],
                  ),

                  _buildLessonItem(
                    icon: Icons.water_damage,
                    title: 'Removal of Soluble Impurities',
                    isUnlocked: _isLessonUnlocked(8),
                    topicId: lessonTopics[8],
                  ),

                  const SizedBox(height: 100), // Extra space for bottom button
                ],
              ),
            ),
          ),

          // Fixed Bottom Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C4DFF), // Deep Purple
                    Color(0xFFD500F9), // Pink Purple
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Navigate to the first unlocked lesson
                    if (_isLessonUnlocked(0)) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MissionOnePage(),
                        ),
                      );
                      // Reload progress when returning
                      if (result == true && mounted) {
                        _loadAllData();
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Start Learning',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Fixed Floating Action Button with Emoji
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9C27B0),
                Color(0xFFE91E63),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Show progress message
                final percentage = totalLessons > 0
                    ? (completedLessons / totalLessons * 100).round()
                    : 0;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Great progress! You\'ve completed $completedLessons out of $totalLessons lessons ($percentage%) 🎉',
                    ),
                    backgroundColor: const Color(0xFF9C27B0),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(32),
              child: const Center(
                child: Text(
                  '🎉',
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPurpleStatCard({
    required IconData icon,
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9C27B0), size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
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

  Widget _buildLessonItem({
    required IconData icon,
    required String title,
    required bool isUnlocked,
    required String topicId,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isUnlocked ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFF9C27B0).withValues(alpha: 0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFF9C27B0).withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUnlocked ? icon : Icons.lock,
                    color: isUnlocked ? const Color(0xFF9C27B0) : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? const Color(0xFF212121) : Colors.grey,
                    ),
                  ),
                ),
                if (isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Locked',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
