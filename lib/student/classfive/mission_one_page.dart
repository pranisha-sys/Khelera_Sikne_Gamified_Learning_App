import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'student_question_view.dart'; // Import the quiz widget

// Mission One Page - Introduction
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
      backgroundColor: const Color(0xFFE8EAF6),
      body: SafeArea(
        child: Column(
          children: [
            // Top section with back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Back button - returns to PlayAndLearnPage
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
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
                                  color: Colors.purple.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF9C27B0),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
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
                      'Lets Learn about Matter',
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
                            color: const Color(0xFFFFD54F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD54F).withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: _handRotationAnimation.value,
                              child: const Text(
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
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        '👉 Matter is anything that has weight and takes up space—even your school bag and the air that messes up your hair! 😂🎒💨',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF000000),
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
                color: const Color(0xFFE8EAF6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
                      color: const Color(0xFF00C853).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      // Navigate to StudentMatterTopicPage
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentMatterTopicPage(
                            grade: 'Grade 5',
                            topicId: 'what_is_matter',
                          ),
                        ),
                      );

                      // If quiz was completed, return true to PlayAndLearnPage
                      if (result == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lets Go Partner',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
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

// Student Matter Topic Page - Lesson Content + Quiz
class StudentMatterTopicPage extends StatefulWidget {
  final String grade; // e.g., "Grade 5"
  final String topicId; // e.g., "what_is_matter"

  const StudentMatterTopicPage({
    super.key,
    required this.grade,
    required this.topicId,
  });

  @override
  State<StudentMatterTopicPage> createState() => _StudentMatterTopicPageState();
}

class _StudentMatterTopicPageState extends State<StudentMatterTopicPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentLevel = 1;

  AnimationController? _slideController;
  Animation<Offset>? _slideFromLeft;
  Animation<Offset>? _slideFromRight;
  Animation<double>? _fadeAnimation;

  bool _isQuizButtonHovered = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Slide from left animation
    _slideFromLeft = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeOutCubic,
    ));

    // Slide from right animation
    _slideFromRight = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeIn,
    ));

    // Start animations
    _slideController!.forward();
  }

  @override
  void dispose() {
    _slideController?.dispose();
    super.dispose();
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'cyan':
        return const Color(0xFF06B6D4);
      case 'pink':
        return const Color(0xFFEC4899);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'orange':
        return const Color(0xFFF97316);
      case 'green':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF60A5FA);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          // Real-time listener for content updates
          stream: _firestore
              .doc('grades/${widget.grade}/topics/${widget.topicId}')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                      strokeWidth: 5,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading your adventure... 🚀',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: const Text(
                        'Please try again or ask your teacher for help',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No content available yet',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check back soon! 📚',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Extract data from Firestore
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Loading...';
            final description = data['description'] ?? '';
            final examples =
                List<Map<String, dynamic>>.from(data['examples'] ?? []);
            final funFact = data['funFact'] ?? '';

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar with Back Button and Level Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: Colors.grey.shade800, size: 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // Level Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFBBF24).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '⭐',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Level',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_currentLevel',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Main Content Card with Slide Animation
                  if (_slideFromLeft != null && _fadeAnimation != null)
                    SlideTransition(
                      position: _slideFromLeft!,
                      child: FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 20,
                          ),
                          padding: EdgeInsets.all(isTablet ? 32 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Title with decorative elements
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF8B5CF6).withOpacity(0.1),
                                      const Color(0xFFEC4899).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 32 : 26,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF7C3AED),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Icon/Image - Improved with better gradient
                              Container(
                                width: isTablet ? 140 : 120,
                                height: isTablet ? 140 : 120,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6)
                                          .withOpacity(0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Image.asset(
                                      'assets/images/chemistry_icon.png',
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // Fallback icon if image not found
                                        return const Icon(
                                          Icons.science,
                                          size: 60,
                                          color: Colors.white,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Description Box - More playful design
                              if (description.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFEF3C7),
                                        Color(0xFFFDE68A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFFBBF24),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFBBF24)
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '📖',
                                        style: TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          description,
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontSize: isTablet ? 16 : 15,
                                            height: 1.6,
                                            color: const Color(0xFF92400E),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 32),

                              // Examples Section Title
                              if (examples.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '✨',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Examples of Matter',
                                      style: TextStyle(
                                        fontSize: isTablet ? 22 : 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '✨',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Grid of Examples - Enhanced design
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: isTablet ? 1.1 : 1.0,
                                  ),
                                  itemCount: examples.length,
                                  itemBuilder: (context, index) {
                                    final example = examples[index];
                                    final name = example['name'] ?? '';
                                    final icon = example['icon'] ?? '';
                                    final colorName =
                                        example['color'] ?? 'blue';
                                    final color =
                                        _getColorFromString(colorName);

                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color.withOpacity(0.2),
                                            color.withOpacity(0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: color.withOpacity(0.5),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (icon.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        color.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                icon,
                                                style: TextStyle(
                                                  fontSize: isTablet ? 44 : 36,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Text(
                                              name,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: isTablet ? 16 : 15,
                                                fontWeight: FontWeight.bold,
                                                color: color.withOpacity(1.0),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),
                              ],

                              // Fun Fact Section - More engaging
                              if (funFact.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF3E8FF),
                                        Color(0xFFE9D5FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF8B5CF6),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6)
                                            .withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              '💡',
                                              style: TextStyle(fontSize: 28),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Fun Fact!',
                                            style: TextStyle(
                                              fontSize: isTablet ? 22 : 20,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        funFact,
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 15,
                                          height: 1.7,
                                          color: const Color(0xFF581C87),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: isTablet ? 32 : 24),

                  // Start Quiz Button with Slide from Right and Hover Animation
                  if (_slideFromRight != null && _fadeAnimation != null)
                    SlideTransition(
                      position: _slideFromRight!,
                      child: FadeTransition(
                        opacity: _fadeAnimation!,
                        child: MouseRegion(
                          onEnter: (_) =>
                              setState(() => _isQuizButtonHovered = true),
                          onExit: (_) =>
                              setState(() => _isQuizButtonHovered = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32 : 20,
                            ),
                            width: double.infinity,
                            height: isTablet ? 64 : 60,
                            transform: Matrix4.identity()
                              ..scale(_isQuizButtonHovered ? 1.05 : 1.0)
                              ..translate(
                                  0.0, _isQuizButtonHovered ? -4.0 : 0.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isQuizButtonHovered
                                    ? const [
                                        Color(0xFFFCD34D),
                                        Color(0xFFFBBF24)
                                      ]
                                    : const [
                                        Color(0xFFFBBF24),
                                        Color(0xFFF59E0B)
                                      ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFBBF24).withOpacity(
                                    _isQuizButtonHovered ? 0.6 : 0.5,
                                  ),
                                  blurRadius: _isQuizButtonHovered ? 20 : 16,
                                  offset:
                                      Offset(0, _isQuizButtonHovered ? 8 : 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  // Navigate to Student Question View (Quiz)
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudentQuestionView(
                                        grade: widget.grade,
                                        topicId: widget.topicId,
                                        studentId:
                                            'student_${DateTime.now().millisecondsSinceEpoch}',
                                      ),
                                    ),
                                  );

                                  // If quiz was completed, return true to previous page
                                  if (result == true && mounted) {
                                    Navigator.pop(context, true);
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 1.0,
                                          end: _isQuizButtonHovered ? 1.2 : 1.0,
                                        ),
                                        duration:
                                            const Duration(milliseconds: 200),
                                        builder: (context, scale, child) {
                                          return Transform.scale(
                                            scale: scale,
                                            child: const Text(
                                              '🎯',
                                              style: TextStyle(fontSize: 28),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Start Quiz: Introduction to Matter',
                                        style: TextStyle(
                                          fontSize: isTablet ? 20 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: isTablet ? 24 : 20),

                  // Help Button with Slide Animation
                  if (_slideFromRight != null && _fadeAnimation != null)
                    SlideTransition(
                      position: _slideFromRight!,
                      child: FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      title: const Row(
                                        children: [
                                          Text('🤔'),
                                          SizedBox(width: 8),
                                          Text('Need Help?'),
                                        ],
                                      ),
                                      content: const Text(
                                        'This content is managed by your teacher. If you have questions, please ask your teacher!',
                                        style: TextStyle(
                                            fontSize: 16, height: 1.5),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF8B5CF6),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Got it! 👍',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.help_outline,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Need Help?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
