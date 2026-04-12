import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ============================================================================
// ANALYTICS PAGE v3
// - Overview: quiz performance pulled from quiz_stats + submissions
// - User activity chart filtered per selected period
// - Online Now modal → lists students, teachers, admins
// - Total Classes → real grades/{grade}/topics count
// - Students tab: enrollment + per-student quiz progress from quiz_stats
// ============================================================================

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late TabController _tabController;

  // ── Firebase ─────────────────────────────────────────────────────────────
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Period selector ───────────────────────────────────────────────────────
  String _selectedPeriod = 'Daily';

  // ── Streams ───────────────────────────────────────────────────────────────
  Stream<QuerySnapshot>? _studentsStream;
  Stream<QuerySnapshot>? _teachersStream;
  Stream<QuerySnapshot>? _activitiesStream;
  Stream<QuerySnapshot>? _enrollmentsStream;
  Stream<QuerySnapshot>? _onlineUsersStream;

  // ── Computed state ────────────────────────────────────────────────────────
  Map<String, int> _userActivityData = {};
  // topicName → average score (0–100)
  Map<String, double> _topicPerformance = {};
  double _overallQuizPerformance = 0.0;
  double _completionRate = 0.0;
  // grade → topic count
  Map<String, int> _classTopicCounts = {};
  int _totalTopicsAcrossGrades = 0;

  String _enrollmentFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _tabController = TabController(length: 3, vsync: this);
    _initStreams();
    _loadActivityData();
    _loadQuizPerformanceFromStudentPanel();
    _loadRealClasses();
    _calculateCompletionRate();
    _updatePresence();
  }

  // ── Presence ──────────────────────────────────────────────────────────────
  Future<void> _updatePresence() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('online_users').doc(uid).set({
      'uid': uid,
      'lastSeen': FieldValue.serverTimestamp(),
      'online': true,
    }, SetOptions(merge: true));
  }

  // ── Animations ────────────────────────────────────────────────────────────
  void _initAnimations() {
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _scaleController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _fadeController.forward();
    _scaleController.forward();
  }

  // ── Streams ───────────────────────────────────────────────────────────────
  void _initStreams() {
    _studentsStream =
        _db.collection('users').where('role', isEqualTo: 'student').snapshots();
    _teachersStream =
        _db.collection('users').where('role', isEqualTo: 'teacher').snapshots();
    _activitiesStream = _db
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
    _enrollmentsStream = _db.collection('enrollments').snapshots();
    _onlineUsersStream = _db
        .collection('online_users')
        .where('online', isEqualTo: true)
        .snapshots();
  }

  // ── Activity data (respects period) ──────────────────────────────────────
  Future<void> _loadActivityData() async {
    try {
      final now = DateTime.now();
      final Map<String, int> result = {};

      if (_selectedPeriod == 'Daily') {
        // Last 7 days
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayName = days[date.weekday - 1];
          final start = DateTime(date.year, date.month, date.day);
          final end = start.add(const Duration(days: 1));
          final snap = await _db
              .collection('activities')
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .where('timestamp', isLessThan: Timestamp.fromDate(end))
              .get();
          result[dayName] = snap.docs.length;
        }
      } else if (_selectedPeriod == 'Weekly') {
        // Last 4 weeks
        for (int w = 3; w >= 0; w--) {
          final start = now.subtract(Duration(days: (w + 1) * 7));
          final end = now.subtract(Duration(days: w * 7));
          final snap = await _db
              .collection('activities')
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .where('timestamp', isLessThan: Timestamp.fromDate(end))
              .get();
          result['W${4 - w}'] = snap.docs.length;
        }
      } else {
        // Monthly — last 6 months
        for (int m = 5; m >= 0; m--) {
          final month = DateTime(now.year, now.month - m, 1);
          final nextMonth = DateTime(month.year, month.month + 1, 1);
          final snap = await _db
              .collection('activities')
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(month))
              .where('timestamp', isLessThan: Timestamp.fromDate(nextMonth))
              .get();
          final label = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ][month.month - 1];
          result[label] = snap.docs.length;
        }
      }

      if (mounted) setState(() => _userActivityData = result);
    } catch (e) {
      debugPrint('Error loading activity data: $e');
    }
  }

  // ── Quiz performance — pulled from student panel data ────────────────────
  // Reads: users/{uid}/quiz_stats/stats  (completed_topics, total_coins, total_quizzes)
  // Reads: grades/{grade}/topics/{topicId}/questions  — same path as PlayAndLearnPage
  // Reads: submissions/{studentId}_{grade}_{topicId}  — written by TopicInlineQuizPage
  Future<void> _loadQuizPerformanceFromStudentPanel() async {
    try {
      // 1. Collect all students
      final studentsSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // 2. Collect all grades
      final gradesSnap = await _db.collection('grades').get();

      // 3. For each grade, get its topics
      final Map<String, String> topicIdToName = {}; // topicId → topicName
      for (final gradeDoc in gradesSnap.docs) {
        final grade = gradeDoc.id;
        final topicsSnap = await _db
            .collection('grades')
            .doc(grade)
            .collection('topics')
            .get();
        for (final topicDoc in topicsSnap.docs) {
          final name = (topicDoc.data()['name'] as String?) ?? topicDoc.id;
          topicIdToName['${grade}_${topicDoc.id}'] = name;
        }
      }

      // 4. Aggregate scores per topic from submissions
      // submissions doc id format: {studentId}_{grade}_{topicId}
      final Map<String, List<double>> topicScores = {}; // topicName → scores
      int totalQuizzes = 0;
      double totalScore = 0;

      for (final studentDoc in studentsSnap.docs) {
        final uid = studentDoc.id;

        // quiz_stats for completion count
        final statsDoc = await _db
            .collection('users')
            .doc(uid)
            .collection('quiz_stats')
            .doc('stats')
            .get();

        if (statsDoc.exists) {
          final data = statsDoc.data()!;
          totalQuizzes += (data['total_quizzes'] as num?)?.toInt() ?? 0;
        }

        // Submissions for per-topic scores
        for (final gradeDoc in gradesSnap.docs) {
          final grade = gradeDoc.id;
          final topicsSnap = await _db
              .collection('grades')
              .doc(grade)
              .collection('topics')
              .get();

          for (final topicDoc in topicsSnap.docs) {
            final topicKey = '${grade}_${topicDoc.id}';
            final topicName = topicIdToName[topicKey] ?? topicDoc.id;
            final submissionId = '${uid}_${grade}_${topicDoc.id}';

            final submissionDoc =
                await _db.collection('submissions').doc(submissionId).get();
            if (!submissionDoc.exists) continue;

            final submData = submissionDoc.data()!;
            final answers = submData['answers'] as Map<String, dynamic>? ?? {};
            if (answers.isEmpty) continue;

            int correct = 0;
            for (final answer in answers.values) {
              if ((answer as Map<String, dynamic>)['correct'] == true)
                correct++;
            }

            final pct = (correct / answers.length) * 100;
            topicScores.putIfAbsent(topicName, () => []).add(pct);
            totalScore += pct;
          }
        }
      }

      // 5. Average per topic
      final Map<String, double> avgPerTopic = {};
      for (final entry in topicScores.entries) {
        avgPerTopic[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }

      final overall = topicScores.isEmpty
          ? 0.0
          : topicScores.values.expand((l) => l).reduce((a, b) => a + b) /
              topicScores.values.expand((l) => l).length;

      if (mounted) {
        setState(() {
          _topicPerformance = avgPerTopic;
          _overallQuizPerformance = overall;
        });
      }
    } catch (e) {
      debugPrint('Error loading quiz performance: $e');
    }
  }

  // ── Real classes from grades collection ───────────────────────────────────
  Future<void> _loadRealClasses() async {
    try {
      final gradesSnap = await _db.collection('grades').get();
      final Map<String, int> counts = {};
      int total = 0;
      for (final gradeDoc in gradesSnap.docs) {
        final topicsSnap = await _db
            .collection('grades')
            .doc(gradeDoc.id)
            .collection('topics')
            .get();
        counts[gradeDoc.id] = topicsSnap.docs.length;
        total += topicsSnap.docs.length;
      }
      if (mounted) {
        setState(() {
          _classTopicCounts = counts;
          _totalTopicsAcrossGrades = total;
        });
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  // ── Completion rate ───────────────────────────────────────────────────────
  Future<void> _calculateCompletionRate() async {
    try {
      final students = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      if (students.docs.isEmpty) {
        if (mounted) setState(() => _completionRate = 0.0);
        return;
      }
      final completions = await _db.collection('course_completions').get();
      final Set<String> done = {};
      for (final doc in completions.docs) {
        done.add(doc.data()['userId'] as String? ?? '');
      }
      if (mounted) {
        setState(
            () => _completionRate = (done.length / students.docs.length) * 100);
      }
    } catch (e) {
      debugPrint('Error calculating completion rate: $e');
    }
  }

  void _onPeriodSelected(String period) {
    setState(() => _selectedPeriod = period);
    _scaleController.reset();
    _scaleController.forward();
    _loadActivityData();
  }

  void _refreshAll() {
    _loadActivityData();
    _loadQuizPerformanceFromStudentPanel();
    _loadRealClasses();
    _calculateCompletionRate();
    _fadeController.reset();
    _scaleController.reset();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0EA5E9),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF0EA5E9),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Students'),
                  Tab(text: 'Activity'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildStudentTab(),
                  _buildActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF0EA5E9),
      title: const Text('Analytics Dashboard',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: _onlineUsersStream,
          builder: (context, snap) {
            final count = snap.data?.docs.length ?? 0;
            return GestureDetector(
              onTap: () => _showOnlineUsersModal(snap.data?.docs ?? []),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('$count online',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white, size: 14),
                ]),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshAll,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ONLINE USERS MODAL
  // ══════════════════════════════════════════════════════════════════════════
  void _showOnlineUsersModal(List<QueryDocumentSnapshot> onlineDocs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OnlineUsersSheet(onlineDocs: onlineDocs, db: _db),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLASSES MODAL
  // ══════════════════════════════════════════════════════════════════════════
  void _showClassesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ClassesSheet(classTopicCounts: _classTopicCounts, db: _db),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — OVERVIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(),
          const SizedBox(height: 20),
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          ScaleTransition(scale: _scaleAnimation, child: _buildStatCards()),
          const SizedBox(height: 24),
          _buildActivityChart(),
          const SizedBox(height: 24),
          _buildQuizPerformanceChart(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.trending_up, size: 36, color: Colors.white),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Real-time Analytics',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 4),
            Text('Live auth · Enrollment · Quiz performance from student panel',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['Daily', 'Weekly', 'Monthly'].map((p) {
        final sel = _selectedPeriod == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => _onPeriodSelected(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF0EA5E9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFFE5E7EB)),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: const Color(0xFF0EA5E9).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Center(
                child: Text(p,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF6B7280))),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Stat cards ─────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    return Column(children: [
      Row(children: [
        Expanded(
          child: _streamStatCard(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Total Students',
            stream: _studentsStream,
            valueBuilder: (snap) => '${snap.data?.docs.length ?? 0}',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _streamStatCard(
            icon: Icons.school_outlined,
            iconColor: const Color(0xFF10B981),
            label: 'Total Teachers',
            stream: _teachersStream,
            valueBuilder: (snap) => '${snap.data?.docs.length ?? 0}',
          ),
        ),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        // Online Now — tappable → modal
        Expanded(
          child: _streamStatCard(
            icon: Icons.wifi_tethering,
            iconColor: const Color(0xFF8B5CF6),
            label: 'Online Now',
            stream: _onlineUsersStream,
            valueBuilder: (snap) => '${snap.data?.docs.length ?? 0}',
            liveIndicator: true,
            onTap: () {
              // Re-fetch current online docs for modal
              _db
                  .collection('online_users')
                  .where('online', isEqualTo: true)
                  .get()
                  .then((snap) => _showOnlineUsersModal(snap.docs));
            },
          ),
        ),
        const SizedBox(width: 14),
        // Total Classes — tappable → modal showing real grades/topics
        Expanded(
          child: GestureDetector(
            onTap: _showClassesModal,
            child: _staticStatCard(
              icon: Icons.library_books_outlined,
              iconColor: const Color(0xFFF59E0B),
              label: 'Total Classes',
              value: '$_totalTopicsAcrossGrades',
              badge:
                  '${_classTopicCounts.length} grade${_classTopicCounts.length == 1 ? "" : "s"}',
            ),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: _staticStatCard(
            icon: Icons.emoji_events_outlined,
            iconColor: const Color(0xFFEF4444),
            label: 'Avg Quiz Score',
            value: '${_overallQuizPerformance.toStringAsFixed(0)}%',
            badge: '${_topicPerformance.length} topics',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _staticStatCard(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Completion Rate',
            value: '${_completionRate.toStringAsFixed(0)}%',
          ),
        ),
      ]),
    ]);
  }

  Widget _streamStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Stream<QuerySnapshot>? stream,
    required String Function(AsyncSnapshot<QuerySnapshot>) valueBuilder,
    bool liveIndicator = false,
    VoidCallback? onTap,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final value = valueBuilder(snapshot);
        return GestureDetector(
          onTap: onTap,
          child: _cardShell(
            icon: icon,
            iconColor: iconColor,
            label: label,
            value: value,
            liveIndicator: liveIndicator,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            tappable: onTap != null,
          ),
        );
      },
    );
  }

  Widget _staticStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? badge,
  }) {
    return _cardShell(
        icon: icon,
        iconColor: iconColor,
        label: label,
        value: value,
        badge: badge);
  }

  Widget _cardShell({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool liveIndicator = false,
    bool isLoading = false,
    bool tappable = false,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            tappable ? Border.all(color: iconColor.withOpacity(0.25)) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          if (liveIndicator) ...[
            const Spacer(),
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80), shape: BoxShape.circle)),
          ],
          if (tappable) ...[
            const Spacer(),
            Icon(Icons.chevron_right,
                color: iconColor.withOpacity(0.6), size: 18),
          ],
        ]),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, v, child) => Opacity(opacity: v, child: child),
          child: Text(value,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500)),
        if (badge != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20)),
            child: Text(badge,
                style: TextStyle(
                    fontSize: 11,
                    color: iconColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
              ),
            ),
          ),
      ]),
    );
  }

  // ── Activity line chart (period-aware) ────────────────────────────────────
  Widget _buildActivityChart() {
    final labels = _userActivityData.keys.toList();
    final maxY = _userActivityData.values.isEmpty
        ? 20.0
        : (_userActivityData.values.reduce((a, b) => a > b ? a : b) + 5)
            .toDouble();

    return _chartBox(
      title: 'User Activity (${_selectedPeriod})',
      child: SizedBox(
        height: 200,
        child: labels.isEmpty
            ? const Center(
                child: Text('No data yet',
                    style: TextStyle(color: Color(0xFF9CA3AF))))
            : LineChart(LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4).ceilToDouble(),
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length)
                          return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[idx],
                              style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY / 4).ceilToDouble(),
                      reservedSize: 36,
                      getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (labels.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                        labels.length,
                        (i) => FlSpot(i.toDouble(),
                            (_userActivityData[labels[i]] ?? 0).toDouble())),
                    isCurved: true,
                    color: const Color(0xFF0EA5E9),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF0EA5E9),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0EA5E9).withOpacity(0.08)),
                  ),
                ],
              )),
      ),
    );
  }

  // ── Quiz performance bar chart — from student panel data ──────────────────
  Widget _buildQuizPerformanceChart() {
    final topicNames = _topicPerformance.keys.take(6).toList();

    if (topicNames.isEmpty) {
      return _chartBox(
        title: 'Quiz Performance by Topic',
        child: Container(
          height: 100,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined,
                  color: Color(0xFF9CA3AF), size: 36),
              const SizedBox(height: 8),
              Text(
                'No quiz submissions yet.\nStudents need to complete topics in Play & Learn.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return _chartBox(
      title: 'Quiz Performance by Topic (from Student Panel)',
      subtitle: 'Avg score across all students per topic',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1F2937),
                  getTooltipItem: (group, groupIndex, rod, _) => BarTooltipItem(
                    '${topicNames[groupIndex]}\n${rod.toY.toStringAsFixed(1)}%',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= topicNames.length)
                        return const Text('');
                      final name = topicNames[idx];
                      final display =
                          name.length > 10 ? '${name.substring(0, 10)}…' : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(display,
                            style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 9,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 25,
                    getTitlesWidget: (value, _) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1),
              ),
              barGroups: List.generate(topicNames.length, (i) {
                final score = _topicPerformance[topicNames[i]] ?? 0.0;
                // Color-code by performance
                final barColor = score >= 75
                    ? const Color(0xFF10B981)
                    : score >= 50
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFFEF4444);
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: score,
                    color: barColor,
                    width: 32,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ]);
              }),
            )),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendDot(const Color(0xFF10B981), '≥75% Excellent'),
              _legendDot(const Color(0xFF0EA5E9), '50–74% Good'),
              _legendDot(const Color(0xFFEF4444), '<50% Needs work'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — STUDENTS (with quiz progress from quiz_stats)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStudentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _studentsStream,
      builder: (context, studentsSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _enrollmentsStream,
          builder: (context, enrollSnap) {
            final students = studentsSnap.data?.docs ?? [];
            final enrollments = enrollSnap.data?.docs ?? [];

            final enrolledIds = enrollments
                .map((e) =>
                    (e.data() as Map<String, dynamic>)['userId'] as String?)
                .whereType<String>()
                .toSet();

            final enrolledCount =
                students.where((s) => enrolledIds.contains(s.id)).length;
            final notEnrolledCount = students.length - enrolledCount;

            return Column(children: [
              // Summary row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  _enrollCard('Total', '${students.length}',
                      const Color(0xFF0EA5E9), Icons.people),
                  const SizedBox(width: 8),
                  _enrollCard('Enrolled', '$enrolledCount',
                      const Color(0xFF10B981), Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  _enrollCard('Not Enrolled', '$notEnrolledCount',
                      const Color(0xFFEF4444), Icons.cancel_outlined),
                ]),
              ),
              // Filter chips
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['All', 'Enrolled', 'Not Enrolled', 'Pending'].map((f) {
                      final sel = _enrollmentFilter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _enrollmentFilter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF0EA5E9) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? const Color(0xFF0EA5E9)
                                    : const Color(0xFFE5E7EB)),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF6B7280))),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(child: _buildStudentList(students, enrolledIds)),
            ]);
          },
        );
      },
    );
  }

  Widget _enrollCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        ]),
      ),
    );
  }

  Widget _buildStudentList(
      List<QueryDocumentSnapshot> students, Set<String> enrolledIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: _onlineUsersStream,
      builder: (context, onlineSnap) {
        final onlineIds =
            (onlineSnap.data?.docs ?? []).map((d) => d.id).toSet();

        final filtered = students.where((s) {
          final isEnrolled = enrolledIds.contains(s.id);
          if (_enrollmentFilter == 'Enrolled') return isEnrolled;
          if (_enrollmentFilter == 'Not Enrolled') return !isEnrolled;
          if (_enrollmentFilter == 'Pending') {
            final data = s.data() as Map<String, dynamic>;
            return data['enrollmentStatus'] == 'pending';
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
              child: Text('No students found',
                  style: TextStyle(color: Color(0xFF6B7280))));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final doc = filtered[i];
            final data = doc.data() as Map<String, dynamic>;
            return _StudentCard(
              uid: doc.id,
              data: data,
              isEnrolled: enrolledIds.contains(doc.id),
              isOnline: onlineIds.contains(doc.id),
              db: _db,
              onEnroll: (uid, name) => _enrollStudent(uid, name),
            );
          },
        );
      },
    );
  }

  Future<void> _enrollStudent(String uid, String name) async {
    try {
      await _db.collection('enrollments').add({
        'userId': uid,
        'enrolledAt': FieldValue.serverTimestamp(),
        'status': 'enrolled',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name enrolled successfully'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3 — ACTIVITY FEED
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActivityTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _activitiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history, size: 48, color: Color(0xFF9CA3AF)),
              SizedBox(height: 12),
              Text('No recent activities',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
            ]),
          );
        }
        return Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0EA5E9).withOpacity(0.06),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Live feed · ${docs.length} recent events',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, i) => _ActivityTile(doc: docs[i]),
            ),
          ),
        ]);
      },
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _chartBox({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937))),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
        const SizedBox(height: 20),
        child,
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// STUDENT CARD — shows quiz progress from quiz_stats
// ══════════════════════════════════════════════════════════════════════════
class _StudentCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final bool isEnrolled;
  final bool isOnline;
  final FirebaseFirestore db;
  final Future<void> Function(String uid, String name) onEnroll;

  const _StudentCard({
    required this.uid,
    required this.data,
    required this.isEnrolled,
    required this.isOnline,
    required this.db,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        data['name'] as String? ?? data['fullName'] as String? ?? 'Unknown';
    final email = data['email'] as String? ?? '';
    final avatar =
        data['avatar'] as String? ?? data['profilePicture'] as String?;
    final enrollStatus = isEnrolled
        ? 'Enrolled'
        : (data['enrollmentStatus'] as String? ?? 'Not Enrolled');
    final statusColor = switch (enrollStatus.toLowerCase()) {
      'enrolled' => const Color(0xFF10B981),
      'pending' => const Color(0xFFF59E0B),
      _ => const Color(0xFFEF4444),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Avatar + online dot
            Stack(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.15),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0EA5E9)))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937))),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 6),
                    Row(children: [
                      _chip(
                        isOnline ? 'Online' : 'Offline',
                        isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFF9CA3AF),
                        isOnline ? Icons.wifi : Icons.wifi_off,
                      ),
                      const SizedBox(width: 6),
                      _chip(
                          enrollStatus,
                          statusColor,
                          isEnrolled
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked),
                    ]),
                  ]),
            ),
            if (!isEnrolled)
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.08),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => onEnroll(uid, name),
                child: const Text('Enroll',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
        // Quiz progress from quiz_stats — real data from student panel
        FutureBuilder<DocumentSnapshot>(
          future: db
              .collection('users')
              .doc(uid)
              .collection('quiz_stats')
              .doc('stats')
              .get(),
          builder: (context, snap) {
            if (!snap.hasData || !snap.data!.exists) {
              return _quizProgressBar(
                label: 'No quizzes taken yet',
                pct: 0,
                coins: 0,
                completed: 0,
                totalQuizzes: 0,
              );
            }
            final d = snap.data!.data() as Map<String, dynamic>;
            final completedTopics =
                (d['completed_topics'] as List<dynamic>? ?? []).length;
            final totalCoins = (d['total_coins'] as num?)?.toInt() ?? 0;
            final totalQuizzes = (d['total_quizzes'] as num?)?.toInt() ?? 0;
            final totalQuestions = (d['total_questions'] as num?)?.toInt() ?? 0;
            // approximate: each topic has ~3-5 questions; show ratio if we know
            final pct = totalQuestions > 0
                ? ((completedTopics / (completedTopics + 1).clamp(1, 99)) * 100)
                    .clamp(0.0, 100.0)
                : 0.0;
            return _quizProgressBar(
              label:
                  '$completedTopics topic${completedTopics == 1 ? "" : "s"} completed · $totalQuizzes quiz${totalQuizzes == 1 ? "" : "zes"}',
              pct: pct,
              coins: totalCoins,
              completed: completedTopics,
              totalQuizzes: totalQuizzes,
            );
          },
        ),
      ]),
    );
  }

  Widget _quizProgressBar({
    required String label,
    required double pct,
    required int coins,
    required int completed,
    required int totalQuizzes,
  }) {
    final barColor = pct >= 75
        ? const Color(0xFF10B981)
        : pct >= 40
            ? const Color(0xFF0EA5E9)
            : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Quiz progress',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          Row(children: [
            const Text('🪙', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 3),
            Text('$coins coins',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B))),
          ]),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ]),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ONLINE USERS BOTTOM SHEET — students, teachers, admins grouped
// ══════════════════════════════════════════════════════════════════════════
class _OnlineUsersSheet extends StatefulWidget {
  final List<QueryDocumentSnapshot> onlineDocs;
  final FirebaseFirestore db;

  const _OnlineUsersSheet({required this.onlineDocs, required this.db});

  @override
  State<_OnlineUsersSheet> createState() => _OnlineUsersSheetState();
}

class _OnlineUsersSheetState extends State<_OnlineUsersSheet> {
  List<Map<String, dynamic>> _resolvedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveUsers();
  }

  Future<void> _resolveUsers() async {
    final List<Map<String, dynamic>> resolved = [];
    for (final doc in widget.onlineDocs) {
      final uid = doc.id;
      try {
        final userDoc = await widget.db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final d = userDoc.data()!;
          resolved.add({
            'uid': uid,
            'name': d['name'] ?? d['fullName'] ?? d['email'] ?? 'Unknown',
            'email': d['email'] ?? '',
            'role': d['role'] ?? 'student',
            'avatar': d['avatar'] ?? d['profilePicture'],
          });
        } else {
          resolved.add({
            'uid': uid,
            'name': 'Unknown User',
            'email': '',
            'role': 'student',
            'avatar': null,
          });
        }
      } catch (_) {}
    }

    // Sort: admin → teacher → student
    resolved.sort((a, b) {
      const order = {'admin': 0, 'teacher': 1, 'student': 2};
      return (order[a['role']] ?? 3).compareTo(order[b['role']] ?? 3);
    });

    if (mounted)
      setState(() {
        _resolvedUsers = resolved;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('Online Now (${widget.onlineDocs.length})',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
          ]),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('All authenticated users currently online',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        if (_loading)
          const Expanded(
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0EA5E9))),
          )
        else if (_resolvedUsers.isEmpty)
          const Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 8),
                Text('No users online',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ]),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _resolvedUsers.length,
              itemBuilder: (context, i) {
                final u = _resolvedUsers[i];
                // Show role divider
                final showHeader =
                    i == 0 || _resolvedUsers[i - 1]['role'] != u['role'];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding:
                            EdgeInsets.only(top: i == 0 ? 4 : 16, bottom: 8),
                        child: Text(
                          _roleLabel(u['role'] as String),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9CA3AF),
                              letterSpacing: 0.8),
                        ),
                      ),
                    _onlineUserTile(u),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ]),
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'admin' => 'ADMINISTRATORS',
      'teacher' => 'TEACHERS',
      _ => 'STUDENTS',
    };
  }

  Color _roleColor(String role) {
    return switch (role) {
      'admin' => const Color(0xFF8B5CF6),
      'teacher' => const Color(0xFF0EA5E9),
      _ => const Color(0xFF10B981),
    };
  }

  Widget _onlineUserTile(Map<String, dynamic> u) {
    final role = u['role'] as String;
    final color = _roleColor(role);
    final name = u['name'] as String;
    final email = u['email'] as String;
    final avatar = u['avatar'] as String?;
    final initials = name
        .trim()
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(children: [
        Stack(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.15),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Text(initials,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
            ),
          ),
        ]),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937))),
          if (email.isNotEmpty)
            Text(email,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Text(role,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CLASSES BOTTOM SHEET — real grades + topic counts
// ══════════════════════════════════════════════════════════════════════════
class _ClassesSheet extends StatelessWidget {
  final Map<String, int> classTopicCounts;
  final FirebaseFirestore db;

  const _ClassesSheet({required this.classTopicCounts, required this.db});

  @override
  Widget build(BuildContext context) {
    final grades = classTopicCounts.keys.toList()..sort();
    final total = classTopicCounts.values.fold(0, (a, b) => a + b);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            const Icon(Icons.library_books_outlined,
                color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 8),
            Text('All Classes ($total topics)',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Grades and their topics from Firestore',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        Expanded(
          child: grades.isEmpty
              ? const Center(
                  child: Text('No grades found',
                      style: TextStyle(color: Color(0xFF9CA3AF))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grades.length,
                  itemBuilder: (context, i) {
                    final grade = grades[i];
                    final count = classTopicCounts[grade] ?? 0;
                    final pct = total > 0 ? count / total : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(grade,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937))),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                    '$count topic${count == 1 ? "" : "s"}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFF59E0B)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF59E0B)),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                '${(pct * 100).toStringAsFixed(0)}% of all topics',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF9CA3AF))),
                          ]),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ACTIVITY TILE
// ══════════════════════════════════════════════════════════════════════════
class _ActivityTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _ActivityTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] as String? ?? '';
    final userName = data['userName'] as String? ?? 'Unknown';
    final userRole = data['userRole'] as String? ?? 'student';
    final description = data['description'] as String? ?? '';
    final ts = data['timestamp'] as Timestamp?;
    final timeAgo = _timeAgo(ts?.toDate());

    final isTeacher = userRole == 'teacher';
    final avatarColor =
        isTeacher ? const Color(0xFF0EA5E9) : const Color(0xFF10B981);
    final initials = userName
        .trim()
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: avatarColor.withOpacity(0.15),
          child: Text(initials,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: avatarColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(userName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937))),
              ),
              Text(timeAgo,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text(_icon(type), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(description.isNotEmpty ? description : type,
                    style: TextStyle(
                        fontSize: 13,
                        color: _color(type),
                        fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _icon(String type) => switch (type) {
        'teacherSignup' || 'teacherLogin' => '👨‍🏫',
        'studentSignup' || 'studentLogin' => '👨‍🎓',
        'quizCreated' || 'quizPublished' => '📝',
        'quizCompleted' || 'quizSubmitted' => '✔️',
        'contentUpload' => '📤',
        'contentViewed' => '👀',
        'rewardEarned' || 'rewardIssued' => '🎁',
        'badgeReceived' || 'badgeAwarded' => '🏅',
        'achievementUnlocked' => '🌟',
        'userActivated' => '✅',
        'userDeactivated' => '❌',
        _ => '📌',
      };

  Color _color(String type) => switch (type) {
        'teacherSignup' || 'teacherLogin' => const Color(0xFF2196F3),
        'studentSignup' || 'studentLogin' => const Color(0xFF10B981),
        'quizCompleted' => const Color(0xFF059669),
        'rewardEarned' || 'badgeReceived' => const Color(0xFFF59E0B),
        'userDeactivated' => const Color(0xFFDC2626),
        _ => const Color(0xFF6B7280),
      };

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
