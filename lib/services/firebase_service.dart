import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Lesson configuration with coin distribution
  final Map<String, int> lessonCoins = {
    'What is Matter?': 30,
    'Properties of Matter': 30,
    'Molecules': 30,
    'States of Matter': 30,
    'Effect of Heat on Matter': 30,
    'Water can Dissolve Many Substances': 30,
    'Impurities of Water': 30,
    'Removal of Insoluble Impurities': 30,
    'Removal of Soluble Impurities': 30,
    'Final Quiz': 200, // Final quiz worth 200 coins
  };

  // Total coins available: 500
  int get totalCoins => lessonCoins.values.reduce((a, b) => a + b);

  // Initialize user progress if not exists
  Future<void> initializeUserProgress(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(userId).set({
        'totalCoins': 0,
        'quizzesTaken': 0,
        'achievementPercentage': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Initialize all lessons as locked except the first one
      final lessons = lessonCoins.keys.toList();
      for (int i = 0; i < lessons.length; i++) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('lessons')
            .doc(lessons[i])
            .set({
          'title': lessons[i],
          'isCompleted': false,
          'isUnlocked': i == 0, // Only first lesson unlocked
          'coinsEarned': 0,
          'maxCoins': lessonCoins[lessons[i]],
          'score': 0,
          'attempts': 0,
          'lastAttempt': null,
        });
      }
    }
  }

  // Get user progress data
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      await initializeUserProgress(userId);
      return {
        'totalCoins': 0,
        'quizzesTaken': 0,
        'achievementPercentage': 0,
      };
    }

    return userDoc.data() as Map<String, dynamic>;
  }

  // Get all lessons with their status
  Future<List<Map<String, dynamic>>> getLessons(String userId) async {
    final lessonsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('lessons')
        .get();

    if (lessonsSnapshot.docs.isEmpty) {
      await initializeUserProgress(userId);
      return await getLessons(userId);
    }

    return lessonsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  // Complete a lesson and award coins
  Future<void> completeLesson({
    required String userId,
    required String lessonTitle,
    required int score,
    required int totalQuestions,
  }) async {
    final lessonRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('lessons')
        .doc(lessonTitle);

    final lessonDoc = await lessonRef.get();
    if (!lessonDoc.exists) return;

    final maxCoins = lessonCoins[lessonTitle] ?? 0;

    // Calculate coins based on score percentage
    final scorePercentage = (score / totalQuestions);
    final coinsEarned = (maxCoins * scorePercentage).round();

    // Update lesson data
    await lessonRef.update({
      'isCompleted': true,
      'coinsEarned': coinsEarned,
      'score': score,
      'attempts': FieldValue.increment(1),
      'lastAttempt': FieldValue.serverTimestamp(),
    });

    // Unlock next lesson
    await _unlockNextLesson(userId, lessonTitle);

    // Update user's total coins and stats
    await _updateUserStats(userId);
  }

  // Unlock the next lesson in sequence
  Future<void> _unlockNextLesson(String userId, String completedLesson) async {
    final lessons = lessonCoins.keys.toList();
    final currentIndex = lessons.indexOf(completedLesson);

    if (currentIndex != -1 && currentIndex < lessons.length - 1) {
      final nextLesson = lessons[currentIndex + 1];
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lessons')
          .doc(nextLesson)
          .update({'isUnlocked': true});
    }
  }

  // Update user statistics
  Future<void> _updateUserStats(String userId) async {
    final lessonsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('lessons')
        .get();

    int totalCoinsEarned = 0;
    int quizzesTaken = 0;
    int completedLessons = 0;

    for (var doc in lessonsSnapshot.docs) {
      final data = doc.data();
      totalCoinsEarned += (data['coinsEarned'] as int? ?? 0);
      quizzesTaken += (data['attempts'] as int? ?? 0);
      if (data['isCompleted'] == true) {
        completedLessons++;
      }
    }

    // Calculate achievement percentage
    final achievementPercentage =
        ((totalCoinsEarned / totalCoins) * 100).round();

    await _firestore.collection('users').doc(userId).update({
      'totalCoins': totalCoinsEarned,
      'quizzesTaken': quizzesTaken,
      'achievementPercentage': achievementPercentage,
      'completedLessons': completedLessons,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Get specific lesson data
  Future<Map<String, dynamic>?> getLesson(
      String userId, String lessonTitle) async {
    final lessonDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('lessons')
        .doc(lessonTitle)
        .get();

    if (!lessonDoc.exists) return null;

    return {
      'id': lessonDoc.id,
      ...lessonDoc.data() as Map<String, dynamic>,
    };
  }

  // Check if lesson is unlocked
  Future<bool> isLessonUnlocked(String userId, String lessonTitle) async {
    final lessonDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('lessons')
        .doc(lessonTitle)
        .get();

    if (!lessonDoc.exists) return false;

    return lessonDoc.data()?['isUnlocked'] ?? false;
  }

  // Get progress percentage (0-9 lessons completed)
  Future<Map<String, int>> getChapterProgress(String userId) async {
    final lessonsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('lessons')
        .get();

    int completed = 0;
    final total = lessonCoins.length;

    for (var doc in lessonsSnapshot.docs) {
      if (doc.data()['isCompleted'] == true) {
        completed++;
      }
    }

    return {
      'completed': completed,
      'total': total,
    };
  }

  // Reset progress (for testing purposes)
  Future<void> resetProgress(String userId) async {
    // Delete all lesson documents
    final lessonsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('lessons')
        .get();

    for (var doc in lessonsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Reset user stats
    await _firestore.collection('users').doc(userId).update({
      'totalCoins': 0,
      'quizzesTaken': 0,
      'achievementPercentage': 0,
      'completedLessons': 0,
    });

    // Reinitialize
    await initializeUserProgress(userId);
  }
}
