import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  TOPIC CONTENT EDITOR (For Teachers)
//  Step 1: Create and save topic content
//  Step 2: Then add quiz questions separately
// ═══════════════════════════════════════════════════════════════════════════
class TopicContentEditorPage extends StatefulWidget {
  final String firestoreGradeId;
  final String topicDocId;
  final String topicName;
  final String grade;
  final int topicNumber;
  final Color color;

  const TopicContentEditorPage({
    super.key,
    required this.firestoreGradeId,
    required this.topicDocId,
    required this.topicName,
    required this.grade,
    this.topicNumber = 1,
    required this.color,
  });

  @override
  State<TopicContentEditorPage> createState() => _TopicContentEditorPageState();
}

class _TopicContentEditorPageState extends State<TopicContentEditorPage> {
  final _formKey = GlobalKey<FormState>();

  DocumentReference get _topicRef => FirebaseFirestore.instance
      .collection('grades')
      .doc(widget.firestoreGradeId)
      .collection('topics')
      .doc(widget.topicDocId);

  final TextEditingController _descriptionCtrl = TextEditingController();
  final List<Map<String, dynamic>> _exampleCtrls = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasContent = false;

  final List<String> _colorOptions = [
    'blue',
    'purple',
    'green',
    'orange',
    'red',
    'pink',
    'cyan',
    'yellow'
  ];

  @override
  void initState() {
    super.initState();
    _loadTopicContent();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    for (var ex in _exampleCtrls) {
      (ex['name'] as TextEditingController?)?.dispose();
      (ex['icon'] as TextEditingController?)?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTopicContent() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _topicRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _descriptionCtrl.text = data['description'] as String? ?? '';

        final examples = List<Map<String, dynamic>>.from(
            (data['examples'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map)));
        _exampleCtrls.clear();
        for (var ex in examples) {
          _exampleCtrls.add({
            'name': TextEditingController(text: ex['name'] as String? ?? ''),
            'icon': TextEditingController(text: ex['icon'] as String? ?? '🔹'),
            'color': ex['color'] as String? ?? 'blue',
          });
        }
        if (_exampleCtrls.isEmpty) _addNewExample();
        _hasContent = _descriptionCtrl.text.isNotEmpty || examples.isNotEmpty;
      } else {
        _addNewExample();
      }
    } catch (e) {
      _showSnackbar('Error loading content: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addNewExample() {
    _exampleCtrls.add({
      'name': TextEditingController(),
      'icon': TextEditingController(text: '🔹'),
      'color': 'blue',
    });
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final examples = _exampleCtrls
          .where((ex) =>
              (ex['name'] as TextEditingController).text.trim().isNotEmpty)
          .map((ex) => {
                'name': (ex['name'] as TextEditingController).text.trim(),
                'icon': (ex['icon'] as TextEditingController).text.trim(),
                'color': ex['color'],
              })
          .toList();

      await _topicRef.set({
        'name': widget.topicName,
        'description': _descriptionCtrl.text.trim(),
        'examples': examples,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackbar('Content saved successfully!', isError: false);
      setState(() {
        _hasContent = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackbar('Error saving content: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor:
          isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Content',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(widget.topicName,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          if (_hasContent)
            IconButton(
              icon: const Icon(Icons.quiz, color: Colors.white),
              tooltip: 'Manage Quiz Questions',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizQuestionsManagerPage(
                    firestoreGradeId: widget.firestoreGradeId,
                    topicDocId: widget.topicDocId,
                    topicName: widget.topicName,
                    color: widget.color,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.color))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: widget.color.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline, color: widget.color),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Create topic content first, then add quiz questions',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    _buildSectionCard(
                      title: 'Overview / Description',
                      icon: Icons.description_outlined,
                      child: TextFormField(
                        controller: _descriptionCtrl,
                        maxLines: 6,
                        decoration: _inputDecoration(
                            hint: 'Enter a brief overview of this topic...'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a description'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Examples
                    _buildSectionCard(
                      title: 'Examples',
                      icon: Icons.lightbulb_outline,
                      child: Column(
                        children: [
                          ..._exampleCtrls.asMap().entries.map((entry) {
                            final index = entry.key;
                            final ctrls = entry.value;
                            final currentColor = ctrls['color'] as String;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text('Example ${index + 1}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    const Spacer(),
                                    if (_exampleCtrls.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Color(0xFFDC2626), size: 20),
                                        onPressed: () {
                                          setState(() {
                                            (ctrls['name']
                                                    as TextEditingController?)
                                                ?.dispose();
                                            (ctrls['icon']
                                                    as TextEditingController?)
                                                ?.dispose();
                                            _exampleCtrls.removeAt(index);
                                          });
                                        },
                                      ),
                                  ]),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    SizedBox(
                                      width: 70,
                                      child: TextFormField(
                                        controller: ctrls['icon']
                                            as TextEditingController,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 28),
                                        maxLength: 2,
                                        decoration: _inputDecoration(hint: '🔹')
                                            .copyWith(counterText: ''),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: ctrls['name']
                                            as TextEditingController,
                                        decoration: _inputDecoration(
                                            hint: 'Example name (e.g., Water)'),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 12),
                                  const Text('Color:',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280))),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: _colorOptions.map((colorStr) {
                                      final color =
                                          _getColorFromString(colorStr);
                                      final isSelected =
                                          currentColor == colorStr;
                                      return GestureDetector(
                                        onTap: () => setState(
                                            () => ctrls['color'] = colorStr),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: isSelected
                                                ? Border.all(
                                                    color: Colors.white,
                                                    width: 3)
                                                : null,
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                        color: color
                                                            .withOpacity(0.5),
                                                        blurRadius: 8,
                                                        spreadRadius: 2)
                                                  ]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check,
                                                  color: Colors.white, size: 18)
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _addNewExample()),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Example'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.color,
                              side: BorderSide(color: widget.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Save Content',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),

                    if (_hasContent) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizQuestionsManagerPage(
                                firestoreGradeId: widget.firestoreGradeId,
                                topicDocId: widget.topicDocId,
                                topicName: widget.topicName,
                                color: widget.color,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: widget.color, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.quiz, color: widget.color),
                              const SizedBox(width: 12),
                              Text('Next: Add Quiz Questions',
                                  style: TextStyle(
                                      color: widget.color,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward,
                                  color: widget.color, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.color, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  QUIZ QUESTIONS MANAGER PAGE
//
//  FIX: correctAnswer is stored as an INT (index into options[]).
//       e.g. correctAnswer: 0  means options[0] is correct.
//       This matches the schema used by TopicDetailQuizPage and
//       StudentQuestionView — NO more String cast crashes.
// ═══════════════════════════════════════════════════════════════════════════
class QuizQuestionsManagerPage extends StatefulWidget {
  final String firestoreGradeId;
  final String topicDocId;
  final String topicName;
  final Color color;

  const QuizQuestionsManagerPage({
    super.key,
    required this.firestoreGradeId,
    required this.topicDocId,
    required this.topicName,
    required this.color,
  });

  @override
  State<QuizQuestionsManagerPage> createState() =>
      _QuizQuestionsManagerPageState();
}

class _QuizQuestionsManagerPageState extends State<QuizQuestionsManagerPage> {
  CollectionReference get _questionsRef => FirebaseFirestore.instance
      .collection('grades')
      .doc(widget.firestoreGradeId)
      .collection('topics')
      .doc(widget.topicDocId)
      .collection('questions');

  bool _showAddForm = false;
  bool _isSaving = false;

  // Form controllers
  final _questionCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _opt1Ctrl = TextEditingController();
  final _opt2Ctrl = TextEditingController();
  final _opt3Ctrl = TextEditingController();
  final _opt4Ctrl = TextEditingController();

  // ── correctAnswerIndex: 0=opt1, 1=opt2, 2=opt3, 3=opt4 ──
  int _correctAnswerIndex = 0;
  String _difficulty = 'Easy';

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    _opt1Ctrl.dispose();
    _opt2Ctrl.dispose();
    _opt3Ctrl.dispose();
    _opt4Ctrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  Save question — correctAnswer stored as INT index
  // ─────────────────────────────────────────────────────────────
  Future<void> _saveQuestion() async {
    final q = _questionCtrl.text.trim();
    final o1 = _opt1Ctrl.text.trim();
    final o2 = _opt2Ctrl.text.trim();

    if (q.isEmpty || o1.isEmpty || o2.isEmpty) {
      _showSnackbar('Please fill question and at least 2 options',
          isError: true);
      return;
    }

    // Build options list (skip empty optional ones)
    final options = <String>[
      o1,
      o2,
      if (_opt3Ctrl.text.trim().isNotEmpty) _opt3Ctrl.text.trim(),
      if (_opt4Ctrl.text.trim().isNotEmpty) _opt4Ctrl.text.trim(),
    ];

    // Clamp correct index to valid range
    final correctIdx = _correctAnswerIndex.clamp(0, options.length - 1);

    // Get current question count for `order` field
    final snap = await _questionsRef.get();
    final order = snap.docs.length + 1;

    setState(() => _isSaving = true);
    try {
      await _questionsRef.add({
        'question': q,
        'options': options,
        'correctAnswer': correctIdx, // ← INT index, not String text
        'explanation': _explanationCtrl.text.trim().isEmpty
            ? 'Great thinking!'
            : _explanationCtrl.text.trim(),
        'category': 'General',
        'difficulty': _difficulty,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reset form
      _questionCtrl.clear();
      _explanationCtrl.clear();
      _opt1Ctrl.clear();
      _opt2Ctrl.clear();
      _opt3Ctrl.clear();
      _opt4Ctrl.clear();
      setState(() {
        _correctAnswerIndex = 0;
        _difficulty = 'Easy';
        _isSaving = false;
        _showAddForm = false;
      });

      _showSnackbar('Question added successfully!', isError: false);
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackbar('Error: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor:
          isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─────────────────────────────────────────────────────────────
  //  Helper: safely parse correctAnswer from Firestore
  //  (handles both old String docs and new int docs)
  // ─────────────────────────────────────────────────────────────
  int _parseCorrectIndex(dynamic raw, List options) {
    if (raw is int) return raw.clamp(0, options.length - 1);
    if (raw is String) {
      // Legacy: stored as option text — find its index
      final idx = options.indexOf(raw);
      if (idx != -1) return idx;
      // Legacy: stored as "Option 1" label
      final labelIdx = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
      if (labelIdx != null) return (labelIdx - 1).clamp(0, options.length - 1);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quiz Questions',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(widget.topicName,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(children: [
              Expanded(
                child: Text(
                  _showAddForm ? 'New Question Form' : 'Manage Quiz Questions',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showAddForm = !_showAddForm),
                icon: Icon(_showAddForm ? Icons.close : Icons.add),
                label: Text(_showAddForm ? 'Cancel' : 'Add Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showAddForm ? Colors.grey : widget.color,
                  foregroundColor: Colors.white,
                ),
              ),
            ]),
          ),

          Expanded(
            child:
                _showAddForm ? _buildAddQuestionForm() : _buildQuestionsList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ADD QUESTION FORM
  // ─────────────────────────────────────────────────────────────
  Widget _buildAddQuestionForm() {
    // Build current options list for the dropdown preview
    final currentOptions = <String>[
      if (_opt1Ctrl.text.isNotEmpty) _opt1Ctrl.text,
      if (_opt2Ctrl.text.isNotEmpty) _opt2Ctrl.text,
      if (_opt3Ctrl.text.isNotEmpty) _opt3Ctrl.text,
      if (_opt4Ctrl.text.isNotEmpty) _opt4Ctrl.text,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // ── Question ──────────────────────────────────────
            _fieldLabel('Question *'),
            const SizedBox(height: 8),
            TextField(
              controller: _questionCtrl,
              maxLines: 3,
              decoration: _inputDecoration(hint: 'Enter your question...'),
            ),

            const SizedBox(height: 20),

            // ── Options ───────────────────────────────────────
            _fieldLabel('Answer Options'),
            const SizedBox(height: 8),
            _buildOptionField('Option A *', _opt1Ctrl, index: 0),
            _buildOptionField('Option B *', _opt2Ctrl, index: 1),
            _buildOptionField('Option C (optional)', _opt3Ctrl, index: 2),
            _buildOptionField('Option D (optional)', _opt4Ctrl, index: 3),

            const SizedBox(height: 20),

            // ── Correct Answer (int-based radio) ──────────────
            _fieldLabel('Correct Answer *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: List.generate(4, (i) {
                  final controllers = [
                    _opt1Ctrl,
                    _opt2Ctrl,
                    _opt3Ctrl,
                    _opt4Ctrl
                  ];
                  final labels = ['A', 'B', 'C', 'D'];
                  final text = controllers[i].text.trim();
                  // Only show options that have text
                  if (i >= 2 && text.isEmpty) return const SizedBox.shrink();
                  return RadioListTile<int>(
                    value: i,
                    groupValue: _correctAnswerIndex,
                    activeColor: widget.color,
                    title: Text(
                      text.isEmpty
                          ? 'Option ${labels[i]} (fill above)'
                          : '${labels[i]}: $text',
                      style: TextStyle(
                        fontSize: 14,
                        color: text.isEmpty
                            ? Colors.grey
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    onChanged: text.isEmpty
                        ? null
                        : (val) => setState(() => _correctAnswerIndex = val!),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // ── Explanation ───────────────────────────────────
            _fieldLabel('Explanation (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _explanationCtrl,
              maxLines: 2,
              decoration: _inputDecoration(
                  hint:
                      'Why is this the correct answer? e.g., Matter is anything that has mass and takes up space.'),
            ),

            const SizedBox(height: 20),

            // ── Difficulty ────────────────────────────────────
            _fieldLabel('Difficulty'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _difficulty,
                  isExpanded: true,
                  items: ['Easy', 'Medium', 'Hard']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) => setState(() => _difficulty = val!),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Save button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text('Save Question',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionField(String label, TextEditingController ctrl,
      {required int index}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        // Rebuild form on change so radio list updates live
        onChanged: (_) => setState(() {}),
        decoration: _inputDecoration(hint: label),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151)),
      );

  // ─────────────────────────────────────────────────────────────
  //  QUESTIONS LIST
  // ─────────────────────────────────────────────────────────────
  Widget _buildQuestionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _questionsRef.orderBy('order', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: widget.color));
        }
        if (snapshot.hasError) {
          // Fallback: try without ordering (index may not exist yet)
          return StreamBuilder<QuerySnapshot>(
            stream: _questionsRef.snapshots(),
            builder: (context, snap2) {
              if (!snap2.hasData || snap2.data!.docs.isEmpty) {
                return _buildEmptyState();
              }
              return _buildList(snap2.data!.docs);
            },
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }
        return _buildList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No questions yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          const Text('Tap "+ Add Question" to get started!',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final question = data['question']?.toString() ?? '';
        final rawOptions = data['options'] as List<dynamic>? ?? [];
        final options = rawOptions.map((o) => o.toString()).toList();

        // ── Safe int parsing — handles both old String and new int ──
        final correctIdx = _parseCorrectIndex(data['correctAnswer'], options);

        final explanation = data['explanation']?.toString() ?? '';
        final difficulty = data['difficulty']?.toString() ?? 'Easy';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: widget.color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.05),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: widget.color, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(question,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1F2937))),
                  ),
                  // Difficulty badge
                  _difficultyBadge(difficulty),
                  const SizedBox(width: 8),
                  // Delete
                  GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete Question?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626)),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await doc.reference.delete();
                        _showSnackbar('Question deleted', isError: false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Color(0xFFDC2626), size: 18),
                    ),
                  ),
                ]),
              ),

              // ── Options ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...options.asMap().entries.map((e) {
                      final i = e.key;
                      final opt = e.value;
                      final isCorrect = i == correctIdx;
                      final label = String.fromCharCode(65 + i); // A,B,C,D

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? const Color(0xFF10B981).withOpacity(0.08)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCorrect
                                ? const Color(0xFF10B981).withOpacity(0.4)
                                : const Color(0xFFE5E7EB),
                            width: isCorrect ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF10B981)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCorrect
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: Center(
                              child: isCorrect
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : Text(label,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6B7280))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(opt,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isCorrect
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF374151),
                                    fontWeight: isCorrect
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                          ),
                          if (isCorrect)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('CORRECT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                            ),
                        ]),
                      );
                    }),

                    // Explanation
                    if (explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Text(explanation,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(difficulty,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.color, width: 2)),
    );
  }
}
