import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'student_question_view.dart';

class MissionOnePage extends StatefulWidget {
  const MissionOnePage({super.key});

  @override
  State<MissionOnePage> createState() => _MissionOnePageState();
}

class _MissionOnePageState extends State<MissionOnePage>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;
  late AnimationController _handController;
  late Animation<double> _handSlide;
  late Animation<double> _handFade;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
        duration: const Duration(milliseconds: 1800), vsync: this)
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _breatheController = AnimationController(
        duration: const Duration(milliseconds: 2200), vsync: this)
      ..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut));

    _handController = AnimationController(
        duration: const Duration(milliseconds: 1800), vsync: this)
      ..repeat();

    _handSlide = Tween<double>(begin: -44.0, end: 44.0).animate(CurvedAnimation(
        parent: _handController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)));

    _handFade = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 18),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 54),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 28),
    ]).animate(_handController);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _breatheController.dispose();
    _handController.dispose();
    super.dispose();
  }

  Future<void> _navigateToMission(BuildContext context) async {
    final nav = Navigator.of(context);
    final result = await nav.push(
      MaterialPageRoute(
        builder: (_) => const StudentMatterTopicPage(
            grade: 'Grade 5', topicId: 'what_is_matter'),
      ),
    );
    if (!mounted) return;
    if (result == true) nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final circleSize = size.width * 0.60;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEBFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _circleBackButton(),
                  ),
                  _missionBadge(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      "Lets Learn about Matter",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00BCD4),
                        height: 1.18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 38),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _breatheController,
                        _glowController,
                        _handController,
                      ]),
                      builder: (_, __) {
                        return Transform.scale(
                          scale: _breatheAnim.value,
                          child: Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFC107),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFE57F).withValues(
                                      alpha: _glowAnim.value * 0.62),
                                  blurRadius: 70,
                                  spreadRadius: 22,
                                ),
                                const BoxShadow(
                                  color: Color(0x40FF8F00),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.white
                                                .withValues(alpha: 0.20),
                                            Colors.transparent,
                                          ],
                                          center: const Alignment(-0.3, -0.4),
                                          radius: 0.65,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(_handSlide.value, 0),
                                    child: Opacity(
                                      opacity: _handFade.value,
                                      child: const Text(
                                        '👆',
                                        style: TextStyle(fontSize: 76),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    _factCard(
                      'Matter is anything that has weight and takes up space — even your school bag and the air that messes up your hair! 😂🎒💨',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _ctaButton(context),
          ],
        ),
      ),
    );
  }

  Widget _circleBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1A1A2E),
          size: 17,
        ),
      ),
    );
  }

  Widget _missionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFAB6EFF), Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 1),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 12),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Mission 1',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Center(child: Text('👉', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2D2D3A),
                fontSize: 15,
                height: 1.62,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: GestureDetector(
        onTap: () => _navigateToMission(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2ECC71), Color(0xFF1DB954)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF27AE60).withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🚀', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text(
                "Lets Go Partner",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
//  Student Matter Topic Page (unchanged)
// ────────────────────────────────────────────
class StudentMatterTopicPage extends StatefulWidget {
  final String grade;
  final String topicId;

  const StudentMatterTopicPage(
      {super.key, required this.grade, required this.topicId});

  @override
  State<StudentMatterTopicPage> createState() => _StudentMatterTopicPageState();
}

class _StudentMatterTopicPageState extends State<StudentMatterTopicPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideIn;
  late Animation<double> _fadeIn;
  bool _quizHovered = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeIn));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Color _colorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'blue':
        return const Color(0xFF1565C0);
      case 'cyan':
        return const Color(0xFF00838F);
      case 'pink':
        return const Color(0xFFE91E63);
      case 'purple':
        return const Color(0xFF9C27B0);
      case 'orange':
        return const Color(0xFFE65100);
      case 'green':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .doc('grades/${widget.grade}/topics/${widget.topicId}')
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snap.hasError || !snap.hasData || !snap.data!.exists) {
              return _buildEmpty();
            }
            final data = snap.data!.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'What is Matter?';
            final description = data['description'] ?? '';
            final examples =
                List<Map<String, dynamic>>.from(data['examples'] ?? []);
            final funFact = data['funFact'] ?? '';

            return FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildTopBar(isTablet),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 28 : 16),
                        child: Column(
                          children: [
                            _buildHeroSection(title, isTablet),
                            const SizedBox(height: 18),
                            if (description.isNotEmpty)
                              _buildDescription(description, isTablet),
                            if (examples.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildExamplesSection(examples, isTablet),
                            ],
                            if (funFact.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _buildFunFact(funFact, isTablet),
                            ],
                            const SizedBox(height: 26),
                            _buildQuizButton(isTablet),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF9C27B0), strokeWidth: 3),
            SizedBox(height: 16),
            Text('Loading adventure... 🚀',
                style: TextStyle(color: Color(0xFF006064), fontSize: 15)),
          ],
        ),
      );

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📚', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text('Content not found',
                style: TextStyle(color: Color(0xFF1565C0), fontSize: 18)),
            SizedBox(height: 8),
            Text('Ask your teacher!',
                style: TextStyle(color: Color(0xFF006064), fontSize: 14)),
          ],
        ),
      );

  Widget _buildTopBar(bool isTablet) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(isTablet ? 28 : 16, 12, isTablet ? 28 : 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB2DFDB)),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Color(0xFF006064), size: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 10)
              ],
            ),
            child: const Row(children: [
              Text('⭐', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('Level 1',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(String title, bool isTablet) {
    return Column(children: [
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('SCIENCE • GRADE 5',
            style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w900)),
      ),
      const SizedBox(height: 12),
      Text(title,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: isTablet ? 30 : 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A2E),
              height: 1.2)),
      const SizedBox(height: 18),
      Container(
        width: isTablet ? 140 : 120,
        height: isTablet ? 140 : 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: const Center(child: Text('⚗️', style: TextStyle(fontSize: 58))),
      ),
    ]);
  }

  Widget _buildDescription(String desc, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📖', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(desc,
                style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: isTablet ? 15 : 14,
                    height: 1.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesSection(
      List<Map<String, dynamic>> examples, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('✨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('Examples of Matter',
              style: TextStyle(
                  color: const Color(0xFF1565C0),
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: examples.length,
          itemBuilder: (_, i) {
            final ex = examples[i];
            final color = _colorFromName(ex['color'] ?? 'blue');
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.1)),
                    child: Text(ex['icon'] ?? '🔵',
                        style: const TextStyle(fontSize: 34)),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(ex['name'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 14 : 13)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFunFact(String fact, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('💡', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Fun Fact!',
                style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ]),
          const SizedBox(height: 10),
          Text(fact,
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: isTablet ? 14 : 13,
                  height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildQuizButton(bool isTablet) {
    return MouseRegion(
      onEnter: (_) => setState(() => _quizHovered = true),
      onExit: (_) => setState(() => _quizHovered = false),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentQuestionView(
                grade: widget.grade,
                topicId: widget.topicId,
                studentId: 'student_${DateTime.now().millisecondsSinceEpoch}',
              ),
            ),
          );
          if (!mounted) return;
          if (result == true) Navigator.pop(context, true);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          transform:
              Matrix4.translationValues(0.0, _quizHovered ? -4.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFFD500F9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF)
                    .withValues(alpha: _quizHovered ? 0.55 : 0.38),
                blurRadius: _quizHovered ? 22 : 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text('Start Quiz!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 20 : 17,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}
