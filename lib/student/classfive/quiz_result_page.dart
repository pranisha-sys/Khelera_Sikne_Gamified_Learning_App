import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizResultPage extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final String topicName;

  const QuizResultPage({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.topicName,
  }) : super(key: key);

  Future<void> _saveQuizResults() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      // Calculate coins earned (10 coins per correct answer)
      int coinsEarned = score * 10;

      // Calculate percentage
      int percentage =
          totalQuestions > 0 ? ((score / totalQuestions) * 100).round() : 0;

      debugPrint('========== SAVING QUIZ RESULTS ==========');
      debugPrint('Topic Name: $topicName');
      debugPrint('Coins Earned: $coinsEarned');
      debugPrint('Score: $score / $totalQuestions');
      debugPrint('Percentage: $percentage%');

      // Reference to user's stats document
      final statsRef = firestore
          .collection('users')
          .doc(uid)
          .collection('quiz_stats')
          .doc('stats');

      // Get current stats from Firestore
      final statsDoc = await statsRef.get();

      if (statsDoc.exists) {
        // Update existing stats
        final currentData = statsDoc.data()!;
        final currentTotalQuizzes = currentData['total_quizzes'] ?? 0;
        final currentTotalCoins = currentData['total_coins'] ?? 0;
        final currentTotalQuestions = currentData['total_questions'] ?? 0;
        final currentCompletedTopics =
            List<String>.from(currentData['completed_topics'] ?? []);

        // Add current topic if not already completed
        if (!currentCompletedTopics.contains(topicName)) {
          currentCompletedTopics.add(topicName);
        }

        // Update Firestore
        await statsRef.update({
          'total_quizzes': currentTotalQuizzes + 1,
          'total_coins': currentTotalCoins + coinsEarned,
          'total_questions': currentTotalQuestions + totalQuestions,
          'last_quiz_score': coinsEarned,
          'last_quiz_percentage': percentage,
          'completed_topics': currentCompletedTopics,
          'last_updated': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Quiz results saved to Firestore:');
        debugPrint('  - Coins earned: $coinsEarned');
        debugPrint('  - Score: $score / $totalQuestions ($percentage%)');
        debugPrint('  - Total quizzes: ${currentTotalQuizzes + 1}');
        debugPrint('  - Total coins: ${currentTotalCoins + coinsEarned}');
        debugPrint('  - Completed topics: $currentCompletedTopics');
      } else {
        // Create new stats document for first quiz
        final completedTopics = [topicName];

        await statsRef.set({
          'total_quizzes': 1,
          'total_coins': coinsEarned,
          'total_questions': totalQuestions,
          'last_quiz_score': coinsEarned,
          'last_quiz_percentage': percentage,
          'completed_topics': completedTopics,
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Created initial quiz stats in Firestore');
        debugPrint('  - First quiz completed!');
        debugPrint('  - Coins earned: $coinsEarned');
      }

      // Also save to SharedPreferences for offline backup
      await _saveToSharedPreferences(uid, coinsEarned, percentage);

      debugPrint('========================================');
    } catch (e) {
      debugPrint('❌ Error saving quiz results to Firestore: $e');
      // Fallback to SharedPreferences only if Firestore fails
      await _saveToSharedPreferencesOnly();
    }
  }

  Future<void> _saveToSharedPreferences(
      String uid, int coinsEarned, int percentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save with user-specific keys
      int currentTotalQuizzes = prefs.getInt('total_quizzes_$uid') ?? 0;
      int currentTotalCoins = prefs.getInt('total_coins_$uid') ?? 0;
      int currentTotalQuestions = prefs.getInt('total_questions_$uid') ?? 0;
      List<String> completedTopics =
          prefs.getStringList('completed_topics_$uid') ?? [];

      if (!completedTopics.contains(topicName)) {
        completedTopics.add(topicName);
      }

      await prefs.setInt('total_quizzes_$uid', currentTotalQuizzes + 1);
      await prefs.setInt('total_coins_$uid', currentTotalCoins + coinsEarned);
      await prefs.setInt(
          'total_questions_$uid', currentTotalQuestions + totalQuestions);
      await prefs.setInt('last_quiz_score_$uid', coinsEarned);
      await prefs.setInt('last_quiz_percentage_$uid', percentage);
      await prefs.setStringList('completed_topics_$uid', completedTopics);

      debugPrint('💾 Synced to SharedPreferences (offline backup)');
    } catch (e) {
      debugPrint('❌ Error saving to SharedPreferences: $e');
    }
  }

  Future<void> _saveToSharedPreferencesOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'default';

      // Get current stats
      int currentTotalQuizzes = prefs.getInt('total_quizzes_$uid') ?? 0;
      int currentTotalCoins = prefs.getInt('total_coins_$uid') ?? 0;
      int currentTotalQuestions = prefs.getInt('total_questions_$uid') ?? 0;
      List<String> completedTopics =
          prefs.getStringList('completed_topics_$uid') ?? [];

      // Calculate coins earned (10 coins per correct answer)
      int coinsEarned = score * 10;

      // Calculate percentage
      int percentage =
          totalQuestions > 0 ? ((score / totalQuestions) * 100).round() : 0;

      // Add current topic to completed topics if not already there
      if (!completedTopics.contains(topicName)) {
        completedTopics.add(topicName);
      }

      // Update stats
      await prefs.setInt('total_quizzes_$uid', currentTotalQuizzes + 1);
      await prefs.setInt('total_coins_$uid', currentTotalCoins + coinsEarned);
      await prefs.setInt(
          'total_questions_$uid', currentTotalQuestions + totalQuestions);
      await prefs.setInt('last_quiz_score_$uid', coinsEarned);
      await prefs.setInt('last_quiz_percentage_$uid', percentage);
      await prefs.setStringList('completed_topics_$uid', completedTopics);

      debugPrint('💾 Quiz results saved to SharedPreferences (offline mode):');
      debugPrint('  - Coins earned: $coinsEarned');
      debugPrint('  - Score: $score / $totalQuestions ($percentage%)');
    } catch (e) {
      debugPrint('❌ Error saving quiz results: $e');
    }
  }

  String _getEncouragementMessage(int percentage) {
    if (percentage >= 80) {
      return '🎉 Outstanding!';
    } else if (percentage >= 60) {
      return '👍 Great effort!';
    } else {
      return '💪 Keep practicing!';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate coins and percentage
    final coinsEarned = score * 10;
    final percentage =
        totalQuestions > 0 ? ((score / totalQuestions) * 100).round() : 0;

    return WillPopScope(
      onWillPop: () async {
        // Save results and return true to indicate success
        await _saveQuizResults();
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 40)),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'Quiz Complete!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 8),

                // Encouragement
                Text(
                  _getEncouragementMessage(percentage),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 30),

                // Coins Display
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFBBF24),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 40)),
                          const SizedBox(width: 12),
                          Text(
                            '$coinsEarned',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$score out of $totalQuestions correct',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$percentage% Score',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Continue Learning Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                      );

                      // Save results before navigating back
                      await _saveQuizResults();

                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.pop(context); // Close loading

                        // Pop back to previous screen with refresh signal
                        // This will go back to the quiz/mission page
                        Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue Learning',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('🚀', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Finish Quiz Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                      );

                      // Save results before navigating back
                      await _saveQuizResults();

                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.pop(context); // Close loading

                        // Pop back to previous screen with refresh signal
                        Navigator.pop(context, true);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color(0xFF9C27B0),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🏆', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text(
                          'Finish Quiz',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                      ],
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
