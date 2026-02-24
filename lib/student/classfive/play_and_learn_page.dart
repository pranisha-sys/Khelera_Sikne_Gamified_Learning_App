import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mission_one_page.dart';
import 'student_question_view.dart'; // your quiz page

class PlayAndLearnPage extends StatefulWidget {
  /// Pass the Firestore grade ID, e.g. "Grade 5"
  final String grade;

  const PlayAndLearnPage({super.key, this.grade = 'Grade 5'});

  @override
  State<PlayAndLearnPage> createState() => _PlayAndLearnPageState();
}

class _PlayAndLearnPageState extends State<PlayAndLearnPage>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Stats ──
  int totalCoins = 0;
  int completedTopicsCount = 0;

  // ── Dynamic topics from Firestore ──
  List<Map<String, dynamic>> _firestoreTopics = []; // teacher-uploaded
  Set<String> _completedTopicIds = {}; // IDs student finished
  bool _loadingTopics = true;

  // ── Fixed first topic (always "What is Matter?" → MissionOnePage) ──
  static const String _firstTopicId = 'what_is_matter';
  static const String _firstTopicName = 'What is Matter?';

  // ── FAB animation ──
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
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  Load everything
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadQuizStats(),
      _loadFirestoreTopics(),
    ]);
  }

  /// Load student quiz stats + completed topic IDs from Firestore
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
        final completedList = List<String>.from(data['completed_topics'] ?? []);
        setState(() {
          totalCoins = data['total_coins'] ?? 0;
          completedTopicsCount = completedList.length;
          _completedTopicIds = completedList.toSet();
        });
      }
    } catch (e) {
      debugPrint('❌ Stats error: $e');
    }
  }

  /// Load teacher-uploaded topics from grades/{grade}/topics
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
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? doc.id,
          'description': data['description'] ?? '',
        };
      }).toList();

      // Remove 'what_is_matter' if teacher accidentally added it — it's hardcoded first
      topics.removeWhere((t) => t['id'] == _firstTopicId);

      setState(() {
        _firestoreTopics = topics;
        _loadingTopics = false;
      });
    } catch (e) {
      debugPrint('❌ Topics error: $e');
      setState(() => _loadingTopics = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Build the ORDERED lesson list:
  //  [0] What is Matter? (hardcoded)
  //  [1..N] Teacher topics (from Firestore, ordered by createdAt)
  //  [N+1] Quiz (always last)
  // ─────────────────────────────────────────────────────────────
  List<_LessonItem> get _orderedLessons {
    final List<_LessonItem> items = [];

    // 0 — Fixed first lesson
    items.add(_LessonItem(
      id: _firstTopicId,
      title: _firstTopicName,
      icon: Icons.science_outlined,
      isFixedLesson: true,
      isQuiz: false,
    ));

    // 1..N — Teacher-uploaded topics
    for (final t in _firestoreTopics) {
      items.add(_LessonItem(
        id: t['id'] as String,
        title: t['name'] as String,
        icon: _iconForTopic(t['name'] as String),
        isFixedLesson: false,
        isQuiz: false,
      ));
    }

    // Last — Quiz (always)
    items.add(_LessonItem(
      id: 'quiz',
      title: 'Quiz',
      icon: Icons.quiz_outlined,
      isFixedLesson: false,
      isQuiz: true,
    ));

    return items;
  }

  /// A topic is unlocked if ALL topics before it are completed
  bool _isUnlocked(int index) {
    if (index == 0) return true; // first is always unlocked
    final lessons = _orderedLessons;
    // All previous non-quiz items must be completed
    for (int i = 0; i < index; i++) {
      if (!_completedTopicIds.contains(lessons[i].id)) return false;
    }
    return true;
  }

  bool get _allTopicsCompleted {
    final lessons = _orderedLessons;
    // All except the quiz must be completed
    for (int i = 0; i < lessons.length - 1; i++) {
      if (!_completedTopicIds.contains(lessons[i].id)) return false;
    }
    return lessons.length > 1; // need at least one topic
  }

  int get _completedLessonsCount =>
      _orderedLessons.where((l) => _completedTopicIds.contains(l.id)).length;

  int get _totalLessons => _orderedLessons.length - 1; // exclude quiz

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

  // ─────────────────────────────────────────────────────────────
  //  Navigation
  // ─────────────────────────────────────────────────────────────
  Future<void> _navigateToLesson(_LessonItem lesson) async {
    if (lesson.isQuiz) {
      // Navigate to quiz
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentQuestionView(
            grade: widget.grade,
            topicId: 'quiz',
            studentId: user?.uid ?? '',
          ),
        ),
      );
      if (!mounted) return;
      if (result == true) {
        await _markTopicComplete('quiz');
        _loadAllData();
      }
      return;
    }

    if (lesson.isFixedLesson) {
      // MissionOnePage for "What is Matter?"
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MissionOnePage()),
      );
      if (!mounted) return;
      if (result == true) {
        await _markTopicComplete(_firstTopicId);
        _loadAllData();
      }
      return;
    }

    // Teacher-uploaded topic — content viewer with sequential auto-advance
    final lessons = _orderedLessons;
    final currentIndex = lessons.indexWhere((l) => l.id == lesson.id);
    final nextIndex = currentIndex + 1;
    final nextLesson = nextIndex < lessons.length ? lessons[nextIndex] : null;
    final nextLabel = nextLesson == null
        ? 'Finish'
        : nextLesson.isQuiz
            ? 'Go to Quiz 🏆'
            : 'Next: ${nextLesson.title}';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TopicContentPage(
          grade: widget.grade,
          topicId: lesson.id,
          topicName: lesson.title,
          studentId: user?.uid ?? '',
          nextLabel: nextLabel,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _markTopicComplete(lesson.id);
      _loadAllData();
    }
  }

  /// Mark a topic as completed in Firestore + SharedPreferences
  Future<void> _markTopicComplete(String topicId) async {
    if (user == null) return;
    try {
      final uid = user!.uid;
      final statsRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('quiz_stats')
          .doc('stats');

      final doc = await statsRef.get();
      final List<String> completed = doc.exists
          ? List<String>.from(doc.data()?['completed_topics'] ?? [])
          : [];

      if (!completed.contains(topicId)) {
        completed.add(topicId);
        if (doc.exists) {
          await statsRef.update({
            'completed_topics': completed,
            'last_updated': FieldValue.serverTimestamp(),
          });
        } else {
          await statsRef.set({
            'completed_topics': completed,
            'total_quizzes': 0,
            'total_coins': 0,
            'total_questions': 0,
            'created_at': FieldValue.serverTimestamp(),
            'last_updated': FieldValue.serverTimestamp(),
          });
        }

        // Sync to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('completed_topics_$uid', completed);

        setState(() => _completedTopicIds = completed.toSet());
      }
    } catch (e) {
      debugPrint('❌ markTopicComplete error: $e');
    }
  }

  void _showProgressSnackbar() {
    final pct = _totalLessons > 0
        ? (_completedLessonsCount / _totalLessons * 100).round()
        : 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Great progress! $_completedLessonsCount/$_totalLessons lessons ($pct%) 🎉',
        ),
        backgroundColor: const Color(0xFF9C27B0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Color(0xFF006064), size: 20),
            ),
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
                  colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 28)),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
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
                        // ── Stats card ──
                        _buildStatsCard(progressPct),

                        const SizedBox(height: 28),

                        // ── Section title ──
                        const Text(
                          "What You'll Learn",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Lesson list ──
                        ...List.generate(lessons.length, (i) {
                          final lesson = lessons[i];
                          final unlocked = _isUnlocked(i);
                          final completed =
                              _completedTopicIds.contains(lesson.id);
                          return _buildLessonItem(
                            lesson: lesson,
                            index: i,
                            isUnlocked: unlocked,
                            isCompleted: completed,
                          );
                        }),
                      ],
                    ),
                  ),
          ),

          // ── Fixed bottom Start Learning button ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildStartLearningButton(lessons),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Stats Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatsCard(double progressPct) {
    final achievementPct = _totalLessons > 0
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
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
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
          const Positioned(
              top: 36,
              left: 16,
              child: Opacity(
                  opacity: 0.3,
                  child: Text('🌟', style: TextStyle(fontSize: 12)))),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(Icons.quiz_rounded,
                          '$completedTopicsCount', 'Topic master')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildStatCard(Icons.monetization_on_rounded,
                          '$totalCoins', 'Total Coin')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildStatCard(Icons.emoji_events_rounded,
                          '$achievementPct%', 'Achievements')),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Row(children: [
                    const Text('✨', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '$_completedLessonsCount/$_totalLessons',
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPct,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
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
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF9C27B0), size: 26),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 26,
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Lesson Item
  // ─────────────────────────────────────────────────────────────
  Widget _buildLessonItem({
    required _LessonItem lesson,
    required int index,
    required bool isUnlocked,
    required bool isCompleted,
  }) {
    // Quiz special styling
    final isQuiz = lesson.isQuiz;
    final accentColor =
        isQuiz ? const Color(0xFF00897B) : const Color(0xFF9C27B0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? accentColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isUnlocked ? () => _navigateToLesson(lesson) : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: accentColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : isUnlocked
                            ? lesson.icon
                            : Icons.lock_outline_rounded,
                    color: isCompleted
                        ? const Color(0xFF00C853)
                        : isUnlocked
                            ? accentColor
                            : Colors.grey.shade400,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey.shade400,
                        ),
                      ),
                      if (isQuiz) ...[
                        const SizedBox(height: 3),
                        Text(
                          isUnlocked
                              ? 'Complete all lessons to unlock'
                              : 'Unlocked! Time to test yourself 🎯',
                          style: TextStyle(
                              fontSize: 11,
                              color: isUnlocked
                                  ? Colors.grey.shade500
                                  : const Color(0xFF00897B)),
                        ),
                      ],
                    ],
                  ),
                ),

                // Status badge
                _buildStatusBadge(
                    isUnlocked: isUnlocked,
                    isCompleted: isCompleted,
                    isQuiz: isQuiz,
                    accentColor: accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isUnlocked,
    required bool isCompleted,
    required bool isQuiz,
    required Color accentColor,
  }) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00C853), size: 13),
            SizedBox(width: 4),
            Text('Done',
                style: TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    if (!isUnlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 13),
            const SizedBox(width: 4),
            Text('Locked',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isQuiz ? 'Take Quiz' : 'Start',
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Start Learning Button
  // ─────────────────────────────────────────────────────────────
  Widget _buildStartLearningButton(List<_LessonItem> lessons) {
    // Find the first unlocked + incomplete lesson
    _LessonItem? nextLesson;
    for (int i = 0; i < lessons.length; i++) {
      if (_isUnlocked(i) && !_completedTopicIds.contains(lessons[i].id)) {
        nextLesson = lessons[i];
        break;
      }
    }

    final bool allDone = nextLesson == null;

    return GestureDetector(
      onTap: nextLesson != null ? () => _navigateToLesson(nextLesson!) : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: allDone
                ? [const Color(0xFF00C853), const Color(0xFF009624)]
                : [const Color(0xFF7C4DFF), const Color(0xFFD500F9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  (allDone ? const Color(0xFF00C853) : const Color(0xFF7C4DFF))
                      .withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allDone ? Icons.emoji_events_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              allDone
                  ? 'All Done! 🎉'
                  : nextLesson!.isQuiz
                      ? 'Take Quiz 🏆'
                      : 'Continue Learning',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Data model for a lesson item
// ─────────────────────────────────────────────────────────────
class _LessonItem {
  final String id;
  final String title;
  final IconData icon;
  final bool isFixedLesson;
  final bool isQuiz;

  const _LessonItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.isFixedLesson,
    required this.isQuiz,
  });
}

// ─────────────────────────────────────────────────────────────
//  Topic Content Page
//  • Reads content from Firestore (description, keyPoints, examples)
//  • NO "Mark as Complete" button
//  • "Next Lesson →" button completes topic and pops with true
//  • Scroll-to-unlock when content exists; always-active when empty
// ─────────────────────────────────────────────────────────────
class _TopicContentPage extends StatefulWidget {
  final String grade;
  final String topicId;
  final String topicName;
  final String studentId;
  final String nextLabel;

  const _TopicContentPage({
    required this.grade,
    required this.topicId,
    required this.topicName,
    required this.studentId,
    this.nextLabel = 'Next Lesson',
  });

  @override
  State<_TopicContentPage> createState() => _TopicContentPageState();
}

class _TopicContentPageState extends State<_TopicContentPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 60) {
      if (!_hasScrolledToBottom) setState(() => _hasScrolledToBottom = true);
    }
  }

  void _completeAndContinue() => Navigator.pop(context, true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C4DFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          widget.topicName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('grades')
            .doc(widget.grade)
            .collection('topics')
            .doc(widget.topicId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
          }

          String description = '';
          List<String> keyPoints = [];
          List<String> examples = [];

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            description = data['description'] ?? '';
            keyPoints = List<String>.from(data['keyPoints'] ?? []);
            examples = List<String>.from(data['examples'] ?? []);
          }

          _hasContent = description.isNotEmpty ||
              keyPoints.isNotEmpty ||
              examples.isNotEmpty;

          // No content → button always active; has content → unlock after scroll
          final bool buttonActive = !_hasContent || _hasScrolledToBottom;

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Topic header card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF7C4DFF),
                                Color(0xFFD500F9)
                              ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(widget.grade,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          Text(widget.topicName,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A2E))),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(description,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade700,
                                    height: 1.6)),
                          ],
                        ],
                      ),
                    ),

                    // ── Key Points ──
                    if (keyPoints.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Row(children: const [
                        Text('💡', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text('Key Points',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0))),
                      ]),
                      const SizedBox(height: 12),
                      ...keyPoints.asMap().entries.map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF7C4DFF)
                                      .withValues(alpha: 0.2)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C4DFF)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('${e.key + 1}',
                                          style: const TextStyle(
                                              color: Color(0xFF7C4DFF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(e.value,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF1A1A2E),
                                              height: 1.5))),
                                ]),
                          )),
                    ],

                    // ── Examples ──
                    if (examples.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Row(children: const [
                        Text('🔬', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text('Examples',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0))),
                      ]),
                      const SizedBox(height: 12),
                      ...examples.map((ex) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF9C27B0)
                                      .withValues(alpha: 0.15)),
                            ),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('▶',
                                      style: TextStyle(
                                          color: Color(0xFF9C27B0),
                                          fontSize: 12)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(ex,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF1A1A2E),
                                              height: 1.5))),
                                ]),
                          )),
                    ],

                    // ── No content state ──
                    if (!_hasContent)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.07),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6))
                                ],
                              ),
                              child: const Center(
                                child:
                                    Text('📖', style: TextStyle(fontSize: 44)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.topicName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1565C0)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your teacher will add content\nfor this topic soon!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You can continue to the next lesson 👇',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic),
                            ),
                          ]),
                        ),
                      ),

                    // ── Scroll hint ──
                    if (_hasContent && !_hasScrolledToBottom)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xFF9C27B0), size: 18),
                                Text(' Scroll down to continue',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500)),
                              ]),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Next Lesson button (NO "Mark as Complete") ──
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: AnimatedOpacity(
                  opacity: buttonActive ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 400),
                  child: GestureDetector(
                    onTap: buttonActive ? _completeAndContinue : null,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: buttonActive
                              ? [
                                  const Color(0xFF7C4DFF),
                                  const Color(0xFFD500F9)
                                ]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: buttonActive
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF7C4DFF)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6))
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              widget.nextLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
