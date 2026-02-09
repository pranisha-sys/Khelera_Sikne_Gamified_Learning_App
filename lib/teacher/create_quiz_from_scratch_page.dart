import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateQuizFromScratchPage extends StatefulWidget {
  const CreateQuizFromScratchPage({super.key});

  @override
  State<CreateQuizFromScratchPage> createState() =>
      _CreateQuizFromScratchPageState();
}

class _CreateQuizFromScratchPageState extends State<CreateQuizFromScratchPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Quiz data
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isSaving = false;

  // Current question controllers
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerExplanationController =
      TextEditingController(); // ✅ NEW
  List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctAnswerIndex = 0;
  bool _hasTimeLimit = false;
  String _selectedTime = '1 minute 30 seconds';

  final List<String> _timeOptions = [
    '30 seconds',
    '1 minute',
    '1 minute 30 seconds',
    '2 minutes',
    '3 minutes',
    '5 minutes',
  ];

  @override
  void initState() {
    super.initState();
    _addInitialQuestion();
  }

  void _addInitialQuestion() {
    if (_questions.isEmpty) {
      _questions.add(QuizQuestion(
        question: '',
        options: ['', ''],
        correctAnswerIndex: 0,
        hasTimeLimit: false,
        timeLimit: '1 minute 30 seconds',
        answerExplanation: '', // ✅ NEW
      ));
    }
  }

  void _loadQuestion(int index) {
    final question = _questions[index];
    _questionController.text = question.question;
    _answerExplanationController.text = question.answerExplanation; // ✅ NEW
    _correctAnswerIndex = question.correctAnswerIndex;
    _hasTimeLimit = question.hasTimeLimit;
    _selectedTime = question.timeLimit;

    // Clear existing controllers
    for (var controller in _optionControllers) {
      controller.dispose();
    }

    // Create new controllers for options
    _optionControllers = question.options
        .map((option) => TextEditingController(text: option))
        .toList();
  }

  void _saveCurrentQuestion() {
    _questions[_currentQuestionIndex] = QuizQuestion(
      question: _questionController.text,
      options: _optionControllers.map((c) => c.text).toList(),
      correctAnswerIndex: _correctAnswerIndex,
      hasTimeLimit: _hasTimeLimit,
      timeLimit: _selectedTime,
      answerExplanation: _answerExplanationController.text, // ✅ NEW
    );
  }

  void _addOption() {
    if (_optionControllers.length < 4) {
      // ✅ CHANGED: from 6 to 4
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 options allowed')), // ✅ CHANGED
      );
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        if (_correctAnswerIndex >= _optionControllers.length) {
          _correctAnswerIndex = 0;
        }
      });
    }
  }

  void _addNextQuestion() {
    if (_questions.length >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 100 questions allowed')),
      );
      return;
    }

    _saveCurrentQuestion();

    setState(() {
      _questions.add(QuizQuestion(
        question: '',
        options: ['', ''],
        correctAnswerIndex: 0,
        hasTimeLimit: false,
        timeLimit: '1 minute 30 seconds',
        answerExplanation: '', // ✅ NEW
      ));
      _currentQuestionIndex = _questions.length - 1;
      _loadQuestion(_currentQuestionIndex);
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Question ${_currentQuestionIndex} saved! Now editing Question ${_currentQuestionIndex + 1}'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _saveCurrentQuestion();
      setState(() {
        _currentQuestionIndex--;
        _loadQuestion(_currentQuestionIndex);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing Question ${_currentQuestionIndex + 1}'),
          backgroundColor: const Color(0xFF3B82F6),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is the first question'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showQuestionSelector() {
    _saveCurrentQuestion();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Question'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              final questionPreview = question.question.isEmpty
                  ? 'Question ${index + 1} (Empty)'
                  : question.question;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: index == _currentQuestionIndex
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  questionPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: index == _currentQuestionIndex
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text('${question.options.length} options'),
                trailing: index == _currentQuestionIndex
                    ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentQuestionIndex = index;
                    _loadQuestion(_currentQuestionIndex);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Viewing Question ${index + 1}'),
                      backgroundColor: const Color(0xFF3B82F6),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveQuizDialog() async {
    final titleController = TextEditingController();
    final topicController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Quiz'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Quiz Title',
                hintText: 'Enter quiz title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Topic (Optional)',
                hintText: 'e.g., Mathematics, Science',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a quiz title'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, {
                'title': titleController.text.trim(),
                'topic': topicController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveQuiz(result['title']!, result['topic']!);
    }
  }

  Future<void> _saveQuiz(String title, String topic) async {
    _saveCurrentQuestion();

    // Validate
    if (_questions.any((q) => q.question.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all questions')),
      );
      return;
    }

    if (_questions.any((q) => q.options.any((o) => o.trim().isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all answer options')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create quiz document
      final quizRef = _firestore.collection('quizzes').doc();

      final quizData = {
        'teacherId': user.uid,
        'title': title,
        'topic': topic,
        'questionCount': _questions.length,
        'totalStudents': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await quizRef.set(quizData);

      // Save questions
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        await quizRef.collection('questions').doc('question_$i').set({
          'questionNumber': i + 1,
          'question': question.question,
          'options': question.options,
          'correctAnswerIndex': question.correctAnswerIndex,
          'hasTimeLimit': question.hasTimeLimit,
          'timeLimit': question.timeLimit,
          'answerExplanation':
              question.answerExplanation, // ✅ NEW: Save explanation
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz saved successfully! 🎉'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to quizzes page
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerExplanationController.dispose(); // ✅ NEW
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Quiz',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.edit,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showQuestionSelector,
                      icon: const Icon(Icons.list, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      tooltip: 'View all questions',
                    ),
                  ],
                ),
              ),

              // ── Info Box ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Maximum 100 questions allowed • Maximum 4 options per question',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // ── Main Content ──
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Question Input ──
                        const Text(
                          'Question',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _questionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type your question here...',
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Answer Options ──
                        Row(
                          children: [
                            const Text(
                              'Answer Options',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Tap to select correct answer',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ...List.generate(_optionControllers.length, (index) {
                          return _buildOptionField(index);
                        }),

                        const SizedBox(height: 12),

                        // ── Add Option Button ──
                        if (_optionControllers.length <
                            4) // ✅ CHANGED: Only show if less than 4
                          InkWell(
                            onTap: _addOption,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF3B82F6),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add,
                                      color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Option (${_optionControllers.length}/4)', // ✅ CHANGED: Show count
                                    style: const TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // ✅ NEW: Answer Explanation Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Answer Explanation',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          'Students will see this after answering',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _answerExplanationController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      'Explain why this is the correct answer and help students understand...',
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(
                                        left: 12, right: 8, top: 12),
                                    child: Icon(Icons.description,
                                        color: Color(0xFF8B5CF6)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF8B5CF6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'This explanation will be shown to students along with the correct answer (Option ${_correctAnswerIndex + 1})',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B21A8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Time Limit ──
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.timer_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Time Limit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _hasTimeLimit,
                                    onChanged: (value) {
                                      setState(() => _hasTimeLimit = value);
                                    },
                                    activeColor: const Color(0xFF3B82F6),
                                  ),
                                ],
                              ),
                              if (_hasTimeLimit) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF9C3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedTime,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      items: _timeOptions.map((time) {
                                        return DropdownMenuItem(
                                          value: time,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  color: Color(0xFFFBBF24),
                                                  size: 16),
                                              const SizedBox(width: 8),
                                              Text(time),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => _selectedTime = value!);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Students will have $_selectedTime to answer this question',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Set how long students have to answer each question',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom Actions ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add Next Question Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addNextQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Add Next Question',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Previous Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _goToPreviousQuestion,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_back,
                                      color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentQuestionIndex > 0
                                        ? 'Previous'
                                        : 'First',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Save Quiz Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _showSaveQuizDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Save Quiz',
                                          style: TextStyle(
                                            fontSize: 16,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionField(int index) {
    final isCorrect = _correctAnswerIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Checkmark button to mark as correct
          InkWell(
            onTap: () {
              setState(() => _correctAnswerIndex = index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Option ${index + 1} marked as correct answer ✓'),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFF10B981) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                boxShadow: isCorrect
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  color: isCorrect ? Colors.white : const Color(0xFFD1D5DB),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Option Input
          Expanded(
            child: TextField(
              controller: _optionControllers[index],
              decoration: InputDecoration(
                hintText: 'Option ${index + 1}',
                filled: true,
                fillColor: isCorrect
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: isCorrect
                      ? const BorderSide(color: Color(0xFF10B981), width: 2)
                      : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: isCorrect
                      ? const BorderSide(color: Color(0xFF10B981), width: 2)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isCorrect
                        ? const Color(0xFF10B981)
                        : const Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                suffixIcon: isCorrect
                    ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete Button (only if more than 2 options)
          if (_optionControllers.length > 2)
            IconButton(
              onPressed: () => _removeOption(index),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            ),
        ],
      ),
    );
  }
}

// ── Quiz Question Model ──
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final bool hasTimeLimit;
  final String timeLimit;
  final String answerExplanation; // ✅ NEW

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.hasTimeLimit,
    required this.timeLimit,
    required this.answerExplanation, // ✅ NEW
  });
}
