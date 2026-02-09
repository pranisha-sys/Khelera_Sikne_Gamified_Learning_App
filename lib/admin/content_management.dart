import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({Key? key}) : super(key: key);

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  // Store topic count for grade 5 only
  int _topicCount = 0;
  bool _isLoading = true;

  // Only Grade 5 data
  final Map<String, dynamic> _gradeData = {
    'grade': 5,
    'color': const Color(0xFF0EA5E9),
    'icon': '📘',
    'description': 'Matter fundamentals for Grade 5'
  };

  @override
  void initState() {
    super.initState();
    _fetchTopicCount();
  }

  // Fetch topic count for grade 5 from Firebase
  Future<void> _fetchTopicCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Matter_subtopics')
          .where('grade', isEqualTo: 5)
          .get();

      setState(() {
        _topicCount = snapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading topics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0EA5E9),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              '🔬',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Matter Content',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Manage Grade 5 topics',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Grade Section Title
                    const Text(
                      'Grade 5 Content',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'View and manage Grade 5 Matter subtopics',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Grade 5 Card
                    _buildGradeCard(
                      grade: _gradeData['grade'],
                      topicCount: _topicCount,
                      color: _gradeData['color'],
                      icon: _gradeData['icon'],
                      description: _gradeData['description'],
                    ),

                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGradeCard({
    required int grade,
    required int topicCount,
    required Color color,
    required String icon,
    required String description,
  }) {
    return GestureDetector(
      onTap: () {
        _showGradeDetailsDialog(grade, topicCount, color, icon, description);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Grade Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade $grade',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 18,
                        color: const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$topicCount ${topicCount == 1 ? 'topic' : 'topics'}',
                        style: TextStyle(
                          fontSize: 15,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradeDetailsDialog(
    int grade,
    int topicCount,
    Color color,
    String icon,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade $grade',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.book_outlined,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Topics',
                        style: TextStyle(
                          fontSize: 13,
                          color: color.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topicCount.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showTopicsListDialog(grade, color);
            },
            icon: const Icon(Icons.list, size: 18),
            label: const Text('View Topics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTopicsListDialog(int grade, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.topic_outlined,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Grade $grade Topics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('Matter_subtopics')
                .where('grade', isEqualTo: grade)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No topics found for this grade'),
                );
              }

              final topics = snapshot.data!.docs;

              return ListView.builder(
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index].data() as Map<String, dynamic>;
                  final topicName = topic['name'] ?? 'Unnamed Topic';
                  final topicId = topics[index].id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topicName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: $topicId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Edit topic: $topicName'),
                                  ),
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () {
                                _showDeleteConfirmation(topicName, topicId);
                              },
                            ),
                          ],
                          child: Icon(
                            Icons.more_vert,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddTopicDialog(grade, color);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Topic'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTopicDialog(int grade, Color color) {
    final TextEditingController topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Add New Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                hintText: 'Enter topic name',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (topicController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a topic name'),
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('Matter_subtopics')
                    .add({
                  'name': topicController.text,
                  'grade': grade,
                  'createdAt': DateTime.now(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Topic added successfully'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  // Refresh the count
                  _fetchTopicCount();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String topicName, String topicId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete Topic'),
        content: Text('Are you sure you want to delete "$topicName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('Matter_subtopics')
                    .doc(topicId)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Topic deleted successfully'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  // Refresh the count
                  _fetchTopicCount();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
