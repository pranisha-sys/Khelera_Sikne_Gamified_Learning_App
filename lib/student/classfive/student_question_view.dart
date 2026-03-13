import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Option gradients: purple, blue, pink, yellow
const List<List<Color>> _optionGradients = [
  [Color(0xFF7C4DFF), Color(0xFFB388FF)],
  [Color(0xFF1E88E5), Color(0xFF64B5F6)],
  [Color(0xFFE91E63), Color(0xFFFF80AB)],
  [Color(0xFFF9A825), Color(0xFFFFD54F)],
];

const List<String> _optionEmojis = ['🎯', '💡', '⭐', '🌙'];

class StudentQuestionView extends StatefulWidget {
  final String grade;
  final String quizId; // ← ID from 'quizzes' collection
  final String studentId;

  const StudentQuestionView({
    Key? key,
    required this.grade,
    required this.quizId, // e.g. 'h62x2JgTUvLHj04zeXvm'
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.elasticOut,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.elasticOut,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    fetchQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _feedbackAnimationController.dispose();
    _cardAnimationController.dispose();
    _scoreAnimationController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  FETCH — reads from quizzes/{quizId}/questions
  // ─────────────────────────────────────────────────────────────
  Future<void> fetchQuestions() async {
    setState(() => loading = true);
    try {
      QuerySnapshot snap;

      // Try ordered fetch first; if no index, fall back to unordered
      try {
        snap = await FirebaseFirestore.instance
            .collection('quizzes') // ← TOP-LEVEL quizzes collection
            .doc(widget.quizId) // ← teacher-assigned quiz doc
            .collection('questions')
            .orderBy('questionNumber', descending: false)
            .get();
      } catch (_) {
        snap = await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .collection('questions')
            .get();
      }

      if (snap.docs.isEmpty) {
        setState(() {
          questions = [];
          loading = false;
        });
        return;
      }

      final fetched = snap.docs.map((doc) {
        final q = doc.data() as Map<String, dynamic>;
        final rawOptions = q['options'] as List<dynamic>? ?? [];

        // Support both correctAnswerIndex (from CreateQuizFromScratch) and correctAnswer
        final correctIdx = q['correctAnswerIndex'] ??
            q['correctAnswer'] ??
            q['correct_answer'] ??
            q['answer'] ??
            0;

        final options = rawOptions
            .asMap()
            .entries
            .map((e) => {
                  'text': e.value.toString(),
                  'correct': e.key == correctIdx,
                  'emoji':
                      e.key < _optionEmojis.length ? _optionEmojis[e.key] : '⭐',
                })
            .toList();

        return {
          'id': doc.id,
          'question': q['question'] ?? q['text'] ?? '',
          'options': options,
          // Support both answerExplanation (from teacher) and explanation
          'explanation': q['answerExplanation'] ?? q['explanation'] ?? '',
          'order': q['questionNumber'] ?? q['order'] ?? 0,
        };
      }).toList();

      // Sort locally by order
      fetched.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      setState(() {
        questions = fetched;
        loading = false;
      });

      _cardAnimationController.forward();
      _showOptionsSequentially();
    } catch (e) {
      debugPrint('❌ fetchQuestions error: $e');
      setState(() {
        questions = [];
        loading = false;
      });
    }
  }

  void _showOptionsSequentially() {
    setState(() => optionsVisible = [false, false, false, false]);
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 180 * (i + 1)), () {
        if (mounted) setState(() => optionsVisible[i] = true);
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Answer handling
  // ─────────────────────────────────────────────────────────────
  Future<void> saveAnswer(
      String questionId, bool isCorrect, int answerIndex) async {
    try {
      // Save to submissions using quizId (not topicId)
      final ref = FirebaseFirestore.instance
          .collection('submissions')
          .doc('${widget.studentId}_${widget.grade}_${widget.quizId}');
      await ref.set({
        'studentId': widget.studentId,
        'grade': widget.grade,
        'quizId': widget.quizId, // ← stores quizId, not topicId
        'answers': {
          questionId: {
            'selectedAnswer': answerIndex,
            'correct': isCorrect,
            'timestamp': FieldValue.serverTimestamp(),
            'score': isCorrect ? 10 : 0,
          }
        },
        'totalScore': score,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving answer: $e');
    }
  }

  void handleAnswerSelect(int index) {
    if (showFeedback) return;
    setState(() {
      selectedAnswer = index;
      showFeedback = true;
    });
    _feedbackAnimationController.forward(from: 0);

    final isCorrect = (questions[currentQuestion]['options'] as List)[index]
            ['correct'] ??
        false;
    if (isCorrect) {
      setState(() => score += 10);
      _confettiController.forward(from: 0);
      _scoreAnimationController.forward(from: 0);
    } else {
      _shakeController.forward(from: 0);
    }
    saveAnswer(questions[currentQuestion]['id'], isCorrect, index);
    setState(() => answeredQuestions.add({
          'questionId': questions[currentQuestion]['id'],
          'correct': isCorrect,
        }));
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

  Future<void> _saveQuizStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;
      final correctAnswers =
          answeredQuestions.where((a) => a['correct']).length;
      final coinsEarned = correctAnswers * 10;
      final percentage = questions.isNotEmpty
          ? (correctAnswers / questions.length * 100).round()
          : 0;

      final statsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('quiz_stats')
          .doc('stats');

      final statsDoc = await statsRef.get();
      if (statsDoc.exists) {
        final d = statsDoc.data()!;
        final topics = List<String>.from(d['completed_topics'] ?? []);
        // Mark quiz as complete using quizId
        if (!topics.contains(widget.quizId)) topics.add(widget.quizId);
        // Also mark 'quiz' so PlayAndLearnPage recognises completion
        if (!topics.contains('quiz')) topics.add('quiz');
        await statsRef.update({
          'total_quizzes': (d['total_quizzes'] ?? 0) + 1,
          'total_coins': (d['total_coins'] ?? 0) + coinsEarned,
          'total_questions': (d['total_questions'] ?? 0) + questions.length,
          'last_quiz_score': coinsEarned,
          'last_quiz_percentage': percentage,
          'completed_topics': topics,
          'last_updated': FieldValue.serverTimestamp(),
        });
      } else {
        await statsRef.set({
          'total_quizzes': 1,
          'total_coins': coinsEarned,
          'total_questions': questions.length,
          'last_quiz_score': coinsEarned,
          'last_quiz_percentage': percentage,
          'completed_topics': [widget.quizId, 'quiz'],
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });
      }

      // Also increment totalStudents on the quiz doc
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .update({'totalStudents': FieldValue.increment(1)});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'total_quizzes_$uid', (prefs.getInt('total_quizzes_$uid') ?? 0) + 1);
      await prefs.setInt('total_coins_$uid',
          (prefs.getInt('total_coins_$uid') ?? 0) + coinsEarned);
    } catch (e) {
      debugPrint('Error saving stats: $e');
    }
  }

  void handleFinish() async {
    await _saveQuizStats();
    final correct = answeredQuestions.where((a) => a['correct']).length;
    final pct =
        questions.isNotEmpty ? (correct / questions.length * 100).round() : 0;
    if (!mounted) return;
    _showResultsDialog(correct, pct);
  }

  // ─────────────────────────────────────────────────────────────
  //  Results dialog
  // ─────────────────────────────────────────────────────────────
  void _showResultsDialog(int correct, int pct) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(6, (i) {
                      final angle = i * pi / 3;
                      return Positioned(
                        left: 55 + cos(angle) * 44,
                        top: 35 + sin(angle) * 38,
                        child: Text(['⭐', '✨', '🌟', '💫', '⭐', '✨'][i],
                            style: const TextStyle(fontSize: 16)),
                      );
                    }),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.5),
                              blurRadius: 22)
                        ],
                      ),
                      child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 42))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Quiz Complete!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 6),
              Text(
                pct >= 80
                    ? '🎉 You\'re a Star!'
                    : pct >= 60
                        ? '👍 Great Work!'
                        : '💪 Keep Going!',
                style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9C27B0),
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip('🪙', '$score', 'coins'),
                    _vDivider(),
                    _statChip('✅', '$correct/${questions.length}', 'correct'),
                    _vDivider(),
                    _statChip('📊', '$pct%', 'score'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _actionBtn(
                'Continue Learning 🚀',
                const Color(0xFF7C4DFF),
                const Color(0xFFD500F9),
                () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                  Navigator.pop(context, true);
                },
                child: const Text('Back to Home 🏠',
                    style: TextStyle(color: Color(0xFF9E9EC8), fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E))),
      Text(label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9E9EC8))),
    ]);
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: const Color(0xFFE0D4F0));

  Widget _actionBtn(String text, Color c1, Color c2, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [c1, c2]),
          boxShadow: [
            BoxShadow(
                color: c1.withValues(alpha: 0.38),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Center(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold))),
      ),
    );
  }

  List<Color> _getOptionColors(int index) {
    if (!showFeedback) return _optionGradients[index % _optionGradients.length];
    final options =
        List<Map<String, dynamic>>.from(questions[currentQuestion]['options']);
    if (options[index]['correct'] ?? false) {
      return [const Color(0xFF00897B), const Color(0xFF26C6DA)];
    }
    if (selectedAnswer == index) {
      return [const Color(0xFFE53935), const Color(0xFFFF5252)];
    }
    return [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)];
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    if (loading) return _buildLoading();
    if (questions.isEmpty) return _buildEmpty();

    final currentQ = questions[currentQuestion];
    final options = List<Map<String, dynamic>>.from(currentQ['options']);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB2EBF2), Color(0xFFE8EAF6)],
              ),
            ),
          ),
          if (_confettiController.isAnimating)
            Align(
              alignment: Alignment.topCenter,
              child: _ConfettiWidget(controller: _confettiController),
            ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  isTablet ? 24 : 16, 16, isTablet ? 24 : 16, 32),
              child: Column(
                children: [
                  _buildHeader(isTablet),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _cardSlideAnimation,
                    child: _buildQuestionCard(currentQ, options, isTablet),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Column(
      children: [
        Row(
          children: [
            _backButton(() => Navigator.pop(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFFD500F9)]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 17)),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Quiz Time!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            ScaleTransition(
              scale: _scoreAnimation,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                        blurRadius: 12)
                  ],
                ),
                child: Row(children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('$score',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.grade,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5C6BC0),
                fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(children: [
                  Container(
                      height: 10, color: Colors.white.withValues(alpha: 0.6)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 10,
                    width: (MediaQuery.of(context).size.width - 32) *
                        ((currentQuestion + 1) / questions.length),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFFD500F9)]),
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                            blurRadius: 6)
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '📝 Question ${currentQuestion + 1} of ${questions.length}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5C6BC0)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q,
      List<Map<String, dynamic>> options, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🤔', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      'Question ${currentQuestion + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('❓', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q['question'] ?? '',
                      style: TextStyle(
                          fontSize: isTablet ? 21 : 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!showFeedback)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAF6), width: 1.5),
            ),
            child: const Row(
              children: [
                Text('✨', style: TextStyle(fontSize: 17)),
                SizedBox(width: 8),
                Text(
                  'Tap the correct answer!',
                  style: TextStyle(
                      color: Color(0xFF7986CB),
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ...List.generate(options.length, (index) {
          final visible =
              index < optionsVisible.length && optionsVisible[index];
          return AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0.12, 0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: index < options.length - 1 ? 12 : 0),
                child: _buildOptionTile(options[index], index, isTablet),
              ),
            ),
          );
        }),
        if (showFeedback) ...[
          const SizedBox(height: 14),
          ScaleTransition(
              scale: _feedbackAnimation,
              child: _buildFeedback(options, isTablet)),
          const SizedBox(height: 12),
          _buildNavButton(isTablet),
        ],
      ],
    );
  }

  Widget _buildOptionTile(Map<String, dynamic> opt, int index, bool isTablet) {
    final colors = _getOptionColors(index);
    final isCorrect = opt['correct'] ?? false;
    final isSelected = selectedAnswer == index;
    final emoji = opt['emoji'] as String? ??
        (index < _optionEmojis.length ? _optionEmojis[index] : '⭐');

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (_, child) {
        final offset = isSelected && !isCorrect && showFeedback
            ? Offset(_shakeAnimation.value * (index % 2 == 0 ? 1 : -1), 0)
            : Offset.zero;
        return Transform.translate(offset: offset, child: child);
      },
      child: GestureDetector(
        onTap: showFeedback ? null : () => handleAnswerSelect(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            boxShadow: [
              BoxShadow(
                  color:
                      colors[0].withValues(alpha: showFeedback ? 0.18 : 0.38),
                  blurRadius: 14,
                  offset: const Offset(0, 6))
            ],
            border: isSelected && showFeedback
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 14, vertical: isTablet ? 18 : 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    opt['text'] ?? '',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 15 : 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35),
                  ),
                ),
                if (showFeedback && isCorrect)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.check,
                        color: Color(0xFF00897B), size: 16),
                  ),
                if (showFeedback && isSelected && !isCorrect)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.close,
                        color: Color(0xFFE53935), size: 16),
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
    final explanation =
        (questions[currentQuestion]['explanation'] as String? ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
            color:
                isCorrect ? const Color(0xFF00897B) : const Color(0xFFE53935),
            width: 2),
        boxShadow: [
          BoxShadow(
              color: (isCorrect
                      ? const Color(0xFF00897B)
                      : const Color(0xFFE53935))
                  .withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Text(isCorrect ? '🎉' : '💪', style: const TextStyle(fontSize: 30)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCorrect ? 'Awesome! Correct!' : 'Not quite!',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isCorrect
                        ? const Color(0xFF00897B)
                        : const Color(0xFFE53935)),
              ),
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildNavButton(bool isTablet) {
    final isLast = currentQuestion == questions.length - 1;
    return GestureDetector(
      onTap: isLast ? handleFinish : handleNext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isLast
                ? [const Color(0xFF00897B), const Color(0xFF26C6DA)]
                : [const Color(0xFF7C4DFF), const Color(0xFFD500F9)],
          ),
          boxShadow: [
            BoxShadow(
                color:
                    (isLast ? const Color(0xFF00897B) : const Color(0xFF7C4DFF))
                        .withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Center(
          child: Text(
            isLast ? '🏆  Finish Quiz' : '➡️  Next Question',
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                        blurRadius: 28)
                  ],
                ),
                child: const Center(
                    child: Text('🚀', style: TextStyle(fontSize: 44))),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Loading your Quiz...',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0))),
            const SizedBox(height: 10),
            Text('Get ready to be awesome! 🌟',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 28),
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFFCE93D8),
                  color: Color(0xFF9C27B0),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _backButton(() => Navigator.pop(context)),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📚', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 18),
                      const Text('No questions yet!',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0))),
                      const SizedBox(height: 10),
                      Text(
                          'Your teacher is cooking up awesome questions! 👨‍🍳',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.5),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 22),
                      GestureDetector(
                        onTap: fetchQuestions,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('🔄 Try Again',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB2DFDB)),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            color: Color(0xFF006064), size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Confetti Widget
// ─────────────────────────────────────────────────────────────
class _ConfettiWidget extends StatelessWidget {
  final AnimationController controller;
  const _ConfettiWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Stack(
          children: List.generate(30, (i) {
            final rng = Random(i);
            return Positioned(
              left: rng.nextDouble() * MediaQuery.of(context).size.width,
              top: -10 +
                  controller.value * MediaQuery.of(context).size.height * 0.7,
              child: Transform.rotate(
                angle: controller.value * 2 * pi * (rng.nextDouble() * 4),
                child: Text(
                  ['🎉', '⭐', '✨', '🌟', '💫', '🎊', '🎈'][i % 7],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
