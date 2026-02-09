import 'package:flutter/material.dart';

class MissionOnePage extends StatefulWidget {
  const MissionOnePage({super.key});

  @override
  State<MissionOnePage> createState() => _MissionOnePageState();
}

class _MissionOnePageState extends State<MissionOnePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _handRotationAnimation;
  late Animation<double> _badgeBounceAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller for hand rotation and badge bounce
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Hand rotation animation (left to right)
    _handRotationAnimation = Tween<double>(
      begin: -0.2, // Rotate left
      end: 0.2, // Rotate right
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Badge bounce animation (up and down)
    _badgeBounceAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8EAF6),
      body: SafeArea(
        child: Column(
          children: [
            // Top section with back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Mission 1 Badge with bounce animation
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _badgeBounceAnimation.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF9C27B0),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mission 1',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9C27B0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Title
                    Text(
                      'What is Matter?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Circle with animated hand inside
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFD54F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFFD54F).withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: _handRotationAnimation.value,
                              child: Text(
                                '👆',
                                style: TextStyle(fontSize: 100),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 50),

                    // Instruction text
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Tap all items that are matter',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Fixed Start Mission Button at bottom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFE8EAF6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF00C853),
                      Color(0xFF00E676),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00C853).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navigate to game/quiz page
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Mission',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '🚀',
                            style: TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
