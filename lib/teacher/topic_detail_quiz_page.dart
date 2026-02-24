import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  TOPIC DETAIL WITH QUIZ FORMAT
//  Flow: Examples → Quiz → Results (saved to Firebase)
// ═══════════════════════════════════════════════════════════════════════════
class TopicDetailQuizPage extends StatefulWidget {
  final String firestoreGradeId;
  final String topicDocId;
  final String topicName;
  final String grade;
  final int topicNumber;
  final Color color;
  final bool isTeacher;

  const TopicDetailQuizPage({
    super.key,
    required this.firestoreGradeId,
    required this.topicDocId,
    required this.topicName,
    required this.grade,
    this.topicNumber = 1,
    required this.color,
    this.isTeacher = false,
  });

  @override
  State<TopicDetailQuizPage> createState() => _TopicDetailQuizPageState();
}

class _TopicDetailQuizPageState extends State<TopicDetailQuizPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore refs
  DocumentReference get _topicRef => FirebaseFirestore.instance
      .collection('grades')
      .doc(widget.firestoreGradeId)
      .collection('topics')
      .doc(widget.topicDocId);

  CollectionReference get _questionsRef => _topicRef.collection('questions');

  // Page state
  int _currentPage = 0; // 0 = Examples, 1 = Quiz, 2 = Results
  bool _dataLoaded = false;

  // Content data
  String _description = '';
  List<Map<String, dynamic>> _examples = [];
  List<String> _keyPoints = [];

  // Quiz state
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  Map<int, String> _selectedAnswers = {}; // questionIndex -> selected answer
  int _score = 0;
  bool _quizSubmitted = false;
  DateTime? _quizStartTime;
  DateTime? _quizEndTime;

  @override
  void initState() {
    super.initState();
    _loadTopicData();
  }

  Future<void> _loadTopicData() async {
    try {
      // Load topic content
      final topicDoc = await _topicRef.get();
      if (topicDoc.exists) {
        final data = topicDoc.data() as Map<String, dynamic>;
        setState(() {
          _description = data['description'] as String? ?? '';
          _keyPoints = List<String>.from(
              (data['keyPoints'] as List? ?? []).map((e) => e.toString()));
          _examples = List<Map<String, dynamic>>.from(
              (data['examples'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map)));
          _dataLoaded = true;
        });
      }

      // Load questions
      final questionsSnapshot =
          await _questionsRef.orderBy('createdAt').limit(10).get();
      setState(() {
        _questions = questionsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      });
    } catch (e) {
      _showSnackbar('Error loading data: $e', isError: true);
    }
  }

  void _startQuiz() {
    setState(() {
      _currentPage = 1;
      _quizStartTime = DateTime.now();
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _score = 0;
      _quizSubmitted = false;
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _quizSubmitted = true);

    // Calculate score
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final selectedAnswer = _selectedAnswers[i];
      final correctAnswer = question['correctAnswer'] as String;

      if (selectedAnswer == correctAnswer) {
        correctCount++;
      }
    }

    _score = correctCount;
    _quizEndTime = DateTime.now();

    // Save to Firebase
    await _saveQuizResult();

    setState(() {
      _currentPage = 2; // Show results
    });
  }

  Future<void> _saveQuizResult() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final duration = _quizEndTime!.difference(_quizStartTime!);

      await FirebaseFirestore.instance.collection('quizResults').add({
        'userId': user.uid,
        'userEmail': user.email,
        'gradeId': widget.firestoreGradeId,
        'topicId': widget.topicDocId,
        'topicName': widget.topicName,
        'grade': widget.grade,
        'score': _score,
        'totalQuestions': _questions.length,
        'percentage': (_score / _questions.length * 100).round(),
        'duration': duration.inSeconds,
        'answers': _selectedAnswers,
        'completedAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Quiz results saved!', isError: false);
    } catch (e) {
      _showSnackbar('Error saving results: $e', isError: true);
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentPage = 0;
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _score = 0;
      _quizSubmitted = false;
      _quizStartTime = null;
      _quizEndTime = null;
    });
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: _dataLoaded
            ? _buildContent()
            : Center(
                child: CircularProgressIndicator(color: widget.color),
              ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentPage) {
      case 0:
        return _buildExamplesPage();
      case 1:
        return _buildQuizPage();
      case 2:
        return _buildResultsPage();
      default:
        return _buildExamplesPage();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PAGE 1: EXAMPLES PAGE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildExamplesPage() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: widget.color,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color, widget.color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _badge('Topic ${widget.topicNumber}'),
                          const SizedBox(width: 8),
                          _badge(widget.grade),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.topicName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description Card
                if (_description.isNotEmpty) ...[
                  _buildCard(
                    icon: Icons.info_outline,
                    title: 'Overview',
                    child: Text(
                      _description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Key Points
                if (_keyPoints.isNotEmpty) ...[
                  _buildCard(
                    icon: Icons.checklist_rounded,
                    title: 'Key Points',
                    child: Column(
                      children: _keyPoints.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: widget.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: widget.color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF374151),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Examples Section
                if (_examples.isNotEmpty) ...[
                  _buildCard(
                    icon: Icons.lightbulb_outline,
                    title: 'Examples',
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _examples.length,
                          itemBuilder: (context, index) {
                            final example = _examples[index];
                            final color = _getColorFromString(
                                example['color'] as String? ?? 'blue');
                            return _buildExampleCard(
                              icon: example['icon'] as String? ?? '🔹',
                              name: example['name'] as String? ?? '',
                              color: color,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Start Quiz Button
                if (_questions.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.color, widget.color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _startQuiz,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.quiz,
                                  color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Start Quiz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${_questions.length} questions)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PAGE 2: QUIZ PAGE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildQuizPage() {
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final question = _questions[_currentQuestionIndex];
    final options = List<String>.from(question['options'] as List? ?? []);
    final selectedAnswer = _selectedAnswers[_currentQuestionIndex];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => _showExitQuizDialog(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value:
                              (_currentQuestionIndex + 1) / _questions.length,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ],
          ),
        ),

        // Question Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question['category'] as String? ?? 'General',
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDifficultyBadge(
                              question['difficulty'] as String? ?? 'Easy'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        question['question'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Options
                ...options.asMap().entries.map((entry) {
                  final optionIndex = entry.key;
                  final option = entry.value;
                  final isSelected = selectedAnswer == option;

                  return GestureDetector(
                    onTap: () => _selectAnswer(option),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.color.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? widget.color
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected ? widget.color : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? widget.color
                                    : const Color(0xFFE5E7EB),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(
                                    65 + optionIndex), // A, B, C, D
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: widget.color,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Navigation Buttons
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Previous Button
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: widget.color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Previous',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),

              // Next/Submit Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: selectedAnswer != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: widget.color.withOpacity(0.5),
                  ),
                  child: Text(
                    _currentQuestionIndex == _questions.length - 1
                        ? 'Submit Quiz'
                        : 'Next Question',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PAGE 3: RESULTS PAGE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildResultsPage() {
    final percentage = (_score / _questions.length * 100).round();
    final isPassed = percentage >= 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Result Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isPassed
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFFF59E0B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isPassed ? '🎉' : '📚',
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            isPassed ? 'Congratulations!' : 'Keep Learning!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 8),

          // Score
          Text(
            'You scored $percentage%',
            style: TextStyle(
              fontSize: 20,
              color:
                  isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 32),

          // Stats Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildStatRow(
                  'Correct Answers',
                  '$_score / ${_questions.length}',
                  Icons.check_circle,
                  const Color(0xFF10B981),
                ),
                const Divider(height: 32),
                _buildStatRow(
                  'Percentage',
                  '$percentage%',
                  Icons.percent,
                  widget.color,
                ),
                const Divider(height: 32),
                _buildStatRow(
                  'Time Taken',
                  _formatDuration(_quizEndTime!.difference(_quizStartTime!)),
                  Icons.timer,
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Review Answers
          _buildCard(
            icon: Icons.list_alt,
            title: 'Review Your Answers',
            child: Column(
              children: _questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final selectedAnswer = _selectedAnswers[index];
                final correctAnswer = question['correctAnswer'] as String;
                final isCorrect = selectedAnswer == correctAnswer;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFF10B981).withOpacity(0.05)
                        : const Color(0xFFDC2626).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFFDC2626).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question['question'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFDC2626),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (selectedAnswer != null)
                        _buildAnswerRow(
                          'Your answer:',
                          selectedAnswer,
                          isCorrect,
                        ),
                      if (!isCorrect)
                        _buildAnswerRow(
                          'Correct answer:',
                          correctAnswer,
                          true,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: widget.color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Topic',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _restartQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required String icon,
    required String name,
    required Color color,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF10B981);
        break;
      case 'medium':
        color = const Color(0xFFF59E0B);
        break;
      case 'hard':
        color = const Color(0xFFDC2626);
        break;
      default:
        color = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerRow(String label, String answer, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: isCorrect
                    ? const Color(0xFF10B981)
                    : const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Color _getColorFromString(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'green':
        return const Color(0xFF10B981);
      case 'red':
        return const Color(0xFFDC2626);
      case 'orange':
        return const Color(0xFFF59E0B);
      case 'pink':
        return const Color(0xFFEC4899);
      case 'cyan':
        return const Color(0xFF06B6D4);
      case 'yellow':
        return const Color(0xFFEAB308);
      default:
        return widget.color;
    }
  }

  void _showExitQuizDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Your progress will be lost if you exit now. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() => _currentPage = 0); // Return to examples
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
