import 'package:flutter/material.dart';

import 'create_quiz_from_scratch_page.dart';

class CreateQuizMethodPage extends StatefulWidget {
  const CreateQuizMethodPage({super.key});

  @override
  State<CreateQuizMethodPage> createState() => _CreateQuizMethodPageState();
}

class _CreateQuizMethodPageState extends State<CreateQuizMethodPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6), // Blue
              Color(0xFF2563EB), // Darker Blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back Button ──
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),

              // ── Header ──
              const Padding(
                padding: EdgeInsets.fromLTRB(32, 16, 32, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Quiz',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose how you\'d like to create your quiz',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Options ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // ── Create from Scratch Option ──
                        _buildOptionCard(
                          icon: Icons.edit_outlined,
                          title: 'Create from Scratch',
                          badge: 'POPULAR',
                          badgeColor: const Color(0xFFDCFCE7),
                          badgeTextColor: const Color(0xFF16A34A),
                          description:
                              'Manually add and customize your quiz questions with full control.',
                          gradientColors: const [
                            Color(0xFF3B82F6),
                            Color(0xFF2563EB),
                          ],
                          borderColor: const Color(0xFF3B82F6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreateQuizFromScratchPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 42),

                        // ── Pro Tip ──
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFDE047),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFACC15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  color: Color(0xFF713F12),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pro Tip',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF713F12),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create from Scratch gives you complete control over your quiz questions and customization.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF713F12)
                                            .withOpacity(0.8),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Build Option Card Widget ──
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String description,
    required List<Color> gradientColors,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: borderColor.withOpacity(0.1),
        highlightColor: borderColor.withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
                const SizedBox(width: 20),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF9CA3AF),
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
