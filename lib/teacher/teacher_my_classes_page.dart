import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import the content editor page for teachers
import 'topic_content_editor_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TEACHER MY CLASSES PAGE
// ─────────────────────────────────────────────────────────────────────────────
class TeacherMyClassesPage extends StatefulWidget {
  const TeacherMyClassesPage({super.key});

  @override
  State<TeacherMyClassesPage> createState() => _TeacherMyClassesPageState();
}

class _TeacherMyClassesPageState extends State<TeacherMyClassesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _assignedGrades = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _teacherName = '';
  String _teacherEmail = '';

  final Map<String, Map<String, dynamic>> _gradeInfo = {
    'Grade 5': {
      'grade': 'Grade 5',
      'gradeNumber': 5,
      'color': const Color(0xFF3B82F6),
      'icon': '📘',
      'description': 'Basic fundamentals',
      'firestoreId': 'Grade 5',
    },
    'Grade 6': {
      'grade': 'Grade 6',
      'gradeNumber': 6,
      'color': const Color(0xFF0EA5E9),
      'icon': '📘',
      'description': 'Matter fundamentals',
      'firestoreId': 'Grade 6',
    },
    'Grade 7': {
      'grade': 'Grade 7',
      'gradeNumber': 7,
      'color': const Color(0xFF8B5CF6),
      'icon': '📗',
      'description': 'States of matter',
      'firestoreId': 'Grade 7',
    },
    'Grade 8': {
      'grade': 'Grade 8',
      'gradeNumber': 8,
      'color': const Color(0xFFF59E0B),
      'icon': '📙',
      'description': 'Atomic structure',
      'firestoreId': 'Grade 8',
    },
    'Grade 9': {
      'grade': 'Grade 9',
      'gradeNumber': 9,
      'color': const Color(0xFFDC2626),
      'icon': '📕',
      'description': 'Chemical reactions',
      'firestoreId': 'Grade 9',
    },
    'Grade 10': {
      'grade': 'Grade 10',
      'gradeNumber': 10,
      'color': const Color(0xFFEC4899),
      'icon': '📔',
      'description': 'Advanced chemistry',
      'firestoreId': 'Grade 10',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadAssignedGrades();
  }

  Future<void> _loadAssignedGrades() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        setState(() {
          _assignedGrades = [];
          _isLoading = false;
          _errorMessage = 'User profile not found';
        });
        return;
      }

      final data = userDoc.data()!;
      _teacherName = data['name'] ?? 'Unknown';
      _teacherEmail = data['email'] ?? user.email ?? '';

      final Set<String> assignedGradesSet = {};

      if (data['assignedGrades'] is List) {
        for (var g in data['assignedGrades'] as List) {
          if (g is String && g.isNotEmpty) assignedGradesSet.add(g);
        }
      }
      for (int i = 5; i <= 10; i++) {
        if (data['grade${i}Access'] == true) {
          assignedGradesSet.add('Grade $i');
        }
      }

      final gradesList = assignedGradesSet
          .where(_gradeInfo.containsKey)
          .map((g) => _gradeInfo[g]!)
          .toList()
        ..sort((a, b) =>
            (a['gradeNumber'] as int).compareTo(b['gradeNumber'] as int));

      setState(() {
        _assignedGrades = gradesList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading grades: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0EA5E9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Classes',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAssignedGrades,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
          : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _assignedGrades.isEmpty
                  ? _buildNoGradesWidget()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner
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
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Text('🎓',
                                    style: TextStyle(fontSize: 40)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Your Assigned Grades',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_assignedGrades.length} grade${_assignedGrades.length == 1 ? '' : 's'} assigned',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70),
                                      ),
                                    ]),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 24),

                          // Teacher info card
                          if (_teacherName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF0EA5E9)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Center(
                                      child: Text('👨‍🏫',
                                          style: TextStyle(fontSize: 28))),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(_teacherName,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937))),
                                      const SizedBox(height: 4),
                                      Text(_teacherEmail,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6B7280))),
                                    ])),
                              ]),
                            ),

                          // Grade cards grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _assignedGrades.length,
                            itemBuilder: (_, i) =>
                                _buildGradeCard(_assignedGrades[i]),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorWidget() => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 60, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            const Text('Error Loading Classes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAssignedGrades,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white),
              child: const Text('Try Again'),
            ),
          ]),
        ),
      );

  Widget _buildNoGradesWidget() => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.school_outlined,
                size: 80, color: Color(0xFF0EA5E9)),
            const SizedBox(height: 24),
            const Text('No Grades Assigned Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Contact admin to assign grades to you',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAssignedGrades,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white),
            ),
          ]),
        ),
      );

  Widget _buildGradeCard(Map<String, dynamic> gradeData) {
    final grade = gradeData['grade'] as String;
    final gradeNumber = gradeData['gradeNumber'] as int;
    final color = gradeData['color'] as Color;
    final icon = gradeData['icon'] as String;
    final description = gradeData['description'] as String;
    final firestoreId = gradeData['firestoreId'] as String;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherGradeTopicsPage(
            grade: grade,
            gradeNumber: gradeNumber,
            firestoreGradeId: firestoreId,
            color: color,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16)),
            child:
                Center(child: Text(icon, style: const TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 12),
          Text(grade,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('View Content',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937))),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEACHER GRADE TOPICS PAGE
//  Firestore path: grades/{firestoreGradeId}/topics
// ─────────────────────────────────────────────────────────────────────────────
class TeacherGradeTopicsPage extends StatefulWidget {
  final String grade;
  final int gradeNumber;
  final String firestoreGradeId;
  final Color color;

  const TeacherGradeTopicsPage({
    super.key,
    this.grade = 'Grade 5',
    this.gradeNumber = 5,
    this.firestoreGradeId = 'Grade 5',
    this.color = const Color(0xFF3B82F6),
  });

  @override
  State<TeacherGradeTopicsPage> createState() => _TeacherGradeTopicsPageState();
}

class _TeacherGradeTopicsPageState extends State<TeacherGradeTopicsPage> {
  /// grades/{firestoreGradeId}/topics
  CollectionReference get _topicsRef => FirebaseFirestore.instance
      .collection('grades')
      .doc(widget.firestoreGradeId)
      .collection('topics');

  // ── Add topic ──────────────────────────────────────────────────────────────
  void _showAddTopicDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child:
                Icon(Icons.add_circle_outline, color: widget.color, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Add New Topic',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Topic Name',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., What is matter?',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.color, width: 2)),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    _addTopic(v.trim());
                    Navigator.pop(context);
                  }
                },
              ),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final n = ctrl.text.trim();
              if (n.isNotEmpty) {
                _addTopic(n);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: widget.color, foregroundColor: Colors.white),
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTopic(String name) async {
    final docId = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim()
        .replaceAll(' ', '_');
    try {
      await _topicsRef.doc(docId).set({
        'name': name,
        'description': '',
        'examples': [],
        'keyPoints': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Topic "$name" added!'),
            backgroundColor: const Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626)));
      }
    }
  }

  // ── Delete topic ───────────────────────────────────────────────────────────
  void _showDeleteConfirmation(String docId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _topicsRef.doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('"$name" deleted!'),
                      backgroundColor: const Color(0xFF10B981)));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: const Color(0xFFDC2626)));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Edit topic name ────────────────────────────────────────────────────────
  void _showEditTopicDialog(String docId, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Topic'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Enter topic name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final n = ctrl.text.trim();
              if (n.isNotEmpty) {
                try {
                  await _topicsRef.doc(docId).update({
                    'name': n,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Topic updated!'),
                        backgroundColor: Color(0xFF10B981)));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: const Color(0xFFDC2626)));
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: widget.color, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.grade} Topics',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Sub-header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('🔬', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Matter Content',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937))),
                    const SizedBox(height: 4),
                    Text('Manage ${widget.grade} Topics',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF6B7280))),
                  ])),
              GestureDetector(
                onTap: _showAddTopicDialog,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(Icons.add, color: widget.color, size: 24),
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Real-time topic list from grades/{grade}/topics
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _topicsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: widget.color));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No topics yet'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddTopicDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Topic'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: widget.color,
                                foregroundColor: Colors.white),
                          ),
                        ]),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] as String? ?? 'Unnamed Topic';
                    final docId = doc.id;

                    return _TopicCard(
                      index: index,
                      topicName: name,
                      color: widget.color,
                      // ── Tap navigates to TopicContentEditorPage (for teachers) ──
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopicContentEditorPage(
                            firestoreGradeId: widget.firestoreGradeId,
                            topicDocId: docId,
                            topicName: name,
                            grade: widget.grade,
                            topicNumber: index + 1,
                            color: widget.color,
                          ),
                        ),
                      ),
                      onEdit: () => _showEditTopicDialog(docId, name),
                      onDelete: () => _showDeleteConfirmation(docId, name),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTopicDialog,
        backgroundColor: widget.color,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOPIC CARD WIDGET
// ─────────────────────────────────────────────
class _TopicCard extends StatelessWidget {
  final int index;
  final String topicName;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopicCard({
    required this.index,
    required this.topicName,
    required this.color,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          // Numbered circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18))),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Text(topicName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937)))),
          // Edit / Delete menu
          PopupMenuButton<String>(
            icon:
                const Icon(Icons.more_vert, color: Color(0xFF9CA3AF), size: 20),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, color: Color(0xFF8B5CF6), size: 18),
                  SizedBox(width: 12),
                  Text('Edit Topic'),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, color: Color(0xFFDC2626), size: 18),
                  SizedBox(width: 12),
                  Text('Delete'),
                ]),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
