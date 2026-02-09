import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// FIREBASE DIAGNOSTIC PAGE
/// Use this page to check what's in your Firebase and why classes aren't showing
class FirebaseDiagnosticPage extends StatefulWidget {
  const FirebaseDiagnosticPage({super.key});

  @override
  State<FirebaseDiagnosticPage> createState() => _FirebaseDiagnosticPageState();
}

class _FirebaseDiagnosticPageState extends State<FirebaseDiagnosticPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _teacherUid = '';
  String _teacherName = '';
  List<String> _assignedGrades = [];
  List<Map<String, dynamic>> _allClasses = [];
  List<Map<String, dynamic>> _myClasses = [];
  bool _isLoading = true;
  String _diagnosis = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _diagnosis = '';
    });

    StringBuffer diagnosis = StringBuffer();
    diagnosis.writeln('🔍 FIREBASE DIAGNOSTIC REPORT\n');
    diagnosis.writeln('=' * 50);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        diagnosis.writeln('❌ ERROR: No user logged in!');
        setState(() {
          _diagnosis = diagnosis.toString();
          _isLoading = false;
        });
        return;
      }

      _teacherUid = user.uid;
      diagnosis.writeln('\n✅ LOGGED IN USER:');
      diagnosis.writeln('   User ID: $_teacherUid');
      diagnosis.writeln('   Email: ${user.email}');

      // Check user document
      diagnosis.writeln('\n📋 CHECKING USER DOCUMENT...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        diagnosis.writeln('   ❌ User document does NOT exist in Firestore!');
        diagnosis.writeln('   Path: users/${user.uid}');
      } else {
        diagnosis.writeln('   ✅ User document exists');
        final userData = userDoc.data()!;
        _teacherName = userData['name'] ?? 'Unknown';
        _assignedGrades = List<String>.from(userData['assignedGrades'] ?? []);

        diagnosis.writeln('   Name: $_teacherName');
        diagnosis.writeln('   Role: ${userData['role']}');
        diagnosis.writeln('   Assigned Grades: $_assignedGrades');
      }

      // Check ALL classes in Firebase
      diagnosis.writeln('\n📚 CHECKING ALL CLASSES IN FIREBASE...');
      final allClassesSnapshot = await _firestore.collection('classes').get();

      diagnosis.writeln(
          '   Total classes in database: ${allClassesSnapshot.docs.length}');

      if (allClassesSnapshot.docs.isEmpty) {
        diagnosis.writeln('   ❌ NO CLASSES EXIST IN FIREBASE!');
        diagnosis.writeln('   You need to create classes first.');
      } else {
        diagnosis.writeln('\n   📋 ALL CLASSES IN DATABASE:');

        for (var doc in allClassesSnapshot.docs) {
          final data = doc.data();
          _allClasses.add({
            'id': doc.id,
            'name': data['name'] ?? 'No name',
            'grade': data['grade'] ?? 'No grade',
            'section': data['section'] ?? 'No section',
            'teacherId': data['teacherId'] ?? 'NO TEACHER ID',
            'topic': data['topic'] ?? 'No topic',
          });

          diagnosis.writeln('\n   Class ID: ${doc.id}');
          diagnosis.writeln('      Name: ${data['name']}');
          diagnosis.writeln('      Grade: ${data['grade']}');
          diagnosis.writeln('      Section: ${data['section']}');
          diagnosis.writeln(
              '      Teacher ID: ${data['teacherId'] ?? '❌ MISSING!'}');
          diagnosis.writeln('      Topic: ${data['topic']}');

          // Check if this class is assigned to current teacher
          if (data['teacherId'] == user.uid) {
            diagnosis.writeln('      ✅ ASSIGNED TO YOU!');
          } else {
            diagnosis.writeln('      ❌ NOT assigned to you');
          }
        }
      }

      // Check classes assigned to this teacher
      diagnosis.writeln('\n🎯 CHECKING CLASSES ASSIGNED TO YOU...');
      final myClassesSnapshot = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: user.uid)
          .get();

      diagnosis.writeln(
          '   Classes assigned to you: ${myClassesSnapshot.docs.length}');

      if (myClassesSnapshot.docs.isEmpty) {
        diagnosis.writeln('\n   ❌ NO CLASSES ASSIGNED TO YOUR USER ID!');
        diagnosis.writeln('\n   🔧 TO FIX THIS:');
        diagnosis.writeln('   1. Go to Firebase Console → Firestore');
        diagnosis.writeln('   2. Open "classes" collection');
        diagnosis.writeln('   3. For each class you want to assign:');
        diagnosis.writeln('      - Add field: teacherId');
        diagnosis.writeln('      - Type: string');
        diagnosis.writeln('      - Value: $_teacherUid');
        diagnosis.writeln('   4. Save and refresh this page');
      } else {
        diagnosis.writeln('\n   ✅ YOU HAVE CLASSES ASSIGNED!');
        for (var doc in myClassesSnapshot.docs) {
          final data = doc.data();
          _myClasses.add({
            'id': doc.id,
            'name': data['name'] ?? 'No name',
            'grade': data['grade'] ?? 'No grade',
            'section': data['section'] ?? 'No section',
            'topic': data['topic'] ?? 'No topic',
          });

          // Count students
          final studentsSnapshot = await _firestore
              .collection('classes')
              .doc(doc.id)
              .collection('students')
              .get();

          diagnosis.writeln('\n      📘 ${data['name']}');
          diagnosis.writeln('         Grade: ${data['grade']}');
          diagnosis
              .writeln('         Students: ${studentsSnapshot.docs.length}');
        }
      }

      diagnosis.writeln('\n' + '=' * 50);
      diagnosis.writeln('\n📊 SUMMARY:');
      diagnosis.writeln('   Your User ID: $_teacherUid');
      diagnosis.writeln('   Total classes in Firebase: ${_allClasses.length}');
      diagnosis.writeln('   Classes assigned to you: ${_myClasses.length}');

      if (_myClasses.isEmpty && _allClasses.isNotEmpty) {
        diagnosis.writeln('\n⚠️ PROBLEM FOUND:');
        diagnosis.writeln('   Classes exist but none are assigned to you!');
        diagnosis
            .writeln('   Copy your User ID and add it to class documents.');
      } else if (_myClasses.isEmpty && _allClasses.isEmpty) {
        diagnosis.writeln('\n⚠️ PROBLEM FOUND:');
        diagnosis.writeln('   No classes exist in Firebase yet.');
        diagnosis.writeln('   Create classes first, then assign them to you.');
      } else {
        diagnosis.writeln('\n✅ EVERYTHING LOOKS GOOD!');
        diagnosis.writeln('   Your classes should appear on the home page.');
      }
    } catch (e) {
      diagnosis.writeln('\n❌ ERROR: $e');
    }

    setState(() {
      _diagnosis = diagnosis.toString();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0EA5E9),
        title: const Text(
          'Firebase Diagnostic',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Running diagnostics...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
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
                                color: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Color(0xFF0EA5E9),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Quick Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Your User ID', _teacherUid,
                            canCopy: true),
                        _buildInfoRow('Your Name', _teacherName),
                        _buildInfoRow(
                            'Classes in Firebase', '${_allClasses.length}'),
                        _buildInfoRow('Your Classes', '${_myClasses.length}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // All Classes Section
                  if (_allClasses.isNotEmpty) ...[
                    const Text(
                      'All Classes in Firebase',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._allClasses
                        .map((classData) => _buildClassCard(classData, false)),
                  ],

                  const SizedBox(height: 20),

                  // My Classes Section
                  if (_myClasses.isNotEmpty) ...[
                    const Text(
                      'Your Assigned Classes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._myClasses
                        .map((classData) => _buildClassCard(classData, true)),
                  ],

                  const SizedBox(height: 20),

                  // Full Diagnosis Report
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.terminal,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Full Diagnostic Report',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy,
                                  color: Colors.white, size: 18),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: _diagnosis));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Report copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _diagnosis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Courier',
                              color: Color(0xFF10B981),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (canCopy)
                  IconButton(
                    icon: const Icon(Icons.copy,
                        size: 16, color: Color(0xFF0EA5E9)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData, bool isAssigned) {
    final isMatchingTeacher = classData['teacherId'] == _teacherUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMatchingTeacher
              ? const Color(0xFF10B981)
              : const Color(0xFFE5E7EB),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isMatchingTeacher
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isMatchingTeacher ? 'YOUR CLASS' : 'NOT ASSIGNED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMatchingTeacher
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            classData['name'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag(
                  'Grade: ${classData['grade']}', const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _buildTag(
                  'Section: ${classData['section']}', const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Topic: ${classData['topic']}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                'Teacher ID: ${classData['teacherId']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
