import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────────
//  MissionOnePage — pure intro/splash screen.
//  Navigation is now handled entirely by PlayAndLearnPage via
//  _openTopicContentPage → _TopicContentPage → TopicInlineQuizPage.
//  This page no longer acts as a gate and contains no routing logic.
// ────────────────────────────────────────────────────────────────
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

  // ✅ "Let's Go" now simply pops back to the caller.
  // PlayAndLearnPage._navigateToLesson will immediately open
  // _TopicContentPage after this returns, so the quiz loads correctly.
  Widget _ctaButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
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
