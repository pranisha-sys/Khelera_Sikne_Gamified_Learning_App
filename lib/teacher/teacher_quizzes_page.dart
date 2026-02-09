import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'create_quiz_method_page.dart';
import 'edit_quiz_page.dart';
import 'teacher_my_classes_page.dart';
import 'teacher_profile_page.dart';

class TeacherQuizzesPage extends StatefulWidget {
  const TeacherQuizzesPage({super.key});

  @override
  State<TeacherQuizzesPage> createState() => _TeacherQuizzesPageState();
}

class _TeacherQuizzesPageState extends State<TeacherQuizzesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // ── App Bar ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quizzes',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),

      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Please log in'),
                  const SizedBox(height: 8),
                  Text('User ID: ${user?.uid ?? 'null'}'),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('quizzes')
                  .where('teacherId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading quizzes...'),
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
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Error loading quizzes'),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final quizDocs = snapshot.data?.docs ?? [];

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Create New Quiz Button ──
                      InkWell(
                        onTap: _navigateToCreateQuiz,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Create New Quiz',
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

                      const SizedBox(height: 32),

                      // ── Quizzes List ──
                      if (quizDocs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No quizzes yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first quiz to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: quizDocs.length,
                          itemBuilder: (context, index) {
                            final doc = quizDocs[index];
                            final quiz = doc.data() as Map<String, dynamic>;

                            return _buildQuizCard(
                              quizId: doc.id,
                              title: quiz['title'] ?? 'Untitled Quiz',
                              topic: quiz['topic'] ?? '',
                              questions: quiz['questionCount'] ?? 0,
                              totalStudents: quiz['totalStudents'] ?? 0,
                              createdAt: quiz['createdAt'] as Timestamp?,
                              onTap: () {
                                debugPrint('Viewing quiz: ${quiz['title']}');
                              },
                              onEdit: () => _editQuiz(doc.id, quiz),
                              onDelete: () => _deleteQuiz(doc.id),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),

      // ── Shared Bottom Navigation Bar ──
      bottomNavigationBar: _buildSharedNavBar(
        context: context,
        activeIndex: 2, // Quizzes tab
      ),
    );
  }

  void _navigateToCreateQuiz() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateQuizMethodPage(),
      ),
    );
  }

  Future<void> _editQuiz(String quizId, Map<String, dynamic> quizData) async {
    try {
      final questionsSnapshot = await _firestore
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .orderBy('questionNumber')
          .get();

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditQuizPage(
              quizId: quizId,
              quizData: quizData,
              questionsSnapshot: questionsSnapshot,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        final questionsSnapshot = await _firestore
            .collection('quizzes')
            .doc(quizId)
            .collection('questions')
            .get();

        for (var doc in questionsSnapshot.docs) {
          await doc.reference.delete();
        }

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

  Widget _buildQuizCard({
    required String quizId,
    required String title,
    required String topic,
    required int questions,
    required int totalStudents,
    required Timestamp? createdAt,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    String formattedDate = 'Just now';
    if (createdAt != null) {
      final date = createdAt.toDate();
      formattedDate = DateFormat('MMM d, yyyy').format(date);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                          Icon(Icons.edit, size: 20, color: Color(0xFF3B82F6)),
                          SizedBox(width: 12),
                          Text('Edit'),
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
                      onDelete();
                    } else if (value == 'edit') {
                      onEdit();
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.label,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      topic,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$questions',
                            style: const TextStyle(
                              fontSize: 20,
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalStudents',
                            style: const TextStyle(
                              fontSize: 20,
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
    );
  }

  /// Shared Navigation Bar Widget
  Widget _buildSharedNavBar({
    required BuildContext context,
    required int activeIndex,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                isActive: activeIndex == 0,
                onTap: () => Navigator.pop(context),
              ),
              _buildNavItem(
                icon: Icons.school_outlined,
                label: 'My Classes',
                isActive: activeIndex == 1,
                onTap: () {
                  if (activeIndex != 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherMyClassesPage(),
                      ),
                    );
                  }
                },
              ),
              _buildNavItem(
                icon: Icons.assignment_outlined,
                label: 'Quizzes',
                isActive: activeIndex == 2,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.trending_up,
                label: 'Progress',
                isActive: activeIndex == 3,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Progress page - Coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isActive: activeIndex == 4,
                onTap: () {
                  if (activeIndex != 4) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherProfilePage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isActive ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
