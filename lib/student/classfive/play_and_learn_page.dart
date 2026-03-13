import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mission_one_page.dart';
import 'student_question_view.dart';

class PlayAndLearnPage extends StatefulWidget {
  final String grade;
  const PlayAndLearnPage({super.key, this.grade = 'Grade 5'});

  @override
  State<PlayAndLearnPage> createState() => _PlayAndLearnPageState();
}

class _PlayAndLearnPageState extends State<PlayAndLearnPage>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalCoins = 0;
  int completedTopicsCount = 0;
  List<Map<String, dynamic>> _firestoreTopics = [];
  Set<String> _completedTopicIds = {};
  bool _loadingTopics = true;

  static const String _firstTopicId = 'what_is_matter';
  static const String _firstTopicName = 'What is Matter?';

  // ── Assigned quiz — loaded from grades/{grade}.assignedQuizId ──
  String? _assignedQuizId; // e.g. 'h62x2JgTUvLHj04zeXvm'
  String _assignedQuizTitle = 'Quiz';

  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _fabScaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut));
    _loadAllData();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async => Future.wait(
      [_loadQuizStats(), _loadFirestoreTopics(), _loadAssignedQuiz()]);

  Future<void> _loadQuizStats() async {
    if (user == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('quiz_stats')
          .doc('stats')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final completed = List<String>.from(data['completed_topics'] ?? []);
        setState(() {
          totalCoins = data['total_coins'] ?? 0;
          completedTopicsCount = completed.length;
          _completedTopicIds = completed.toSet();
        });
      }
    } catch (e) {
      debugPrint('Stats error: $e');
    }
  }

  Future<void> _loadFirestoreTopics() async {
    setState(() => _loadingTopics = true);
    try {
      final snap = await _firestore
          .collection('grades')
          .doc(widget.grade)
          .collection('topics')
          .orderBy('createdAt', descending: false)
          .get();
      final topics = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'name': d['name'] as String? ?? doc.id,
          'description': d['description'] as String? ?? ''
        };
      }).toList();
      // Remove the hardcoded first topic to avoid duplication
      topics.removeWhere((t) => t['id'] == _firstTopicId);
      setState(() {
        _firestoreTopics = topics;
        _loadingTopics = false;
      });
    } catch (e) {
      debugPrint('Topics error: $e');
      setState(() => _loadingTopics = false);
    }
  }

  // ── Load the quiz assigned by the teacher ──────────────────────
  // Teacher sets: grades/{grade}.assignedQuizId = 'h62x2JgTUvLHj04zeXvm'
  // Optionally:   grades/{grade}.assignedQuizTitle = 'matter'
  Future<void> _loadAssignedQuiz() async {
    try {
      final gradeDoc =
          await _firestore.collection('grades').doc(widget.grade).get();
      if (gradeDoc.exists) {
        final data = gradeDoc.data()!;
        final quizId = data['assignedQuizId'] as String?;
        // If no assignedQuizId on the grade doc, try getting it from the quizzes
        // collection directly (most recent quiz for this grade)
        if (quizId != null && quizId.isNotEmpty) {
          setState(() {
            _assignedQuizId = quizId;
            _assignedQuizTitle = data['assignedQuizTitle'] as String? ?? 'Quiz';
          });
        } else {
          // Fallback: load most recent quiz from quizzes collection
          await _loadLatestQuiz();
        }
      } else {
        await _loadLatestQuiz();
      }
    } catch (e) {
      debugPrint('Load assigned quiz error: $e');
      await _loadLatestQuiz();
    }
  }

  // Fallback: find the most recent quiz in the quizzes collection
  Future<void> _loadLatestQuiz() async {
    try {
      final snap = await _firestore
          .collection('quizzes')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        setState(() {
          _assignedQuizId = doc.id;
          _assignedQuizTitle = doc.data()['title'] as String? ?? 'Quiz';
        });
      }
    } catch (e) {
      debugPrint('Load latest quiz error: $e');
    }
  }

  List<_LessonItem> get _orderedLessons {
    final items = <_LessonItem>[];

    // 1. Fixed first lesson
    items.add(_LessonItem(
        id: _firstTopicId,
        title: _firstTopicName,
        icon: Icons.science_outlined,
        isFixedLesson: true,
        isQuiz: false));

    // 2. Dynamic Firestore topics
    for (final t in _firestoreTopics) {
      items.add(_LessonItem(
          id: t['id'] as String,
          title: t['name'] as String,
          icon: _iconForTopic(t['name'] as String),
          isFixedLesson: false,
          isQuiz: false));
    }

    // 3. Quiz — reads from quizzes/{assignedQuizId}/questions
    items.add(_LessonItem(
        id: 'quiz',
        title: _assignedQuizTitle,
        icon: Icons.quiz_outlined,
        isFixedLesson: false,
        isQuiz: true,
        quizTopicId: _assignedQuizId));

    return items;
  }

  bool _isUnlocked(int index) {
    if (index == 0) return true;
    final lessons = _orderedLessons;
    for (int i = 0; i < index; i++) {
      if (!_completedTopicIds.contains(lessons[i].id)) return false;
    }
    return true;
  }

  int get _completedLessonsCount =>
      _orderedLessons.where((l) => _completedTopicIds.contains(l.id)).length;
  int get _totalLessons => _orderedLessons.length - 1;

  IconData _iconForTopic(String name) {
    final n = name.toLowerCase();
    if (n.contains('molecule')) return Icons.bubble_chart;
    if (n.contains('state')) return Icons.gas_meter_outlined;
    if (n.contains('heat') || n.contains('temperature'))
      return Icons.thermostat;
    if (n.contains('water') || n.contains('dissolv')) return Icons.water_drop;
    if (n.contains('impurity') || n.contains('impurities'))
      return Icons.filter_alt;
    if (n.contains('removal') || n.contains('soluble')) return Icons.science;
    if (n.contains('property') || n.contains('properties'))
      return Icons.category;
    return Icons.menu_book_outlined;
  }

  // ── Navigate to quiz using quizzes/{assignedQuizId}/questions ──
  Future<void> _goToQuiz() async {
    if (_assignedQuizId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No quiz assigned yet. Ask your teacher! 👩‍🏫'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating));
      return;
    }
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StudentQuestionView(
                grade: widget.grade,
                quizId: _assignedQuizId!, // ← reads quizzes/{quizId}/questions
                studentId: user?.uid ?? '')));
    if (!mounted) return;
    if (result == true) {
      await _markTopicComplete('quiz');
      _loadAllData();
    }
  }

  Future<void> _navigateToLesson(_LessonItem lesson) async {
    // ── QUIZ ──────────────────────────────────────────────────────────────────
    if (lesson.isQuiz) {
      await _goToQuiz();
      return;
    }

    // ── FIXED FIRST LESSON ────────────────────────────────────────────────────
    if (lesson.isFixedLesson) {
      final result = await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MissionOnePage()));
      if (!mounted) return;
      if (result == true) {
        await _markTopicComplete(_firstTopicId);
        _loadAllData();
      }
      return;
    }

    // ── DYNAMIC FIRESTORE TOPIC ───────────────────────────────────────────────
    final lessons = _orderedLessons;
    final ci = lessons.indexWhere((l) => l.id == lesson.id);
    final ni = ci + 1;
    final next = ni < lessons.length ? lessons[ni] : null;

    final bool nextIsQuiz = next != null && next.isQuiz;
    final String nextLabel = next == null
        ? 'Finish'
        : nextIsQuiz
            ? 'Go to Quiz 🏆'
            : 'Next: ${next.title}';

    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _TopicContentPage(
                grade: widget.grade,
                topicId: lesson.id,
                topicName: lesson.title,
                studentId: user?.uid ?? '',
                nextLabel: nextLabel,
                onGoToQuiz: nextIsQuiz ? _goToQuiz : null)));
    if (!mounted) return;
    if (result == true) {
      await _markTopicComplete(lesson.id);
      _loadAllData();
    }
  }

  Future<void> _markTopicComplete(String topicId) async {
    if (user == null) return;
    try {
      final uid = user!.uid;
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('quiz_stats')
          .doc('stats');
      final doc = await ref.get();
      final completed = doc.exists
          ? List<String>.from(doc.data()?['completed_topics'] ?? [])
          : <String>[];
      if (!completed.contains(topicId)) {
        completed.add(topicId);
        if (doc.exists) {
          await ref.update({
            'completed_topics': completed,
            'last_updated': FieldValue.serverTimestamp()
          });
        } else {
          await ref.set({
            'completed_topics': completed,
            'total_quizzes': 0,
            'total_coins': 0,
            'total_questions': 0,
            'created_at': FieldValue.serverTimestamp(),
            'last_updated': FieldValue.serverTimestamp()
          });
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('completed_topics_$uid', completed);
        setState(() => _completedTopicIds = completed.toSet());
      }
    } catch (e) {
      debugPrint('markTopicComplete error: $e');
    }
  }

  void _showProgressSnackbar() {
    final pct = _totalLessons > 0
        ? (_completedLessonsCount / _totalLessons * 100).round()
        : 0;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Great progress! $_completedLessonsCount/$_totalLessons ($pct%) 🎉'),
        backgroundColor: const Color(0xFF9C27B0),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    final progressPct =
        _totalLessons > 0 ? _completedLessonsCount / _totalLessons : 0.0;
    final lessons = _orderedLessons;
    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back,
                    color: Color(0xFF006064), size: 20)),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: ScaleTransition(
            scale: _fabScaleAnim,
            child: GestureDetector(
                onTap: _showProgressSnackbar,
                child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF9C27B0)
                                  .withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ]),
                    child: const Center(
                        child: Text('🎉', style: TextStyle(fontSize: 28)))))),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(children: [
        Positioned.fill(child: Container(color: const Color(0xFFB2EBF2))),
        SafeArea(
          child: _loadingTopics
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCard(progressPct),
                        const SizedBox(height: 28),
                        const Text("What You'll Learn",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0))),
                        const SizedBox(height: 14),
                        ...List.generate(lessons.length, (i) {
                          final lesson = lessons[i];
                          return _buildLessonItem(
                              lesson: lesson,
                              index: i,
                              isUnlocked: _isUnlocked(i),
                              isCompleted:
                                  _completedTopicIds.contains(lesson.id));
                        }),
                      ])),
        ),
        Positioned(
            left: 16, right: 16, bottom: 16, child: _buildStartButton(lessons)),
      ]),
    );
  }

  Widget _buildStatsCard(double progressPct) {
    final pct = _totalLessons > 0
        ? ((_completedLessonsCount / _totalLessons) * 100).round()
        : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFF8E24AA)],
              stops: [0.0, 0.55, 1.0]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ]),
      child: Stack(children: [
        const Positioned(
            top: 6,
            right: 18,
            child: Opacity(
                opacity: 0.35,
                child: Text('⭐', style: TextStyle(fontSize: 18)))),
        const Positioned(
            bottom: 16,
            right: 36,
            child: Opacity(
                opacity: 0.4,
                child: Text('✨', style: TextStyle(fontSize: 14)))),
        Column(children: [
          Row(children: [
            Expanded(
                child: _statChip(Icons.quiz_rounded, '$completedTopicsCount',
                    'Topic master')),
            const SizedBox(width: 10),
            Expanded(
                child: _statChip(Icons.monetization_on_rounded, '$totalCoins',
                    'Total Coin')),
            const SizedBox(width: 10),
            Expanded(
                child: _statChip(
                    Icons.emoji_events_rounded, '$pct%', 'Achievements')),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Progress',
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Text('$_completedLessonsCount/$_totalLessons',
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: progressPct,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10)),
        ]),
      ]),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: const Color(0xFF9C27B0), size: 26),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121))),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildLessonItem(
      {required _LessonItem lesson,
      required int index,
      required bool isUnlocked,
      required bool isCompleted}) {
    final isQuiz = lesson.isQuiz;
    final accent = isQuiz ? const Color(0xFF00897B) : const Color(0xFF9C27B0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isUnlocked
                  ? accent.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isUnlocked ? () => _navigateToLesson(lesson) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: isUnlocked
                          ? accent.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : isUnlocked
                              ? lesson.icon
                              : Icons.lock_outline_rounded,
                      color: isCompleted
                          ? const Color(0xFF00C853)
                          : isUnlocked
                              ? accent
                              : Colors.grey.shade400,
                      size: 24)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(lesson.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey.shade400)),
                    if (isQuiz) ...[
                      const SizedBox(height: 3),
                      Text(
                          isUnlocked
                              ? 'Unlocked! Time to test yourself 🎯'
                              : 'Complete all lessons to unlock',
                          style: TextStyle(
                              fontSize: 11,
                              color: isUnlocked
                                  ? const Color(0xFF00897B)
                                  : Colors.grey.shade500)),
                    ],
                  ])),
              _statusBadge(
                  isUnlocked: isUnlocked,
                  isCompleted: isCompleted,
                  isQuiz: isQuiz,
                  accent: accent),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(
      {required bool isUnlocked,
      required bool isCompleted,
      required bool isQuiz,
      required Color accent}) {
    if (isCompleted) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle, color: Color(0xFF00C853), size: 13),
            SizedBox(width: 4),
            Text('Done',
                style: TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ]));
    }
    if (!isUnlocked) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 13),
            const SizedBox(width: 4),
            Text('Locked',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ]));
    }
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: accent, borderRadius: BorderRadius.circular(20)),
        child: Text(isQuiz ? 'Take Quiz' : 'Start',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)));
  }

  Widget _buildStartButton(List<_LessonItem> lessons) {
    _LessonItem? next;
    for (int i = 0; i < lessons.length; i++) {
      if (_isUnlocked(i) && !_completedTopicIds.contains(lessons[i].id)) {
        next = lessons[i];
        break;
      }
    }
    final allDone = next == null;
    return GestureDetector(
      onTap: next != null ? () => _navigateToLesson(next!) : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: allDone
                    ? [const Color(0xFF00C853), const Color(0xFF009624)]
                    : [const Color(0xFF7C4DFF), const Color(0xFFD500F9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: (allDone
                          ? const Color(0xFF00C853)
                          : const Color(0xFF7C4DFF))
                      .withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 7))
            ]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(allDone ? Icons.emoji_events_rounded : Icons.play_arrow_rounded,
              color: Colors.white, size: 28),
          const SizedBox(width: 8),
          Text(
              allDone
                  ? 'All Done! 🎉'
                  : next!.isQuiz
                      ? 'Take Quiz 🏆'
                      : 'Continue Learning',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.4)),
        ]),
      ),
    );
  }
}

class _LessonItem {
  final String id, title;
  final IconData icon;
  final bool isFixedLesson, isQuiz;
  final String? quizTopicId;
  const _LessonItem(
      {required this.id,
      required this.title,
      required this.icon,
      required this.isFixedLesson,
      required this.isQuiz,
      this.quizTopicId});
}

// ═══════════════════════════════════════════════════════════════
//  TOPIC CONTENT PAGE
// ═══════════════════════════════════════════════════════════════
class _TopicContentPage extends StatefulWidget {
  final String grade;
  final String topicId;
  final String topicName;
  final String studentId;
  final String nextLabel;
  final Future<void> Function()? onGoToQuiz;

  const _TopicContentPage({
    required this.grade,
    required this.topicId,
    required this.topicName,
    required this.studentId,
    this.nextLabel = 'Next Lesson',
    this.onGoToQuiz,
  });

  @override
  State<_TopicContentPage> createState() => _TopicContentPageState();
}

class _TopicContentPageState extends State<_TopicContentPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _hasContent = false;
  bool _visible = false;
  bool _launchingQuiz = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      if (!_hasScrolledToBottom) setState(() => _hasScrolledToBottom = true);
    }
  }

  Future<void> _completeAndContinue() async {
    if (widget.onGoToQuiz != null) {
      Navigator.pop(context, true);
      await widget.onGoToQuiz!();
    } else {
      Navigator.pop(context, true);
    }
  }

  Color _cardColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'blue':
        return const Color(0xFFE3F2FD);
      case 'purple':
        return const Color(0xFFF3E5F5);
      case 'green':
        return const Color(0xFFE8F5E9);
      case 'red':
        return const Color(0xFFFFEBEE);
      case 'orange':
        return const Color(0xFFFFF3E0);
      case 'pink':
        return const Color(0xFFFCE4EC);
      case 'cyan':
        return const Color(0xFFE0F7FA);
      case 'yellow':
        return const Color(0xFFFFFDE7);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color _cardTextColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'blue':
        return const Color(0xFF1565C0);
      case 'purple':
        return const Color(0xFF6A1B9A);
      case 'green':
        return const Color(0xFF2E7D32);
      case 'red':
        return const Color(0xFFC62828);
      case 'orange':
        return const Color(0xFFE65100);
      case 'pink':
        return const Color(0xFFAD1457);
      case 'cyan':
        return const Color(0xFF00838F);
      case 'yellow':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF1565C0);
    }
  }

  String _heroEmojiForTopic(String topicName) {
    final n = topicName.toLowerCase();
    if (n.contains('molecule')) return '⚗️';
    if (n.contains('state')) return '🌡️';
    if (n.contains('matter')) return '🧪';
    if (n.contains('water') || n.contains('dissolv')) return '💧';
    if (n.contains('heat') || n.contains('temperature')) return '🔥';
    if (n.contains('impurit')) return '🔬';
    if (n.contains('property') || n.contains('properties')) return '📊';
    return '🧪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('grades')
            .doc(widget.grade)
            .collection('topics')
            .doc(widget.topicId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          String description = '';
          List<String> keyPoints = [];
          List<Map<String, dynamic>> examples = [];

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            description = data['description'] as String? ?? '';
            keyPoints = List<String>.from(data['keyPoints'] ?? []);
            final rawExamples = data['examples'] as List<dynamic>? ?? [];
            examples = rawExamples
                .map((e) {
                  if (e is Map) {
                    return {
                      'name': (e['name'] as String? ?? '').trim(),
                      'icon': (e['icon'] as String? ?? '').trim(),
                      'color': e['color'] as String? ?? 'blue',
                    };
                  }
                  return {
                    'name': e.toString().trim(),
                    'icon': '',
                    'color': 'blue'
                  };
                })
                .where((e) => (e['name'] as String).isNotEmpty)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }

          _hasContent = description.isNotEmpty ||
              keyPoints.isNotEmpty ||
              examples.isNotEmpty;
          final bool buttonActive = !_hasContent || _hasScrolledToBottom;

          return Stack(children: [
            SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
                                          blurRadius: 8)
                                    ]),
                                child: const Icon(Icons.arrow_back_ios_new,
                                    size: 16, color: Color(0xFF555555))),
                          ),
                          const Spacer(),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFC107),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFFFFC107)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10)
                                  ]),
                              child: const Row(children: [
                                Text('⭐', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text('Level 1',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ])),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFFE91E63)]),
                            borderRadius: BorderRadius.circular(30)),
                        child: Text('SCIENCE · ${widget.grade.toUpperCase()}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(widget.topicName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A2E))),
                      ),
                      const SizedBox(height: 20),
                      _FadeIn(
                        visible: _visible,
                        delay: 0,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF9C27B0),
                                    Color(0xFFE91E63)
                                  ]),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF9C27B0)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8))
                              ]),
                          child: Center(
                              child: Text(_heroEmojiForTopic(widget.topicName),
                                  style: const TextStyle(fontSize: 56))),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (description.isNotEmpty || keyPoints.isNotEmpty)
                        _FadeIn(
                          visible: _visible,
                          delay: 80,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (description.isNotEmpty) ...[
                                    Row(children: [
                                      const Text('📖',
                                          style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(description,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF555555),
                                                  height: 1.6))),
                                    ]),
                                  ],
                                  if (keyPoints.isNotEmpty) ...[
                                    if (description.isNotEmpty)
                                      const SizedBox(height: 14),
                                    ...keyPoints.map((kp) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                    width: 22,
                                                    height: 22,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 1),
                                                    decoration:
                                                        const BoxDecoration(
                                                            color: Color(
                                                                0xFFEDE7F6),
                                                            shape: BoxShape
                                                                .circle),
                                                    child: const Center(
                                                        child: Icon(Icons.check,
                                                            size: 13,
                                                            color: Color(
                                                                0xFF7C4DFF)))),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                    child: Text(kp,
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            color: Color(
                                                                0xFF333333),
                                                            height: 1.5))),
                                              ]),
                                        )),
                                  ],
                                ]),
                          ),
                        ),
                      if (examples.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _FadeIn(
                          visible: _visible,
                          delay: 160,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Text('✨',
                                        style: TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            'Examples of ${widget.topicName}',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1A1A2E)))),
                                  ]),
                                  const SizedBox(height: 14),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 14,
                                            mainAxisSpacing: 14,
                                            childAspectRatio: 1.0),
                                    itemCount: examples.length,
                                    itemBuilder: (_, i) {
                                      final ex = examples[i];
                                      final name = ex['name'] as String;
                                      final icon = ex['icon'] as String;
                                      final color = ex['color'] as String;
                                      return Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3))
                                            ]),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                    color: _cardColor(color),
                                                    shape: BoxShape.circle),
                                                child: Center(
                                                    child: Text(
                                                        icon.isNotEmpty
                                                            ? icon
                                                            : '🔹',
                                                        style: const TextStyle(
                                                            fontSize: 30))),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(name,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _cardTextColor(
                                                          color)),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ]),
                                      );
                                    },
                                  ),
                                ]),
                          ),
                        ),
                      ],
                      if (!_hasContent)
                        _FadeIn(
                          visible: _visible,
                          delay: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 48, horizontal: 32),
                            child: Column(children: [
                              Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.07),
                                            blurRadius: 16)
                                      ]),
                                  child: const Center(
                                      child: Text('📖',
                                          style: TextStyle(fontSize: 48)))),
                              const SizedBox(height: 20),
                              Text(widget.topicName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0))),
                              const SizedBox(height: 8),
                              Text(
                                  'Your teacher will add content\nfor this topic soon!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      height: 1.5)),
                              const SizedBox(height: 6),
                              Text('You can continue to the next lesson 👇',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic)),
                            ]),
                          ),
                        ),
                      if (_hasContent && !_hasScrolledToBottom) ...[
                        const SizedBox(height: 16),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.keyboard_arrow_down,
                                  color: Color(0xFF7C4DFF), size: 20),
                              const SizedBox(width: 6),
                              Text('Scroll down to continue',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                            ]),
                      ],
                      const SizedBox(height: 20),
                    ]),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AnimatedOpacity(
                opacity: buttonActive ? 1.0 : 0.45,
                duration: const Duration(milliseconds: 500),
                child: GestureDetector(
                  onTap: buttonActive ? _completeAndContinue : null,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: buttonActive
                                ? widget.onGoToQuiz != null
                                    ? [
                                        const Color(0xFFFF8F00),
                                        const Color(0xFFFFCA28)
                                      ]
                                    : [
                                        const Color(0xFF7C4DFF),
                                        const Color(0xFF9C27B0)
                                      ]
                                : [Colors.grey.shade400, Colors.grey.shade500]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: buttonActive
                            ? [
                                BoxShadow(
                                    color: (widget.onGoToQuiz != null
                                            ? const Color(0xFFFF8F00)
                                            : const Color(0xFF7C4DFF))
                                        .withValues(alpha: 0.45),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8))
                              ]
                            : []),
                    child: _launchingQuiz
                        ? const Center(
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5)))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text(widget.nextLabel,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 12),
                                Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Icon(
                                        widget.onGoToQuiz != null
                                            ? Icons.emoji_events_rounded
                                            : Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18)),
                              ]),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF9C27B0)]),
              borderRadius: BorderRadius.circular(20)),
          child:
              const Center(child: Text('📚', style: TextStyle(fontSize: 40)))),
      const SizedBox(height: 20),
      const CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      const SizedBox(height: 16),
      const Text('Loading content...',
          style:
              TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w600)),
    ]));
  }
}

class _FadeIn extends StatelessWidget {
  final bool visible;
  final int delay;
  final Widget child;
  const _FadeIn(
      {required this.visible, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: visible ? 1.0 : 0.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 18 * (1 - v)), child: child)),
      child: child,
    );
  }
}
