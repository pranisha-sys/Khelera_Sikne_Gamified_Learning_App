import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentQuestionView extends StatefulWidget {
  final String grade;
  final String topicId;
  final String studentId;

  const StudentQuestionView({
    Key? key,
    required this.grade,
    required this.topicId,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentQuestionView> createState() => _StudentQuestionViewState();
}

class _StudentQuestionViewState extends State<StudentQuestionView>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> questions = [];
  bool loading = true;
  int currentQuestion = 0;
  int? selectedAnswer;
  bool showFeedback = false;
  int score = 0;
  List<Map<String, dynamic>> answeredQuestions = [];

  // New: Track which options are visible
  List<bool> optionsVisible = [false, false, false, false];

  late AnimationController _confettiController;
  late AnimationController _feedbackAnimationController;
  late Animation<double> _feedbackAnimation;
  late AnimationController _cardAnimationController;
  late Animation<Offset> _cardSlideAnimation;
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.elasticOut,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.elasticOut,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    fetchQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _feedbackAnimationController.dispose();
    _cardAnimationController.dispose();
    _scoreAnimationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> fetchQuestions() async {
    try {
      setState(() => loading = true);

      print('========== FETCHING QUESTIONS ==========');
      print('Grade: ${widget.grade}');
      print('Topic ID: ${widget.topicId}');
      print('=======================================');

      // Fetch the topic document directly
      final topicDoc = await FirebaseFirestore.instance
          .collection('grades')
          .doc(widget.grade)
          .collection('topics')
          .doc(widget.topicId)
          .get();

      print('Topic exists: ${topicDoc.exists}');

      if (topicDoc.exists) {
        final data = topicDoc.data()!;
        print('Topic data: $data');

        // Get questions from the array field
        final questionsArray = data['questions'] as List<dynamic>? ?? [];

        print('========== RESULTS ==========');
        print('Questions found: ${questionsArray.length}');

        if (questionsArray.isEmpty) {
          print('⚠️ WARNING: No questions in array!');
        } else {
          print('✅ Questions loaded successfully:');
          for (var i = 0; i < questionsArray.length; i++) {
            final q = questionsArray[i];
            print('  - Question ${i + 1}: ${q['question']}');
            print('    Options: ${q['options']}');
            print('    Correct Answer: ${q['correctAnswer']}');
          }
        }
        print('============================');

        // Convert to the format your app expects
        final fetchedQuestions = questionsArray.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value as Map<String, dynamic>;

          // Convert the teacher's format to student's expected format
          final options =
              (q['options'] as List<dynamic>).asMap().entries.map((optEntry) {
            return {
              'text': optEntry.value.toString(),
              'correct': optEntry.key == (q['correctAnswer'] ?? 0),
              'emoji': _getEmojiForOption(optEntry.key),
            };
          }).toList();

          return {
            'id': 'question_$index',
            'question': q['question'] ?? '',
            'options': options,
            'explanation': q['explanation'] ?? 'Great effort!',
            'order': index + 1,
          };
        }).toList();

        setState(() {
          questions = fetchedQuestions;
          loading = false;
        });

        if (questions.isNotEmpty) {
          _cardAnimationController.forward();
          _showOptionsSequentially();
        }
      } else {
        print('❌ Topic document does not exist!');
        setState(() {
          questions = [];
          loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ ERROR fetching questions: $e');
      print('Stack trace: $stackTrace');
      setState(() => loading = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 8),
                const Text('Error'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Could not load questions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  fetchQuestions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Helper method to get emojis for options
  String _getEmojiForOption(int index) {
    const emojis = ['🎯', '💡', '🌟', '✨'];
    return index < emojis.length ? emojis[index] : '⭐';
  }

  // Show options one by one with delay
  void _showOptionsSequentially() {
    setState(() {
      optionsVisible = [false, false, false, false];
    });

    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 300 * (i + 1)), () {
        if (mounted) {
          setState(() {
            if (i < optionsVisible.length) {
              optionsVisible[i] = true;
            }
          });
        }
      });
    }
  }

  Future<void> saveAnswer(
      String questionId, bool isCorrect, int answerIndex) async {
    try {
      final submissionRef = FirebaseFirestore.instance
          .collection('submissions')
          .doc('${widget.studentId}_${widget.grade}_${widget.topicId}');

      await submissionRef.set({
        'studentId': widget.studentId,
        'grade': widget.grade,
        'topicId': widget.topicId,
        'answers': {
          questionId: {
            'selectedAnswer': answerIndex,
            'correct': isCorrect,
            'timestamp': FieldValue.serverTimestamp(),
            'score': isCorrect ? 5 : 0,
          }
        },
        'totalScore': score,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving answer: $e');
    }
  }

  void handleAnswerSelect(int index) {
    if (showFeedback) return;

    setState(() {
      selectedAnswer = index;
      showFeedback = true;
    });

    _feedbackAnimationController.forward(from: 0);

    final currentQ = questions[currentQuestion];
    final options = List<Map<String, dynamic>>.from(currentQ['options']);
    final isCorrect = options[index]['correct'] ?? false;

    if (isCorrect) {
      setState(() => score += 10);
      _showConfetti();
      _scoreAnimationController.forward(from: 0);
    } else {
      _shakeController.forward(from: 0);
    }

    saveAnswer(currentQ['id'], isCorrect, index);

    setState(() {
      answeredQuestions.add({
        'questionId': currentQ['id'],
        'correct': isCorrect,
      });
    });
  }

  void _showConfetti() {
    _confettiController.forward(from: 0);
  }

  void handleNext() {
    if (currentQuestion < questions.length - 1) {
      _cardAnimationController.reset();
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        showFeedback = false;
      });
      _cardAnimationController.forward();
      _showOptionsSequentially();
    }
  }

  // FIXED: Save quiz stats to both Firebase and SharedPreferences
  Future<void> _saveQuizStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      final correctAnswers =
          answeredQuestions.where((a) => a['correct']).length;
      final coinsEarned = correctAnswers * 10; // 10 coins per correct answer
      final percentage = (correctAnswers / questions.length * 100).round();

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
        if (!currentCompletedTopics.contains(widget.topicId)) {
          currentCompletedTopics.add(widget.topicId);
        }

        // Update Firestore
        await statsRef.update({
          'total_quizzes': currentTotalQuizzes + 1,
          'total_coins': currentTotalCoins + coinsEarned,
          'total_questions': currentTotalQuestions + questions.length,
          'last_quiz_score': coinsEarned,
          'last_quiz_percentage': percentage,
          'completed_topics': currentCompletedTopics,
          'last_updated': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Quiz stats saved to Firestore:');
        debugPrint('  - Coins earned: $coinsEarned');
        debugPrint('  - Total quizzes: ${currentTotalQuizzes + 1}');
        debugPrint('  - Total coins: ${currentTotalCoins + coinsEarned}');
        debugPrint('  - Completed topics: $currentCompletedTopics');
      } else {
        // Create new stats document for first quiz
        final completedTopics = [widget.topicId];

        await statsRef.set({
          'total_quizzes': 1,
          'total_coins': coinsEarned,
          'total_questions': questions.length,
          'last_quiz_score': coinsEarned,
          'last_quiz_percentage': percentage,
          'completed_topics': completedTopics,
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Created initial quiz stats in Firestore');
      }

      // Also save to SharedPreferences for offline backup
      await _saveToSharedPreferences(uid, coinsEarned, percentage);
    } catch (e) {
      debugPrint('❌ Error saving quiz stats: $e');
    }
  }

  Future<void> _saveToSharedPreferences(
      String uid, int coinsEarned, int percentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current stats
      int currentTotalQuizzes = prefs.getInt('total_quizzes_$uid') ?? 0;
      int currentTotalCoins = prefs.getInt('total_coins_$uid') ?? 0;
      int currentTotalQuestions = prefs.getInt('total_questions_$uid') ?? 0;
      List<String> completedTopics =
          prefs.getStringList('completed_topics_$uid') ?? [];

      // Add current topic if not already there
      if (!completedTopics.contains(widget.topicId)) {
        completedTopics.add(widget.topicId);
      }

      // Update stats
      await prefs.setInt('total_quizzes_$uid', currentTotalQuizzes + 1);
      await prefs.setInt('total_coins_$uid', currentTotalCoins + coinsEarned);
      await prefs.setInt(
          'total_questions_$uid', currentTotalQuestions + questions.length);
      await prefs.setInt('last_quiz_score_$uid', coinsEarned);
      await prefs.setInt('last_quiz_percentage_$uid', percentage);
      await prefs.setStringList('completed_topics_$uid', completedTopics);

      debugPrint('💾 Synced to SharedPreferences');
    } catch (e) {
      debugPrint('❌ Error saving to SharedPreferences: $e');
    }
  }

  void handleFinish() async {
    // Save quiz stats first
    await _saveQuizStats();

    final correctAnswers = answeredQuestions.where((a) => a['correct']).length;
    final percentage = (correctAnswers / questions.length * 100).round();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quiz Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              percentage >= 80
                  ? '🎉 Outstanding!'
                  : percentage >= 60
                      ? '👍 Great Job!'
                      : '💪 Keep Practicing!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFEF3C7),
                    const Color(0xFFFDE68A).withOpacity(0.5)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFBBF24), width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$correctAnswers out of ${questions.length} correct',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percentage% Score',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              // Continue Learning Button - Goes to PlayAndLearnPage with refresh
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context,
                          true); // Go back to PlayAndLearnPage with refresh signal
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Row(
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
                ),
              ),
              const SizedBox(height: 12),
              // Finish Quiz Button - Goes to Main Page
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(
                          context, true); // Go back to PlayAndLearnPage
                      Navigator.pop(
                          context, true); // Go back to main with refresh
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🏆', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Finish Quiz',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color getOptionColor(int index) {
    if (!showFeedback) {
      final colors = [
        const Color(0xFF8B5CF6), // Purple
        const Color(0xFF3B82F6), // Blue
        const Color(0xFFEC4899), // Pink
        const Color(0xFFFBBF24), // Yellow
      ];
      return colors[index % colors.length];
    }

    final options =
        List<Map<String, dynamic>>.from(questions[currentQuestion]['options']);
    if (options[index]['correct'] ?? false) {
      return const Color(0xFF10B981); // Green
    }

    if (selectedAnswer == index) {
      return const Color(0xFFEF4444); // Red
    }

    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final maxWidth = isTablet ? 800.0 : size.width;

    if (loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F9FF), Color(0xFFFDF4FF), Color(0xFFFFF7ED)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '✨ Preparing your quiz...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get ready for some fun! 🎉',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F9FF), Color(0xFFFDF4FF), Color(0xFFFFF7ED)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: Colors.grey.shade800),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('📚',
                                style: TextStyle(fontSize: 64)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No questions yet! 😊',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your teacher is preparing awesome questions for you!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '💡 Check back soon!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final progress = (currentQuestion + 1) / questions.length;
    final currentQ = questions[currentQuestion];
    final options = List<Map<String, dynamic>>.from(currentQ['options']);

    return Scaffold(
      body: Stack(
        children: [
          // Enhanced Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F9FF),
                  Color(0xFFFDF4FF),
                  Color(0xFFFFF7ED)
                ],
              ),
            ),
          ),

          // Animated Background Blobs
          Positioned(
            top: size.height * 0.1,
            left: -30,
            child: _AnimatedBlob(
              color: const Color(0xFFDDD6FE).withOpacity(0.3),
              size: isTablet ? 180 : 120,
            ),
          ),
          Positioned(
            top: size.height * 0.2,
            right: -40,
            child: _AnimatedBlob(
              color: const Color(0xFFFEF3C7).withOpacity(0.3),
              size: isTablet ? 160 : 100,
              delay: 2,
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            left: size.width * 0.3,
            child: _AnimatedBlob(
              color: const Color(0xFFFCCBCA).withOpacity(0.3),
              size: isTablet ? 140 : 90,
              delay: 3,
            ),
          ),

          // Confetti
          if (_confettiController.isAnimating)
            Align(
              alignment: Alignment.topCenter,
              child: _ConfettiWidget(controller: _confettiController),
            ),

          // Main Content
          SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 32 : 20),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(progress, isTablet),
                      SizedBox(height: isTablet ? 40 : 24),

                      // Question Card
                      SlideTransition(
                        position: _cardSlideAnimation,
                        child: _buildQuestionCard(currentQ, options, isTablet),
                      ),
                      SizedBox(height: isTablet ? 24 : 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double progress, bool isTablet) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Title
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '🎯 States of Matter Quiz',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.grade,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Score with Bounce Animation
            ScaleTransition(
              scale: _scoreAnimation,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 22)),
                    SizedBox(width: isTablet ? 8 : 6),
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 24 : 20),

        // Enhanced Progress Bar
        Container(
          height: isTablet ? 18 : 16,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                      Color(0xFFFBBF24)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                width: MediaQuery.of(context).size.width * progress * 0.85,
              ),
              Center(
                child: Text(
                  '📝 Question ${currentQuestion + 1} of ${questions.length}',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> currentQ,
      List<Map<String, dynamic>> options, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 32 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Number Badge
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🤔', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Question ${currentQuestion + 1}',
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // Question Text with Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('❓', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentQ['question'] ?? '',
                  style: TextStyle(
                    fontSize: isTablet ? 26 : 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 14),

          // Subtitle with Animation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 20)),
                SizedBox(width: isTablet ? 10 : 8),
                Expanded(
                  child: Text(
                    'Tap the correct answer!',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 28 : 24),

          // Answer Options with Sequential Animation
          ...List.generate(options.length, (index) {
            return AnimatedOpacity(
              opacity: optionsVisible[index] ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset:
                    optionsVisible[index] ? Offset.zero : const Offset(0.2, 0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: index < options.length - 1
                          ? (isTablet ? 14 : 12)
                          : 0),
                  child: _buildOptionButton(options[index], index, isTablet),
                ),
              ),
            );
          }),

          // Feedback
          if (showFeedback) ...[
            SizedBox(height: isTablet ? 24 : 20),
            ScaleTransition(
              scale: _feedbackAnimation,
              child: _buildFeedback(options, isTablet),
            ),
          ],

          // Next/Finish Button
          if (showFeedback) ...[
            SizedBox(height: isTablet ? 20 : 16),
            _buildNavigationButton(isTablet),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(
      Map<String, dynamic> option, int index, bool isTablet) {
    final color = getOptionColor(index);
    final isCorrect = option['correct'] ?? false;
    final isSelected = selectedAnswer == index;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = isSelected && !isCorrect && showFeedback
            ? Offset(_shakeAnimation.value * (index % 2 == 0 ? 1 : -1), 0)
            : Offset.zero;

        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showFeedback ? null : () => handleAnswerSelect(index),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isTablet ? 20 : 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: showFeedback && isSelected ? 20 : 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: showFeedback && isSelected
                    ? Colors.white
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: Row(
              children: [
                // Emoji with Background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    option['emoji'] ?? '📝',
                    style: TextStyle(fontSize: isTablet ? 32 : 28),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 14),
                Expanded(
                  child: Text(
                    option['text'] ?? '',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
                if (showFeedback && isCorrect)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check,
                        color: color, size: isTablet ? 24 : 20),
                  ),
                if (showFeedback && isSelected && !isCorrect)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        color: color, size: isTablet ? 24 : 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(List<Map<String, dynamic>> options, bool isTablet) {
    final isCorrect = options[selectedAnswer!]['correct'] ?? false;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorrect
              ? [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)]
              : [const Color(0xFFFEE2E2), const Color(0xFFFECDCD)],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
        border: Border.all(
          color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                    .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isCorrect ? Icons.check_circle : Icons.info,
              color:
                  isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: isTablet ? 32 : 28,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? '🎉 Awesome!' : '💪 Keep Trying!',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: isTablet ? 10 : 8),
                Text(
                  questions[currentQuestion]['explanation'] ??
                      (isCorrect
                          ? 'Great job! You got it right!'
                          : 'Not quite, but keep trying!'),
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(bool isTablet) {
    final isLastQuestion = currentQuestion == questions.length - 1;

    return Container(
      width: double.infinity,
      height: isTablet ? 64 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLastQuestion
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
        boxShadow: [
          BoxShadow(
            color: (isLastQuestion
                    ? const Color(0xFF10B981)
                    : const Color(0xFFFBBF24))
                .withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLastQuestion ? handleFinish : handleNext,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLastQuestion)
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                if (!isLastQuestion)
                  const Text('👉', style: TextStyle(fontSize: 24)),
                SizedBox(width: isTablet ? 12 : 10),
                Text(
                  isLastQuestion ? 'Finish Quiz' : 'Next Question',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

class _AnimatedBlob extends StatefulWidget {
  final Color color;
  final double size;
  final int delay;

  const _AnimatedBlob({
    required this.color,
    required this.size,
    this.delay = 0,
  });

  @override
  State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(
        (Random().nextDouble() - 0.5) * 100,
        (Random().nextDouble() - 0.5) * 100,
      ),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(seconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiWidget extends StatelessWidget {
  final AnimationController controller;

  const _ConfettiWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: List.generate(30, (index) {
            final random = Random(index);
            return Positioned(
              left: random.nextDouble() * MediaQuery.of(context).size.width,
              top:
                  -10 + (controller.value * MediaQuery.of(context).size.height),
              child: Transform.rotate(
                angle: controller.value * 2 * pi * (random.nextDouble() * 4),
                child: Text(
                  ['🎉', '⭐', '✨', '🌟', '💫', '🎊', '🎈'][index % 7],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
