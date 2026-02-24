import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
//  Shared helper: safely parse Realtime DB value
//  (List OR Map<int-key,value>) into a clean list
// ─────────────────────────────────────────────
List<Map<String, String>> _parseTopics(dynamic raw) {
  if (raw == null) return [];
  try {
    if (raw is List) {
      return raw
          .where((e) => e != null)
          .map((e) => Map<String, String>.from(
                (e as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
              ))
          .toList();
    } else if (raw is Map) {
      final entries = raw.entries.toList()
        ..sort((a, b) {
          final ai = int.tryParse(a.key.toString()) ?? 0;
          final bi = int.tryParse(b.key.toString()) ?? 0;
          return ai.compareTo(bi);
        });
      return entries
          .where((e) => e.value != null)
          .map((e) => Map<String, String>.from(
                (e.value as Map)
                    .map((k, v) => MapEntry(k.toString(), v.toString())),
              ))
          .toList();
    }
  } catch (e) {
    debugPrint('_parseTopics error: $e');
  }
  return [];
}

// ─────────────────────────────────────────────
//  ADMIN ContentManagementPage
//  (unchanged – still uses Realtime Database)
// ─────────────────────────────────────────────
class ContentManagementPage extends StatefulWidget {
  final bool isTab;
  const ContentManagementPage({super.key, this.isTab = false});

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  List<Map<String, String>> _subtopics = [];
  bool _isLoading = true;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final snapshot = await _database.child('grade5_topics').get();
      if (snapshot.exists && snapshot.value != null) {
        if (mounted) {
          setState(() {
            _subtopics = _parseTopics(snapshot.value);
            _isLoading = false;
          });
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final String? topicsJson = prefs.getString('grade5_topics');
        if (topicsJson != null) {
          final List<dynamic> decoded = json.decode(topicsJson);
          if (mounted) {
            setState(() {
              _subtopics =
                  decoded.map((e) => Map<String, String>.from(e)).toList();
            });
          }
        } else {
          _subtopics = [
            {'id': '1', 'name': 'What is Matter?'},
            {'id': '2', 'name': 'Properties of Matter'},
            {'id': '3', 'name': 'Molecules'},
            {'id': '4', 'name': 'State of Matter'},
          ];
        }
        await _saveTopics();
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading topics: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? topicsJson = prefs.getString('grade5_topics');
        if (topicsJson != null) {
          final List<dynamic> decoded = json.decode(topicsJson);
          if (mounted) {
            setState(() {
              _subtopics =
                  decoded.map((e) => Map<String, String>.from(e)).toList();
            });
          }
        }
      } catch (e2) {
        debugPrint('Error loading from local storage: $e2');
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTopics() async {
    try {
      await _database.child('grade5_topics').set(_subtopics);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('grade5_topics', json.encode(_subtopics));
    } catch (e) {
      debugPrint('Error saving topics: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('grade5_topics', json.encode(_subtopics));
      } catch (e2) {
        debugPrint('Error saving to local storage: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (widget.isTab) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
        );
      }
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
        ),
      );
    }

    Widget bodyContent = Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('🔬', style: TextStyle(fontSize: 40)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Matter Content',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          SizedBox(height: 4),
                          Text('Manage Grade 5 topics',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Grade 5 Content',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937))),
              const SizedBox(height: 4),
              const Text('View and manage Grade 5 Matter subtopics',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          Grade5TopicsPage(subtopics: _subtopics),
                    ),
                  );
                  await _loadTopics();
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                            child: Text('📘', style: TextStyle(fontSize: 36))),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Grade 5',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0EA5E9))),
                            const SizedBox(height: 6),
                            const Text('Matter fundamentals for Grade 5',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.book_outlined,
                                    size: 18, color: Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Text('${_subtopics.length} topics',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF0EA5E9),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios,
                            size: 18, color: Color(0xFF0EA5E9)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isTab) return bodyContent;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Content Management',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadTopics();
            },
          ),
        ],
      ),
      body: SafeArea(child: bodyContent),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEACHER version ── READ-ONLY
//
//  ✅ Reads from FIRESTORE collection "Matter_subtopics"
//     filtered by  grade == gradeNumber  (e.g. grade == 5)
//
//  Each Firestore document has:
//    - name      : String   e.g. "What is matter?"
//    - grade     : number   e.g. 5
//    - createdAt : Timestamp
// ─────────────────────────────────────────────────────────────────────────────
class TeacherContentManagementPage extends StatefulWidget {
  final String grade; // e.g. "Grade 5", "Grade 10"
  const TeacherContentManagementPage({super.key, required this.grade});

  @override
  State<TeacherContentManagementPage> createState() =>
      _TeacherContentManagementPageState();
}

class _TeacherContentManagementPageState
    extends State<TeacherContentManagementPage> {
  List<Map<String, dynamic>> _subtopics = [];
  bool _isLoading = true;
  String _errorInfo = '';

  /// "Grade 5" → 5,  "Grade 10" → 10
  int get _gradeNumber {
    final numStr = widget.grade.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numStr) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      debugPrint(
          '▶ TeacherContent: querying Matter_subtopics where grade==$_gradeNumber');

      final query = await FirebaseFirestore.instance
          .collection('Matter_subtopics')
          .where('grade', isEqualTo: _gradeNumber)
          .orderBy('createdAt')
          .get();

      debugPrint('▶ TeacherContent: got ${query.docs.length} docs');

      if (mounted) {
        setState(() {
          _subtopics =
              query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          _errorInfo = '';
        });
      }
    } catch (e, st) {
      debugPrint('▶ TeacherContent ERROR: $e\n$st');
      // Firestore requires a composite index for where+orderBy.
      // If that index is missing, fall back without ordering.
      try {
        final query = await FirebaseFirestore.instance
            .collection('Matter_subtopics')
            .where('grade', isEqualTo: _gradeNumber)
            .get();

        debugPrint(
            '▶ TeacherContent (no-order fallback): got ${query.docs.length} docs');

        if (mounted) {
          setState(() {
            _subtopics =
                query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
            _errorInfo = '';
          });
        }
      } catch (e2) {
        debugPrint('▶ TeacherContent fallback ERROR: $e2');
        if (mounted) setState(() => _errorInfo = 'Error: $e2');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.grade} Content',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTopics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ───────────────────────────────────────
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
                    child: const Text('🔬', style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Matter Content',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('View ${widget.grade} topics',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('${widget.grade} Content',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text('View ${widget.grade} Matter subtopics',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),

            // ── Topic list ──────────────────────────────────────────
            if (_subtopics.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 64, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 16),
                      const Text('No topics available yet.',
                          style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                      if (_errorInfo.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_errorInfo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subtopics.length,
                itemBuilder: (context, index) {
                  final topic = _subtopics[index];
                  final name = topic['name']?.toString() ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Color(0xFF0EA5E9), shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937)),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Grade5TopicsPage  (admin-only edit page)
// ─────────────────────────────────────────────
class Grade5TopicsPage extends StatefulWidget {
  final List<Map<String, String>> subtopics;
  const Grade5TopicsPage({super.key, required this.subtopics});

  @override
  State<Grade5TopicsPage> createState() => _Grade5TopicsPageState();
}

class _Grade5TopicsPageState extends State<Grade5TopicsPage> {
  late List<Map<String, String>> _topics;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _topics = List.from(widget.subtopics);
  }

  Future<void> _saveTopics() async {
    try {
      await _database.child('grade5_topics').set(_topics);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('grade5_topics', json.encode(_topics));
    } catch (e) {
      debugPrint('Error saving topics: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('grade5_topics', json.encode(_topics));
      } catch (e2) {
        debugPrint('Error saving to local storage: $e2');
      }
    }
  }

  void _showTopicOptions(Map<String, String> topic) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: Color(0xFF0EA5E9), shape: BoxShape.circle),
                    child: Center(
                        child: Text(topic['id']!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(topic['name']!,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937))),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  Future.delayed(const Duration(milliseconds: 100),
                      () => _editTopic(topic));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit,
                            color: Color(0xFF0EA5E9), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Edit',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937))),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  Future.delayed(const Duration(milliseconds: 100),
                      () => _deleteTopic(topic));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete,
                            color: Color(0xFFDC2626), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Delete',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTopic() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF0EA5E9), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Add New Topic'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Topic Name',
            hintText: 'Enter topic name',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF0EA5E9), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a topic name'),
                      backgroundColor: Colors.orange),
                );
                return;
              }
              final newId = (_topics.length + 1).toString();
              if (mounted) {
                setState(
                    () => _topics.add({'id': newId, 'name': controller.text}));
              }
              await _saveTopics();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                    content: Text('Topic added successfully'),
                    backgroundColor: Color(0xFF10B981)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  void _editTopic(Map<String, String> topic) {
    final TextEditingController controller =
        TextEditingController(text: topic['name']);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Color(0xFF0EA5E9), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Edit Topic Name', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Topic Name',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter new topic name',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF0EA5E9), width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                      content: Text('Topic name cannot be empty'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2)),
                );
                return;
              }
              final index = _topics.indexWhere((t) => t['id'] == topic['id']);
              if (index != -1 && mounted) {
                setState(() => _topics[index]['name'] = newName);
                await _saveTopics();
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                    content: Text('Updated to "$newName"'),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 2)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteTopic(Map<String, String> topic) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Delete Topic', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this topic?',
                style: TextStyle(fontSize: 15, color: Colors.grey[800])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        color: Color(0xFFDC2626), shape: BoxShape.circle),
                    child: Center(
                        child: Text(topic['id']!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(topic['name']!,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('This action cannot be undone.',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (mounted) {
                setState(
                    () => _topics.removeWhere((t) => t['id'] == topic['id']));
              }
              await _saveTopics();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                    content: Text('Deleted "${topic['name']}"'),
                    backgroundColor: const Color(0xFFDC2626),
                    duration: const Duration(seconds: 2)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF0EA5E9),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Grade 5 Topics',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('🔬', style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Matter Content',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937))),
                        SizedBox(height: 4),
                        Text('Manage Grade 5 topics',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add,
                          color: Color(0xFF0EA5E9), size: 28),
                      onPressed: _addTopic,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: _topics.isEmpty
                    ? const Center(
                        child: Text('No topics yet. Add your first topic!',
                            style: TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 16)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _topics.length,
                        itemBuilder: (context, index) {
                          final topic = _topics[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFF0EA5E9)
                                      .withValues(alpha: 0.3),
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF0EA5E9),
                                    shape: BoxShape.circle),
                                child: Center(
                                    child: Text(topic['id']!,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16))),
                              ),
                              title: Text(topic['name']!,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937))),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    color: Color(0xFF6B7280)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                onSelected: (value) {
                                  if (value == 'edit') _editTopic(topic);
                                  if (value == 'delete') _deleteTopic(topic);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit,
                                          color: Color(0xFF0EA5E9), size: 20),
                                      SizedBox(width: 12),
                                      Text('Edit'),
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      Icon(Icons.delete,
                                          color: Color(0xFFDC2626), size: 20),
                                      SizedBox(width: 12),
                                      Text('Delete'),
                                    ]),
                                  ),
                                ],
                              ),
                              onTap: () => _showTopicOptions(topic),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
