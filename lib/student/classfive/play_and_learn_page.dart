import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mission_one_page.dart';

class PlayAndLearnPage extends StatefulWidget {
  const PlayAndLearnPage({super.key});

  @override
  State<PlayAndLearnPage> createState() => _PlayAndLearnPageState();
}

class _PlayAndLearnPageState extends State<PlayAndLearnPage> {
  String selectedAvatar = '🐨'; // Default avatar

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAvatar = prefs.getString('student_avatar') ?? '🐨';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Profile avatar - simple circle
          GestureDetector(
            onTap: () {
              // Show profile or navigate to profile page
            },
            child: Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Color(0xFF81D4FA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  selectedAvatar,
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chapter Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF9C27B0),
                            Color(0xFF2196F3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Chapter 1',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.yellow, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '0',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Matter',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Spacer(),
                              Text(
                                '0%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 0.0,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Topics List
                    _buildTopicCard(
                      context,
                      icon: Icons.lightbulb_outline,
                      iconColor: Color(0xFFFFA726),
                      title: 'What is Matter?',
                      description:
                          'Help find things that have mass and occupy space.',
                      isUnlocked: true,
                      showStartButton: true,
                    ),
                    const SizedBox(height: 16),

                    _buildTopicCard(
                      context,
                      icon: Icons.grain,
                      iconColor: Color(0xFF66BB6A),
                      title: 'Tiny Particles',
                      description:
                          'Discover how matter is made of tiny particles.',
                      isUnlocked: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTopicCard(
                      context,
                      icon: Icons.category_outlined,
                      iconColor: Color(0xFF42A5F5),
                      title: 'Characteristics',
                      description: 'Learn the special properties of matter.',
                      isUnlocked: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTopicCard(
                      context,
                      icon: Icons.water_drop_outlined,
                      iconColor: Color(0xFF26C6DA),
                      title: 'States of Matter',
                      description: 'Explore the three states of matter.',
                      isUnlocked: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTopicCard(
                      context,
                      icon: Icons.square_outlined,
                      iconColor: Color(0xFF8D6E63),
                      title: 'Solids',
                      description: 'Understand solid materials around you.',
                      isUnlocked: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTopicCard(
                      context,
                      icon: Icons.opacity_outlined,
                      iconColor: Color(0xFF29B6F6),
                      title: 'Liquids',
                      description: 'Discover liquids and how they flow.',
                      isUnlocked: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTopicCard(
                      context,
                      icon: Icons.cloud_outlined,
                      iconColor: Color(0xFFB0BEC5),
                      title: 'Gases',
                      description: 'Learn about gases we cannot always see.',
                      isUnlocked: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTopicCard(
                      context,
                      icon: Icons.sync_alt,
                      iconColor: Color(0xFF7E57C2),
                      title: 'Changes in Matter',
                      description:
                          'See how matter changes from one state to another.',
                      isUnlocked: false,
                    ),
                    const SizedBox(height: 16),

                    _buildTopicCard(
                      context,
                      icon: Icons.emoji_events_outlined,
                      iconColor: Color(0xFFFF7043),
                      title: 'Boss Quiz 🎯',
                      description: 'Test everything you learned!',
                      isUnlocked: false,
                      isBossQuiz: true,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Start Learning Button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF5F3FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF9C27B0),
                    Color(0xFF2196F3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF9C27B0).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Start first unlocked topic
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MissionOnePage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Start Learning',
                          style: TextStyle(
                            fontSize: 18,
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
        ],
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isUnlocked,
    bool showStartButton = false,
    bool isBossQuiz = false,
  }) {
    return GestureDetector(
      onTap: isUnlocked
          ? () {
              // Navigate to mission page for unlocked topics
              if (title == 'Lets Learn about Matter') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MissionOnePage(),
                  ),
                );
              }
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? iconColor.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? iconColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? icon : Icons.lock,
                color: isUnlocked ? iconColor : Colors.grey.shade400,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Colors.grey.shade800
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnlocked
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showStartButton) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.play_arrow,
                            color: Color(0xFFFF5722), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Start Mission',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Arrow for unlocked items
            if (isUnlocked)
              Icon(
                Icons.arrow_forward_ios,
                color: iconColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
