import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modern Question Dialog - Shows all teacher questions
void showModernQuestionDialog({
  required BuildContext context,
  required Function(Map<String, dynamic>) onQuestionAdded,
  required int currentQuestionCount,
  required int maxQuestions,
  Map<String, dynamic>? existingQuestion,
  int? editIndex,
}) {
  final questionController = TextEditingController(
    text: existingQuestion?['question'] ?? '',
  );
  final option1Controller = TextEditingController(
    text: existingQuestion?['options']?[0] ?? '',
  );
  final option2Controller = TextEditingController(
    text: existingQuestion?['options']?[1] ?? '',
  );
  final option3Controller = TextEditingController(
    text: existingQuestion?['options']?[2] ?? '',
  );
  final option4Controller = TextEditingController(
    text: existingQuestion?['options']?[3] ?? '',
  );
  int correctAnswerIndex = existingQuestion?['correctAnswer'] ?? 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.quiz_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existingQuestion != null
                                      ? 'Edit Question'
                                      : 'Add Question',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Q${editIndex != null ? editIndex + 1 : currentQuestionCount + 1} of $maxQuestions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Question Section
                          _buildSectionLabel('Question', Icons.help_outline),
                          const SizedBox(height: 10),
                          _buildQuestionField(questionController),

                          const SizedBox(height: 24),

                          // Answer Options Section
                          _buildSectionLabel(
                            'Answer Options',
                            Icons.list_alt_rounded,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tap the circle to mark the correct answer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Option 1
                          _buildModernOptionField(
                            label: 'Option 1',
                            controller: option1Controller,
                            index: 0,
                            isCorrect: correctAnswerIndex == 0,
                            onTapCorrect: () {
                              setState(() => correctAnswerIndex = 0);
                            },
                          ),
                          const SizedBox(height: 10),

                          // Option 2
                          _buildModernOptionField(
                            label: 'Option 2',
                            controller: option2Controller,
                            index: 1,
                            isCorrect: correctAnswerIndex == 1,
                            onTapCorrect: () {
                              setState(() => correctAnswerIndex = 1);
                            },
                          ),
                          const SizedBox(height: 10),

                          // Option 3
                          _buildModernOptionField(
                            label: 'Option 3',
                            controller: option3Controller,
                            index: 2,
                            isCorrect: correctAnswerIndex == 2,
                            onTapCorrect: () {
                              setState(() => correctAnswerIndex = 2);
                            },
                          ),
                          const SizedBox(height: 10),

                          // Option 4
                          _buildModernOptionField(
                            label: 'Option 4',
                            controller: option4Controller,
                            index: 3,
                            isCorrect: correctAnswerIndex == 3,
                            onTapCorrect: () {
                              setState(() => correctAnswerIndex = 3);
                            },
                          ),

                          const SizedBox(height: 24),

                          // Correct Answer Indicator
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Correct Answer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Option ${correctAnswerIndex + 1}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF22C55E),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),

                    // Bottom Action Buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B7280),
                                  side: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (_validateQuestion(
                                    questionController,
                                    option1Controller,
                                    option2Controller,
                                    option3Controller,
                                    option4Controller,
                                  )) {
                                    final question = {
                                      'question':
                                          questionController.text.trim(),
                                      'options': [
                                        option1Controller.text.trim(),
                                        option2Controller.text.trim(),
                                        option3Controller.text.trim(),
                                        option4Controller.text.trim(),
                                      ],
                                      'correctAnswer': correctAnswerIndex,
                                      'createdAt':
                                          DateTime.now().millisecondsSinceEpoch,
                                      if (existingQuestion != null)
                                        'updatedAt': DateTime.now()
                                            .millisecondsSinceEpoch,
                                    };
                                    onQuestionAdded(question);
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please fill all fields'),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check_circle),
                                label: Text(
                                  existingQuestion != null
                                      ? 'Update Question'
                                      : 'Add Question',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildSectionLabel(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    ],
  );
}

Widget _buildQuestionField(TextEditingController controller) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1F2937),
      ),
      decoration: const InputDecoration(
        hintText: 'What is matter?',
        hintStyle: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 15,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
    ),
  );
}

Widget _buildModernOptionField({
  required String label,
  required TextEditingController controller,
  required int index,
  required bool isCorrect,
  required VoidCallback onTapCorrect,
}) {
  return Container(
    decoration: BoxDecoration(
      color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
        width: isCorrect ? 2 : 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Option Number Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  isCorrect ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text Field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter option text',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          // Correct Answer Selector
          GestureDetector(
            onTap: onTapCorrect,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect ? const Color(0xFF22C55E) : Colors.transparent,
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: Icon(
                isCorrect ? Icons.check : null,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

bool _validateQuestion(
  TextEditingController question,
  TextEditingController opt1,
  TextEditingController opt2,
  TextEditingController opt3,
  TextEditingController opt4,
) {
  return question.text.trim().isNotEmpty &&
      opt1.text.trim().isNotEmpty &&
      opt2.text.trim().isNotEmpty &&
      opt3.text.trim().isNotEmpty &&
      opt4.text.trim().isNotEmpty;
}

class MatterContentEditor extends StatefulWidget {
  final String grade; // e.g., "Grade 5"
  final String topicId; // e.g., "what_is_matter"

  const MatterContentEditor({
    Key? key,
    required this.grade,
    required this.topicId,
  }) : super(key: key);

  @override
  State<MatterContentEditor> createState() => _MatterContentEditorState();
}

class _MatterContentEditorState extends State<MatterContentEditor> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _funFactController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _examples = [];
  List<Map<String, dynamic>> _questions = [];
  String _searchQuery = '';
  int _currentPage = 0;

  final int _maxQuestions = 50;
  final int _questionsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _funFactController.dispose();
    super.dispose();
  }

  /// Load existing content from Firestore
  Future<void> _loadContent() async {
    setState(() => _isLoading = true);

    try {
      final docPath = 'grades/${widget.grade}/topics/${widget.topicId}';
      final doc = await _firestore.doc(docPath).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _funFactController.text = data['funFact'] ?? '';
          _examples = List<Map<String, dynamic>>.from(data['examples'] ?? []);
          _questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading content: $e');
      _showErrorSnackbar('Failed to load content: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Save content to Firestore
  Future<void> _saveContent() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackbar('Title cannot be empty');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final docPath = 'grades/${widget.grade}/topics/${widget.topicId}';

      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'funFact': _funFactController.text.trim(),
        'examples': _examples,
        'questions': _questions,
        'totalQuestions': _questions.length,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': 'admin',
        'version': 2,
      };

      await _firestore.doc(docPath).set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Content saved successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving content: $e');
      _showErrorSnackbar('Failed to save: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Get filtered questions based on search query
  List<Map<String, dynamic>> _getFilteredQuestions() {
    if (_searchQuery.isEmpty) {
      return _questions;
    }
    return _questions.where((q) {
      return q['question']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          q['options']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  /// Get paginated questions
  List<Map<String, dynamic>> _getPaginatedQuestions() {
    final filtered = _getFilteredQuestions();
    final startIndex = _currentPage * _questionsPerPage;
    final endIndex = startIndex + _questionsPerPage;
    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int _getTotalPages() {
    final filtered = _getFilteredQuestions();
    return (filtered.length / _questionsPerPage).ceil();
  }

  void _addExample() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final iconController = TextEditingController();
        String selectedColor = 'blue';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Add Example'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name (e.g., Books)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: iconController,
                      decoration: const InputDecoration(
                        labelText: 'Icon/Emoji (e.g., 📚)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedColor,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'blue', child: Text('Blue')),
                        DropdownMenuItem(value: 'cyan', child: Text('Cyan')),
                        DropdownMenuItem(value: 'pink', child: Text('Pink')),
                        DropdownMenuItem(
                            value: 'purple', child: Text('Purple')),
                        DropdownMenuItem(
                            value: 'orange', child: Text('Orange')),
                        DropdownMenuItem(value: 'green', child: Text('Green')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedColor = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        _examples.add({
                          'name': nameController.text.trim(),
                          'icon': iconController.text.trim(),
                          'color': selectedColor,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addQuestion() {
    if (_questions.length >= _maxQuestions) {
      _showErrorSnackbar('Maximum $_maxQuestions questions reached!');
      return;
    }

    showModernQuestionDialog(
      context: context,
      currentQuestionCount: _questions.length,
      maxQuestions: _maxQuestions,
      onQuestionAdded: (question) {
        setState(() {
          _questions.add(question);
        });
        _showSuccessSnackbar(
            'Question ${_questions.length} added successfully');
      },
    );
  }

  void _editQuestion(int index) {
    final question = _questions[index];

    showModernQuestionDialog(
      context: context,
      currentQuestionCount: _questions.length,
      maxQuestions: _maxQuestions,
      existingQuestion: question,
      editIndex: index,
      onQuestionAdded: (updatedQuestion) {
        setState(() {
          _questions[index] = updatedQuestion;
        });
        _showSuccessSnackbar('Question ${index + 1} updated successfully');
      },
    );
  }

  void _removeExample(int index) {
    setState(() {
      _examples.removeAt(index);
    });
  }

  void _removeQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Question?'),
          ],
        ),
        content: Text('Are you sure you want to delete question ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _questions.removeAt(index);
                if (_currentPage >= _getTotalPages() && _currentPage > 0) {
                  _currentPage--;
                }
              });
              Navigator.pop(context);
              _showSuccessSnackbar('Question deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return const Color(0xFF93C5FD);
      case 'cyan':
        return const Color(0xFF67E8F9);
      case 'pink':
        return const Color(0xFFFBCAFE);
      case 'purple':
        return const Color(0xFFC4B5FD);
      case 'orange':
        return const Color(0xFFFBBF24);
      case 'green':
        return const Color(0xFF86EFAC);
      default:
        return const Color(0xFF93C5FD);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF7C3AED),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Content Editor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.grade} - ${widget.topicId}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveContent,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C3AED),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Content',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Changes will be visible to students in real-time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title Section
                  _buildSectionHeader('Topic Title', Icons.title),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., What is Matter?',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF7C3AED), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  _buildSectionHeader('Description', Icons.description),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          'Matter is anything that takes up space and has weight!',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF7C3AED), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Examples Section
                  _buildSectionHeader('Examples', Icons.lightbulb),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        if (_examples.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No examples added yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _examples.asMap().entries.map((entry) {
                              final index = entry.key;
                              final example = entry.value;
                              return _buildExampleChip(
                                example['name'],
                                example['icon'] ?? '',
                                _getColorFromString(example['color'] ?? 'blue'),
                                () => _removeExample(index),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addExample,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Example'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7C3AED),
                              side: const BorderSide(color: Color(0xFF7C3AED)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fun Fact Section
                  _buildSectionHeader('Fun Fact 💡', Icons.stars),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _funFactController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          'Even the air you breathe is matter, even though you can\'t see it!',
                      filled: true,
                      fillColor: const Color(0xFFFAF5FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE9D5FF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE9D5FF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF7C3AED), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Questions Section with Pagination
                  _buildSectionHeader(
                      'Questions (${_questions.length}/$_maxQuestions)',
                      Icons.quiz),
                  const SizedBox(height: 12),

                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search questions...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Questions List with Pagination
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        if (_questions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No questions added yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          )
                        else ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _getPaginatedQuestions().length,
                            itemBuilder: (context, index) {
                              final filteredQuestions = _getFilteredQuestions();
                              final actualIndex =
                                  _currentPage * _questionsPerPage + index;
                              if (actualIndex >= filteredQuestions.length) {
                                return const SizedBox.shrink();
                              }
                              final question = filteredQuestions[actualIndex];
                              final displayIndex = actualIndex + 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C3AED),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Q$displayIndex',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            question['question'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 18,
                                              color: Color(0xFF7C3AED)),
                                          onPressed: () =>
                                              _editQuestion(actualIndex),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 18, color: Colors.red),
                                          onPressed: () =>
                                              _removeQuestion(actualIndex),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...List.generate(
                                      question['options'].length,
                                      (optIndex) {
                                        final isCorrect = optIndex ==
                                            question['correctAnswer'];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4, left: 32),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isCorrect
                                                    ? Icons.check_circle
                                                    : Icons
                                                        .radio_button_unchecked,
                                                size: 16,
                                                color: isCorrect
                                                    ? Colors.green
                                                    : const Color(0xFF9CA3AF),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  question['options'][optIndex],
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isCorrect
                                                        ? Colors.green
                                                        : const Color(
                                                            0xFF6B7280),
                                                    fontWeight: isCorrect
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Pagination Controls
                          if (_getTotalPages() > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                ),
                                Text(
                                  'Page ${_currentPage + 1} of ${_getTotalPages()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: _currentPage < _getTotalPages() - 1
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                ),
                              ],
                            ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _questions.length < _maxQuestions
                                ? _addQuestion
                                : null,
                            icon: const Icon(Icons.add),
                            label: Text(_questions.length < _maxQuestions
                                ? 'Add Question'
                                : 'Max Questions Reached'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE5E7EB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveContent,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save, size: 24),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save All Changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildExampleChip(
      String name, String icon, Color color, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon.isNotEmpty) ...[
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
          ],
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(1.0),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              size: 16,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
