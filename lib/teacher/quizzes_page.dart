import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'create_quiz_method_page.dart';

class QuizzesPage extends StatefulWidget {
  const QuizzesPage({super.key});

  @override
  State<QuizzesPage> createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('quizzes')
                  .where('teacherId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildQuizList(snapshot.data!.docs);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),

            // Text
            const Text(
              'No quizzes yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first quiz to get started',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Create Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateQuizMethodPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList(List<QueryDocumentSnapshot> docs) {
    return Column(
      children: [
        // Create New Quiz Button
        Container(
          margin: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateQuizMethodPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Quiz List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final quiz = docs[index].data() as Map<String, dynamic>;
              return _buildQuizCard(docs[index].id, quiz);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(String quizId, Map<String, dynamic> quiz) {
    final title = quiz['title'] ?? 'Untitled Quiz';
    final questionCount = quiz['questionCount'] ?? 0;
    final totalStudents = quiz['totalStudents'] ?? 0;
    final createdAt = quiz['createdAt'] as Timestamp?;
    final topic = quiz['topic'] ?? '';

    String formattedDate = 'Just now';
    if (createdAt != null) {
      final date = createdAt.toDate();
      formattedDate = DateFormat('MMM d, yyyy').format(date);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to quiz details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz details coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Quiz Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.quiz,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // More Options
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit,
                                size: 20, color: Color(0xFF3B82F6)),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share,
                                size: 20, color: Color(0xFF10B981)),
                            SizedBox(width: 12),
                            Text('Share'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete,
                                size: 20, color: Color(0xFFEF4444)),
                            SizedBox(width: 12),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteQuiz(quizId);
                      } else if (value == 'edit') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit coming soon!')),
                        );
                      } else if (value == 'share') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share coming soon!')),
                        );
                      }
                    },
                  ),
                ],
              ),

              if (topic.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                children: [
                  // Questions Count
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.question_answer,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$questionCount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Text(
                              'Questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Students Count
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalStudents',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Text(
                              'Students',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteQuiz(String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text(
          'Are you sure you want to delete this quiz? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete all questions in the quiz
        final questionsSnapshot = await _firestore
            .collection('quizzes')
            .doc(quizId)
            .collection('questions')
            .get();

        for (var doc in questionsSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete the quiz document
        await _firestore.collection('quizzes').doc(quizId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz deleted successfully'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting quiz: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
