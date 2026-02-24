import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  TOPIC DETAIL WITH QUIZ FORMAT
//  Flow: Examples → Quiz → Results (saved to Firebase)
//
//  FIRESTORE SCHEMA (questions subcollection):
//  {
//    order: 1,                        ← int
//    question: "What is matter?",     ← String
//    options: ["A", "B", "C", "D"],   ← List<String>
//    correctAnswer: 0,                ← int (index into options[])
//    explanation: "...",              ← String
//  }
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
  // Each question is stored as:
  // {
  //   'id': doc.id,
  //   'question': String,
  //   'options': List<String>,
  //   'correctAnswerIndex': int,   ← always int internally
  //   'explanation': String,
  //   'difficulty': String,
  //   'category': String,
  // }
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {}; // questionIndex → option index (int)
  int _score = 0;
  bool _quizSubmitted = false;
  DateTime? _quizStartTime;
  DateTime? _quizEndTime;

  @override
  void initState() {
    super.initState();
    _loadTopicData();
  }

  // ─────────────────────────────────────────────────────────────
  //  DATA LOADING
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadTopicData() async {
    try {
      // Load topic document (description, examples, keyPoints)
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
      } else {
        setState(() => _dataLoaded = true);
      }

      // ── Load questions ordered by `order` field ──────────────
      // correctAnswer stored as int in Firestore (e.g. 2)
      // options stored as List<String> (e.g. ["Solid","Liquid","Gas","..."])
      final snap = await _questionsRef
          .orderBy('order', descending: false)
          .limit(20)
          .get();

      final loaded = snap.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;

        // ── Safely parse correctAnswer as int ──────────────────
        // Firestore may return it as int or as String — handle both
        int correctIdx = 0;
        final raw = d['correctAnswer'];
        if (raw is int) {
          correctIdx = raw;
        } else if (raw is String) {
          correctIdx = int.tryParse(raw) ?? 0;
        }

        // ── Safely parse options as List<String> ──────────────
        final rawOptions = d['options'] as List<dynamic>? ?? [];
        final options = rawOptions.map((o) => o.toString()).toList();

        return {
          'id': doc.id,
          'question': (d['question'] ?? d['text'] ?? '').toString(),
          'options': options,
          'correctAnswerIndex': correctIdx, // always int
          'explanation': (d['explanation'] ?? 'Great thinking!').toString(),
          'difficulty': (d['difficulty'] ?? 'Easy').toString(),
          'category': (d['category'] ?? 'General').toString(),
          'order': d['order'] ?? 0,
        };
      }).toList();

      setState(() => _questions = loaded);
    } catch (e, stack) {
      debugPrint('❌ _loadTopicData: $e\n$stack');
      setState(() => _dataLoaded = true);
      _showSnackbar('Error loading data: $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  QUIZ FLOW
  // ─────────────────────────────────────────────────────────────
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

  /// Store selected option index (int)
  void _selectAnswer(int optionIndex) {
    setState(() => _selectedAnswers[_currentQuestionIndex] = optionIndex);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _quizSubmitted = true);

    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final correctIdx = _questions[i]['correctAnswerIndex'] as int;
      final selectedIdx = _selectedAnswers[i];
      if (selectedIdx != null && selectedIdx == correctIdx) correctCount++;
    }

    _score = correctCount;
    _quizEndTime = DateTime.now();

    await _saveQuizResult();
    setState(() => _currentPage = 2);
  }

  Future<void> _saveQuizResult() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final duration = _quizEndTime!.difference(_quizStartTime!);
      final percentage =
          _questions.isEmpty ? 0 : (_score / _questions.length * 100).round();

      // Build a serialisable answers map (all ints → safe for Firestore)
      final answersMap = _selectedAnswers
          .map((qIdx, optIdx) => MapEntry(qIdx.toString(), optIdx));

      await FirebaseFirestore.instance.collection('quizResults').add({
        'userId': user.uid,
        'userEmail': user.email,
        'gradeId': widget.firestoreGradeId,
        'topicId': widget.topicDocId,
        'topicName': widget.topicName,
        'grade': widget.grade,
        'score': _score,
        'totalQuestions': _questions.length,
        'percentage': percentage,
        'duration': duration.inSeconds,
        'answers': answersMap,
        'completedAt': FieldValue.serverTimestamp(),
      });

      _showSnackbar('Quiz results saved!', isError: false);
    } catch (e) {
      debugPrint('❌ _saveQuizResult: $e');
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

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
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
  //  PAGE 1: EXAMPLES
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildExamplesPage() {
    return CustomScrollView(
      slivers: [
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_description.isNotEmpty) ...[
                  _buildCard(
                    icon: Icons.info_outline,
                    title: 'Overview',
                    child: Text(
                      _description,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF4B5563), height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_keyPoints.isNotEmpty) ...[
                  _buildCard(
                    icon: Icons.checklist_rounded,
                    title: 'Key Points',
                    child: Column(
                      children: _keyPoints.asMap().entries.map((e) {
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
                                    '${e.key + 1}',
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
                                child: Text(e.value,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF374151),
                                        height: 1.5)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_examples.isNotEmpty) ...[
                  _buildCard(
                    icon: Icons.lightbulb_outline,
                    title: 'Examples',
                    child: GridView.builder(
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
                        final ex = _examples[index];
                        final color =
                            _colorFromString(ex['color'] as String? ?? 'blue');
                        return _buildExampleCard(
                          icon: ex['icon'] as String? ?? '🔹',
                          name: ex['name'] as String? ?? '',
                          color: color,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Start Quiz button ──────────────────────────
                if (_questions.isNotEmpty)
                  _gradientButton(
                    label: 'Start Quiz',
                    suffix: '(${_questions.length} questions)',
                    icon: Icons.quiz,
                    onTap: _startQuiz,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No quiz questions yet.\nYour teacher will add them soon!',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
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
  //  PAGE 2: QUIZ
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildQuizPage() {
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final q = _questions[_currentQuestionIndex];
    final options = List<String>.from(q['options'] as List);
    final selectedIdx = _selectedAnswers[_currentQuestionIndex];

    return Column(
      children: [
        // Header / progress
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _showExitQuizDialog,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} / ${_questions.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _questions.length,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Question + options
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question card
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
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _categoryBadge(q['category'] as String),
                        const SizedBox(width: 8),
                        _difficultyBadge(q['difficulty'] as String),
                      ]),
                      const SizedBox(height: 20),
                      Text(
                        q['question'] as String,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Option tiles — compared by INDEX (int), not string
                ...options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final text = entry.value;
                  final isSelected = selectedIdx == idx;

                  return GestureDetector(
                    onTap: () => _selectAnswer(idx),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
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
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          // Letter circle
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
                                String.fromCharCode(65 + idx),
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
                              text,
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
                            Icon(Icons.check_circle,
                                color: widget.color, size: 24),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Nav buttons
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ],
          ),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: widget.color),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Previous',
                        style: TextStyle(
                            color: widget.color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: selectedIdx != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    disabledBackgroundColor: widget.color.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _currentQuestionIndex == _questions.length - 1
                        ? 'Submit Quiz'
                        : 'Next Question',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
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
  //  PAGE 3: RESULTS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildResultsPage() {
    final percentage =
        _questions.isEmpty ? 0 : (_score / _questions.length * 100).round();
    final isPassed = percentage >= 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),

          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color:
                  (isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                      .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(isPassed ? '🎉' : '📚',
                  style: const TextStyle(fontSize: 60)),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            isPassed ? 'Congratulations!' : 'Keep Learning!',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
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

          // Stats card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(children: [
              _statRow('Correct Answers', '$_score / ${_questions.length}',
                  Icons.check_circle, const Color(0xFF10B981)),
              const Divider(height: 32),
              _statRow(
                  'Percentage', '$percentage%', Icons.percent, widget.color),
              if (_quizStartTime != null && _quizEndTime != null) ...[
                const Divider(height: 32),
                _statRow(
                    'Time Taken',
                    _formatDuration(_quizEndTime!.difference(_quizStartTime!)),
                    Icons.timer,
                    const Color(0xFF8B5CF6)),
              ],
            ]),
          ),

          const SizedBox(height: 24),

          // Review answers
          _buildCard(
            icon: Icons.list_alt,
            title: 'Review Your Answers',
            child: Column(
              children: _questions.asMap().entries.map((entry) {
                final i = entry.key;
                final q = entry.value;
                final correctIdx = q['correctAnswerIndex'] as int;
                final selectedIdx = _selectedAnswers[i];
                final opts = List<String>.from(q['options'] as List);
                final isCorrect =
                    selectedIdx != null && selectedIdx == correctIdx;

                final selectedText =
                    selectedIdx != null && selectedIdx < opts.length
                        ? opts[selectedIdx]
                        : 'No answer';
                final correctText =
                    correctIdx < opts.length ? opts[correctIdx] : '';

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
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(q['question'] as String,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937))),
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
                      _answerRow('Your answer:', selectedText, isCorrect),
                      if (!isCorrect)
                        _answerRow('Correct answer:', correctText, true),
                      if ((q['explanation'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '💡 ${q['explanation']}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              height: 1.4),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: widget.color),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back to Topic',
                      style: TextStyle(
                          color: widget.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Try Again',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
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
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCard(
      {required IconData icon, required String title, required Widget child}) {
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: widget.color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildExampleCard(
      {required String icon, required String name, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required String suffix,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [widget.color, widget.color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: widget.color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(suffix,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ),
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
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(category,
          style: TextStyle(
              color: widget.color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _difficultyBadge(String difficulty) {
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
      child: Text(difficulty,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Row(children: [
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
          child: Text(label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)))),
      Text(value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937))),
    ]);
  }

  Widget _answerRow(String label, String answer, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(answer,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isCorrect
                        ? const Color(0xFF10B981)
                        : const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  Color _colorFromString(String s) {
    switch (s.toLowerCase()) {
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Quiz?'),
        content: const Text(
            'Your progress will be lost if you exit now. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentPage = 0);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
