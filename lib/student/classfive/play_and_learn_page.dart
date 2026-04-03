import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String? _assignedQuizId;
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
          .get();

      final topics = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'name': d['name'] as String? ?? doc.id,
          'description': d['description'] as String? ?? '',
          'createdAt': d['createdAt'],
        };
      }).toList();

      topics.sort((a, b) {
        final ta = a['createdAt'];
        final tb = b['createdAt'];
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return (ta as Timestamp).compareTo(tb as Timestamp);
      });

      // Remove what_is_matter from the dynamic list — it is pinned
      // manually as the first item in _orderedLessons.
      topics.removeWhere((t) => t['id'] == _firstTopicId);

      setState(() {
        _firestoreTopics = topics;
        _loadingTopics = false;
      });

      debugPrint('✅ Loaded ${topics.length} topics for ${widget.grade}');
    } catch (e) {
      debugPrint('❌ Topics error: $e');
      setState(() => _loadingTopics = false);
    }
  }

  Future<void> _loadAssignedQuiz() async {
    try {
      final gradeDoc =
          await _firestore.collection('grades').doc(widget.grade).get();

      if (gradeDoc.exists) {
        final data = gradeDoc.data()!;
        final quizId = data['assignedQuizId'] as String?;
        if (quizId != null && quizId.isNotEmpty) {
          setState(() {
            _assignedQuizId = quizId;
            _assignedQuizTitle = data['assignedQuizTitle'] as String? ?? 'Quiz';
          });
          return;
        }
      }
      await _loadLatestQuiz();
    } catch (e) {
      debugPrint('Load assigned quiz error: $e');
      await _loadLatestQuiz();
    }
  }

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
        debugPrint('✅ Loaded latest quiz: $_assignedQuizId');
      }
    } catch (e) {
      debugPrint('Load latest quiz error: $e');
    }
  }

  List<_LessonItem> get _orderedLessons {
    final items = <_LessonItem>[];
    items.add(_LessonItem(
        id: _firstTopicId,
        title: _firstTopicName,
        icon: Icons.science_outlined,
        isFixedLesson: true,
        isQuiz: false));
    for (final t in _firestoreTopics) {
      items.add(_LessonItem(
          id: t['id'] as String,
          title: t['name'] as String,
          icon: _iconForTopic(t['name'] as String),
          isFixedLesson: false,
          isQuiz: false));
    }
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
                quizId: _assignedQuizId!,
                studentId: user?.uid ?? '')));
    if (!mounted) return;
    if (result == true) {
      await _markTopicComplete('quiz');
      _loadAllData();
    }
  }

  // ✅ FIXED: All topics — including what_is_matter — go through
  // _openTopicContentPage so TopicInlineQuizPage always loads the
  // grades/{grade}/topics/{topicId}/questions subcollection correctly.
  // MissionOnePage is no longer used as a navigation gate.
  Future<void> _navigateToLesson(_LessonItem lesson) async {
    if (lesson.isQuiz) {
      await _goToQuiz();
      return;
    }
    await _openTopicContentPage(lesson);
  }

  Future<void> _openTopicContentPage(_LessonItem lesson) async {
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
  bool _visible = false;
  bool _launchingQuiz = false;

  late final Future<_TopicData> _topicDataFuture;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _topicDataFuture = _loadTopicData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<_TopicData> _loadTopicData() async {
    final topicRef = FirebaseFirestore.instance
        .collection('grades')
        .doc(widget.grade)
        .collection('topics')
        .doc(widget.topicId);

    debugPrint('=== LOADING TOPIC ===');
    debugPrint('Grade: ${widget.grade}');
    debugPrint('TopicId: ${widget.topicId}');
    debugPrint('Path: grades/${widget.grade}/topics/${widget.topicId}');

    final results = await Future.wait([
      topicRef.get(),
      topicRef.collection('questions').get(),
    ]);

    final topicSnap = results[0] as DocumentSnapshot;
    final questionsSnap = results[1] as QuerySnapshot;

    debugPrint('=== TOPIC DOC EXISTS: ${topicSnap.exists}');
    debugPrint('=== QUESTIONS COUNT: ${questionsSnap.docs.length}');

    String description = '';
    List<String> keyPoints = [];
    List<Map<String, dynamic>> examples = [];

    if (topicSnap.exists) {
      final data = topicSnap.data() as Map<String, dynamic>;
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
            return {'name': e.toString().trim(), 'icon': '', 'color': 'blue'};
          })
          .where((e) => (e['name'] as String).isNotEmpty)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      debugPrint('⚠️ Topic document not found!');
    }

    return _TopicData(
      description: description,
      keyPoints: keyPoints,
      examples: examples,
      hasQuiz: questionsSnap.docs.isNotEmpty,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      if (!_hasScrolledToBottom) setState(() => _hasScrolledToBottom = true);
    }
  }

  Future<void> _launchTopicQuiz() async {
    if (_launchingQuiz) return;
    setState(() => _launchingQuiz = true);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicInlineQuizPage(
          grade: widget.grade,
          topicId: widget.topicId,
          topicName: widget.topicName,
          studentId: widget.studentId,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _launchingQuiz = false);

    if (result == true) {
      Navigator.pop(context, true);
      if (widget.onGoToQuiz != null) {
        await widget.onGoToQuiz!();
      }
    }
  }

  Future<void> _completeAndContinue() async {
    Navigator.pop(context, true);
    if (widget.onGoToQuiz != null) {
      await widget.onGoToQuiz!();
    }
  }

  Color _cardColor(String c) {
    switch (c.toLowerCase()) {
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

  Color _cardTextColor(String c) {
    switch (c.toLowerCase()) {
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

  String _heroEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('molecule')) return '⚗️';
    if (n.contains('state')) return '🌡️';
    if (n.contains('matter')) return '🧪';
    if (n.contains('water') || n.contains('dissolv')) return '💧';
    if (n.contains('heat') || n.contains('temperature')) return '🔥';
    if (n.contains('impurity')) return '🔬';
    if (n.contains('property') || n.contains('properties')) return '📊';
    return '🧪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: FutureBuilder<_TopicData>(
        future: _topicDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          final data = snapshot.data ??
              _TopicData(
                  description: '', keyPoints: [], examples: [], hasQuiz: false);

          final hasContent = data.description.isNotEmpty ||
              data.keyPoints.isNotEmpty ||
              data.examples.isNotEmpty;

          final buttonActive = !hasContent || _hasScrolledToBottom;

          return Stack(children: [
            SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 0, 0, data.hasQuiz ? 20 : 110),
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
                              child: Text(_heroEmoji(widget.topicName),
                                  style: const TextStyle(fontSize: 56))),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (data.description.isNotEmpty ||
                          data.keyPoints.isNotEmpty)
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
                                  if (data.description.isNotEmpty) ...[
                                    Row(children: [
                                      const Text('📖',
                                          style: TextStyle(fontSize: 22)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(data.description,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF555555),
                                                  height: 1.6))),
                                    ]),
                                  ],
                                  if (data.keyPoints.isNotEmpty) ...[
                                    if (data.description.isNotEmpty)
                                      const SizedBox(height: 14),
                                    ...data.keyPoints.map((kp) => Padding(
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
                      if (data.examples.isNotEmpty) ...[
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
                                    itemCount: data.examples.length,
                                    itemBuilder: (_, i) {
                                      final ex = data.examples[i];
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
                      if (!hasContent)
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
                      if (hasContent && !_hasScrolledToBottom) ...[
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
                      if (data.hasQuiz) ...[
                        const SizedBox(height: 24),
                        _FadeIn(
                          visible: _visible,
                          delay: 240,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: AnimatedOpacity(
                              opacity: buttonActive ? 1.0 : 0.45,
                              duration: const Duration(milliseconds: 500),
                              child: GestureDetector(
                                onTap: buttonActive && !_launchingQuiz
                                    ? _launchTopicQuiz
                                    : null,
                                child: Container(
                                  height: 58,
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF9C27B0),
                                        Color(0xFFE91E63)
                                      ]),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: buttonActive
                                          ? [
                                              BoxShadow(
                                                  color: const Color(0xFF9C27B0)
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
                                                  color: Colors.white,
                                                  strokeWidth: 2.5)))
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                              Text('🎯',
                                                  style:
                                                      TextStyle(fontSize: 22)),
                                              SizedBox(width: 10),
                                              Text('Start Quiz!',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ]),
              ),
            ),
            if (!data.hasQuiz)
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
                                  : [
                                      Colors.grey.shade400,
                                      Colors.grey.shade500
                                    ]),
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
                      child: Row(
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
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10)),
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

class _TopicData {
  final String description;
  final List<String> keyPoints;
  final List<Map<String, dynamic>> examples;
  final bool hasQuiz;

  const _TopicData({
    required this.description,
    required this.keyPoints,
    required this.examples,
    required this.hasQuiz,
  });
}

// ═══════════════════════════════════════════════════════════════
//  TOPIC INLINE QUIZ PAGE
//  Reads questions from: grades/{grade}/topics/{topicId}/questions
// ═══════════════════════════════════════════════════════════════
const List<List<Color>> _optionGradients = [
  [Color(0xFF7C4DFF), Color(0xFFB388FF)],
  [Color(0xFF1E88E5), Color(0xFF64B5F6)],
  [Color(0xFFE91E63), Color(0xFFFF80AB)],
  [Color(0xFFF9A825), Color(0xFFFFD54F)],
];
const List<String> _optionEmojis = ['🎯', '💡', '⭐', '🌙'];

class TopicInlineQuizPage extends StatefulWidget {
  final String grade;
  final String topicId;
  final String topicName;
  final String studentId;

  const TopicInlineQuizPage({
    Key? key,
    required this.grade,
    required this.topicId,
    required this.topicName,
    required this.studentId,
  }) : super(key: key);

  @override
  State<TopicInlineQuizPage> createState() => _TopicInlineQuizPageState();
}

class _TopicInlineQuizPageState extends State<TopicInlineQuizPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  String _errorMessage = '';

  int _current = 0;
  int? _selected;
  bool _showFeedback = false;
  int _score = 0;
  final List<bool> _results = [];
  List<bool> _optionsVisible = [false, false, false, false];

  late AnimationController _confettiCtrl;
  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackAnim;
  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _confettiCtrl =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _feedbackCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _feedbackAnim =
        CurvedAnimation(parent: _feedbackCtrl, curve: Curves.elasticOut);
    _cardCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _cardSlide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _scoreCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.elasticOut);
    _shakeCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnim = Tween<double>(begin: 0, end: 10)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this)
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fetchQuestions();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _feedbackCtrl.dispose();
    _cardCtrl.dispose();
    _scoreCtrl.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    final db = FirebaseFirestore.instance;

    final pathsToTry = [
      db
          .collection('grades')
          .doc(widget.grade)
          .collection('topics')
          .doc(widget.topicId)
          .collection('questions'),
      db
          .collection('grades')
          .doc(widget.grade)
          .collection('topics')
          .doc(widget.topicId)
          .collection('Questions'),
      db
          .collection('grades')
          .doc(widget.grade)
          .collection('quizzes')
          .doc(widget.topicId)
          .collection('questions'),
      db.collection('quizzes').doc(widget.topicId).collection('questions'),
    ];

    List<QueryDocumentSnapshot> foundDocs = [];
    String foundPath = '';

    for (final col in pathsToTry) {
      try {
        final snap = await col.get();
        debugPrint('🔍 Path: ${col.path} → ${snap.docs.length} docs');

        if (snap.docs.isNotEmpty) {
          foundDocs = snap.docs;
          foundPath = col.path;
          debugPrint('✅ Found questions at: $foundPath');
          break;
        }
      } catch (e) {
        debugPrint('⚠️ Path error [${col.path}]: $e');
        setState(() => _errorMessage = e.toString());
      }
    }

    if (foundDocs.isEmpty) {
      debugPrint('❌ No questions found for topicId: ${widget.topicId}');
      setState(() => _loading = false);
      return;
    }

    try {
      final fetched = foundDocs.map((doc) {
        final q = doc.data() as Map<String, dynamic>;

        final rawOptions = q['options'] as List<dynamic>? ?? [];
        List<String> optionTexts;

        if (rawOptions.isNotEmpty && rawOptions.first is Map) {
          optionTexts = rawOptions
              .map((o) =>
                  (o as Map)['text']?.toString() ??
                  o['label']?.toString() ??
                  o.toString())
              .toList();
        } else {
          optionTexts = rawOptions.map((o) => o.toString()).toList();
        }

        dynamic correctRaw = q['correctAnswerIndex'] ??
            q['correctAnswer'] ??
            q['correct_answer'] ??
            q['correctIndex'] ??
            q['answer'] ??
            0;

        int correctIdx;
        if (correctRaw is int) {
          correctIdx = correctRaw;
        } else if (correctRaw is String) {
          final matchIdx =
              optionTexts.indexWhere((t) => t.trim() == correctRaw.trim());
          correctIdx = matchIdx >= 0 ? matchIdx : int.tryParse(correctRaw) ?? 0;
        } else {
          correctIdx = 0;
        }

        if (rawOptions.isNotEmpty && rawOptions.first is Map) {
          for (int i = 0; i < rawOptions.length; i++) {
            final opt = rawOptions[i] as Map;
            if (opt['isCorrect'] == true || opt['correct'] == true) {
              correctIdx = i;
              break;
            }
          }
        }

        final options = optionTexts
            .asMap()
            .entries
            .map((e) => {
                  'text': e.value,
                  'correct': e.key == correctIdx,
                  'emoji':
                      e.key < _optionEmojis.length ? _optionEmojis[e.key] : '⭐',
                })
            .toList();

        final orderRaw =
            q['questionNumber'] ?? q['order'] ?? q['index'] ?? q['num'] ?? 0;
        final order =
            orderRaw is int ? orderRaw : int.tryParse(orderRaw.toString()) ?? 0;

        return {
          'id': doc.id,
          'question': q['question'] ??
              q['text'] ??
              q['questionText'] ??
              q['title'] ??
              '',
          'options': options,
          'explanation':
              q['answerExplanation'] ?? q['explanation'] ?? q['hint'] ?? '',
          'order': order,
        };
      }).toList();

      fetched.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      debugPrint('✅ Parsed ${fetched.length} questions successfully');

      setState(() {
        _questions = fetched;
        _loading = false;
      });

      if (fetched.isNotEmpty) {
        _cardCtrl.forward();
        _revealOptions();
      }
    } catch (e) {
      debugPrint('❌ Question parse error: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Parse error: $e';
      });
    }
  }

  void _revealOptions() {
    setState(() => _optionsVisible = [false, false, false, false]);
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 180 * (i + 1)), () {
        if (mounted) setState(() => _optionsVisible[i] = true);
      });
    }
  }

  void _select(int index) {
    if (_showFeedback) return;
    final isCorrect =
        (_questions[_current]['options'] as List)[index]['correct'] ?? false;
    setState(() {
      _selected = index;
      _showFeedback = true;
    });
    _feedbackCtrl.forward(from: 0);
    if (isCorrect) {
      setState(() => _score += 10);
      _confettiCtrl.forward(from: 0);
      _scoreCtrl.forward(from: 0);
    } else {
      _shakeCtrl.forward(from: 0);
    }
    _results.add(isCorrect);
    _saveAnswer(index, isCorrect);
  }

  Future<void> _saveAnswer(int answerIndex, bool isCorrect) async {
    try {
      await FirebaseFirestore.instance
          .collection('submissions')
          .doc('${widget.studentId}_${widget.grade}_${widget.topicId}')
          .set({
        'studentId': widget.studentId,
        'grade': widget.grade,
        'topicId': widget.topicId,
        'answers': {
          'q$_current': {
            'selectedAnswer': answerIndex,
            'correct': isCorrect,
            'timestamp': FieldValue.serverTimestamp(),
          }
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveAnswer error: $e');
    }
  }

  void _next() {
    if (_current < _questions.length - 1) {
      _cardCtrl.reset();
      setState(() {
        _current++;
        _selected = null;
        _showFeedback = false;
      });
      _cardCtrl.forward();
      _revealOptions();
    }
  }

  Future<void> _finish() async {
    final correct = _results.where((r) => r).length;
    final pct =
        _questions.isNotEmpty ? (correct / _questions.length * 100).round() : 0;
    final coins = correct * 10;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('quiz_stats')
            .doc('stats');
        final doc = await ref.get();
        if (doc.exists) {
          final d = doc.data()!;
          final topics = List<String>.from(d['completed_topics'] ?? []);
          if (!topics.contains(widget.topicId)) topics.add(widget.topicId);
          await ref.update({
            'total_quizzes': (d['total_quizzes'] ?? 0) + 1,
            'total_coins': (d['total_coins'] ?? 0) + coins,
            'total_questions': (d['total_questions'] ?? 0) + _questions.length,
            'completed_topics': topics,
            'last_updated': FieldValue.serverTimestamp(),
          });
        } else {
          await ref.set({
            'total_quizzes': 1,
            'total_coins': coins,
            'total_questions': _questions.length,
            'completed_topics': [widget.topicId],
            'created_at': FieldValue.serverTimestamp(),
            'last_updated': FieldValue.serverTimestamp(),
          });
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('total_coins_${user.uid}',
            (prefs.getInt('total_coins_${user.uid}') ?? 0) + coins);
      }
    } catch (e) {
      debugPrint('finish stats error: $e');
    }

    if (!mounted) return;
    _showResults(correct, pct, coins);
  }

  void _showResults(int correct, int pct, int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            const Text('Quiz Complete!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text(
              pct >= 80
                  ? '🎉 Amazing!'
                  : pct >= 60
                      ? '👍 Good job!'
                      : '💪 Keep going!',
              style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9C27B0),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _chip('🪙', '$coins', 'coins'),
                    Container(
                        width: 1, height: 32, color: const Color(0xFFE0D4F0)),
                    _chip('✅', '$correct/${_questions.length}', 'correct'),
                    Container(
                        width: 1, height: 32, color: const Color(0xFFE0D4F0)),
                    _chip('📊', '$pct%', 'score'),
                  ]),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFFD500F9)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFF7C4DFF).withValues(alpha: 0.38),
                          blurRadius: 12,
                          offset: const Offset(0, 5))
                    ]),
                child: const Center(
                    child: Text('Continue 🚀',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String emoji, String val, String label) => Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 3),
        Text(val,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9EC8))),
      ]);

  List<Color> _colors(int idx) {
    if (!_showFeedback) return _optionGradients[idx % _optionGradients.length];
    final opts =
        List<Map<String, dynamic>>.from(_questions[_current]['options']);
    if (opts[idx]['correct'] ?? false)
      return [const Color(0xFF00897B), const Color(0xFF26C6DA)];
    if (_selected == idx)
      return [const Color(0xFFE53935), const Color(0xFFFF5252)];
    return [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_questions.isEmpty) return _buildEmpty();

    final q = _questions[_current];
    final opts = List<Map<String, dynamic>>.from(q['options']);

    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB2EBF2), Color(0xFFE8EAF6)])),
        ),
        if (_confettiCtrl.isAnimating)
          Align(
              alignment: Alignment.topCenter,
              child: _ConfettiWidget(controller: _confettiCtrl)),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFB2DFDB))),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Color(0xFF006064), size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFFD500F9)]),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF7C4DFF)
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4))
                        ]),
                    child: Text(
                      '🎯  ${widget.topicName} Quiz',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ScaleTransition(
                  scale: _scoreAnim,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.45),
                              blurRadius: 12)
                        ]),
                    child: Row(children: [
                      const Text('🪙', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text('$_score',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(children: [
                      Container(
                          height: 10,
                          color: Colors.white.withValues(alpha: 0.6)),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        height: 10,
                        width: (MediaQuery.of(context).size.width - 32) *
                            ((_current + 1) / _questions.length),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFFD500F9)]),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF7C4DFF)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6)
                            ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Text('📝 ${_current + 1}/${_questions.length}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5C6BC0))),
              ]),
              const SizedBox(height: 16),
              SlideTransition(
                position: _cardSlide,
                child: Column(
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
                                  offset: const Offset(0, 6))
                            ]),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF9C27B0),
                                      Color(0xFFE91E63)
                                    ]),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Text('Question ${_current + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('❓',
                                        style: TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(
                                      q['question'] as String? ?? '',
                                      style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1A2E),
                                          height: 1.4),
                                    )),
                                  ]),
                            ]),
                      ),
                      const SizedBox(height: 12),
                      if (!_showFeedback)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE8EAF6), width: 1.5)),
                          child: const Row(children: [
                            Text('✨', style: TextStyle(fontSize: 17)),
                            SizedBox(width: 8),
                            Text('Tap the correct answer!',
                                style: TextStyle(
                                    color: Color(0xFF7986CB),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ]),
                        ),
                      const SizedBox(height: 12),
                      ...List.generate(opts.length, (i) {
                        final vis =
                            i < _optionsVisible.length && _optionsVisible[i];
                        final colors = _colors(i);
                        final isCorrect = opts[i]['correct'] ?? false;
                        final isSelected = _selected == i;
                        final emoji = opts[i]['emoji'] as String? ??
                            (i < _optionEmojis.length ? _optionEmojis[i] : '⭐');
                        return AnimatedOpacity(
                          opacity: vis ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedSlide(
                            offset: vis ? Offset.zero : const Offset(0.12, 0),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  bottom: i < opts.length - 1 ? 12 : 0),
                              child: AnimatedBuilder(
                                animation: _shakeAnim,
                                builder: (_, child) {
                                  final off =
                                      isSelected && !isCorrect && _showFeedback
                                          ? Offset(
                                              _shakeAnim.value *
                                                  (i % 2 == 0 ? 1 : -1),
                                              0)
                                          : Offset.zero;
                                  return Transform.translate(
                                      offset: off, child: child);
                                },
                                child: GestureDetector(
                                  onTap:
                                      _showFeedback ? null : () => _select(i),
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
                                              color: colors[0].withValues(
                                                  alpha: _showFeedback
                                                      ? 0.18
                                                      : 0.38),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6))
                                        ],
                                        border: isSelected && _showFeedback
                                            ? Border.all(
                                                color: Colors.white, width: 2.5)
                                            : null),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      child: Row(children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.22),
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                          child: Center(
                                              child: Text(emoji,
                                                  style: const TextStyle(
                                                      fontSize: 22))),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                            child: Text(
                                          opts[i]['text'] as String? ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              height: 1.35),
                                        )),
                                        if (_showFeedback && isCorrect)
                                          Container(
                                              width: 28,
                                              height: 28,
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white),
                                              child: const Icon(Icons.check,
                                                  color: Color(0xFF00897B),
                                                  size: 16)),
                                        if (_showFeedback &&
                                            isSelected &&
                                            !isCorrect)
                                          Container(
                                              width: 28,
                                              height: 28,
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white),
                                              child: const Icon(Icons.close,
                                                  color: Color(0xFFE53935),
                                                  size: 16)),
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_showFeedback) ...[
                        const SizedBox(height: 14),
                        ScaleTransition(
                            scale: _feedbackAnim,
                            child: _buildFeedback(opts, q)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _current == _questions.length - 1
                              ? _finish
                              : _next,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: _current == _questions.length - 1
                                      ? [
                                          const Color(0xFF00897B),
                                          const Color(0xFF26C6DA)
                                        ]
                                      : [
                                          const Color(0xFF7C4DFF),
                                          const Color(0xFFD500F9)
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: (_current == _questions.length - 1
                                              ? const Color(0xFF00897B)
                                              : const Color(0xFF7C4DFF))
                                          .withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6))
                                ]),
                            child: Center(
                                child: Text(
                              _current == _questions.length - 1
                                  ? '🏆  Finish Quiz'
                                  : '➡️  Next Question',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                            )),
                          ),
                        ),
                      ],
                    ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildFeedback(
      List<Map<String, dynamic>> opts, Map<String, dynamic> q) {
    final isCorrect = opts[_selected!]['correct'] ?? false;
    final explanation = (q['explanation'] as String? ?? '').trim();
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
                offset: const Offset(0, 4))
          ]),
      child: Row(children: [
        Text(isCorrect ? '🎉' : '💪', style: const TextStyle(fontSize: 30)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            Text(explanation,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
          ],
        ])),
      ]),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(
            scale: _pulseAnim,
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
          const SizedBox(height: 24),
          const Text('Loading Quiz...',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0))),
          const SizedBox(height: 24),
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
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB2DFDB))),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Color(0xFF006064), size: 18),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('📚', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 18),
                  const Text('No questions yet!',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0))),
                  const SizedBox(height: 10),
                  Text('Your teacher is cooking up\nawesome questions! 🍳',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5),
                      textAlign: TextAlign.center),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFB300))),
                      child: Column(children: [
                        const Text('📂 Debug Info',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100))),
                        const SizedBox(height: 4),
                        SelectableText(
                          'Path: grades/${widget.grade}/topics/${widget.topicId}/questions\n\nError: $_errorMessage',
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFF795548)),
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _fetchQuestions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Text('🔄 Try Again',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────
class _ConfettiWidget extends StatelessWidget {
  final AnimationController controller;
  const _ConfettiWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Stack(
        children: List.generate(30, (i) {
          final rng = Random(i);
          return Positioned(
            left: rng.nextDouble() * MediaQuery.of(context).size.width,
            top: -10 +
                controller.value * MediaQuery.of(context).size.height * 0.7,
            child: Transform.rotate(
              angle: controller.value * 2 * pi * (rng.nextDouble() * 4),
              child: Text(['🎉', '⭐', '✨', '🌟', '💫', '🎊', '🎈'][i % 7],
                  style: const TextStyle(fontSize: 20)),
            ),
          );
        }),
      ),
    );
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
