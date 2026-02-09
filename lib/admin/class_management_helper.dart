import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Helper class for managing classes in Firestore
class ClassManagementHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create sample classes for testing
  static Future<Map<String, dynamic>> createSampleClasses() async {
    try {
      final classes = [
        {
          'name': 'Class 5',
          'studentCount': 32,
          'currentTopic': 'Science - Matter',
          'grade': 5,
          'section': 'A',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Class 6',
          'studentCount': 28,
          'currentTopic': 'Physics - Energy',
          'grade': 6,
          'section': 'A',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Class 7',
          'studentCount': 30,
          'currentTopic': 'Chemistry - Elements',
          'grade': 7,
          'section': 'A',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Class 8',
          'studentCount': 25,
          'currentTopic': 'Biology - Cells',
          'grade': 8,
          'section': 'A',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Class 9',
          'studentCount': 35,
          'currentTopic': 'Physics - Motion',
          'grade': 9,
          'section': 'A',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Class 10',
          'studentCount': 27,
          'currentTopic': 'Chemistry - Reactions',
          'grade': 10,
          'section': 'A',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      int created = 0;
      for (var classData in classes) {
        await _firestore.collection('classes').add(classData);
        created++;
        print('✅ Created class: ${classData['name']}');
      }

      return {
        'success': true,
        'created': created,
        'message': 'Successfully created $created sample classes',
      };
    } catch (e) {
      print('❌ Error creating sample classes: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Create a new class
  static Future<Map<String, dynamic>> createClass({
    required String name,
    required int grade,
    required String section,
    String? currentTopic,
    int studentCount = 0,
    String? teacherId,
    String? teacherName,
  }) async {
    try {
      final classData = {
        'name': name,
        'grade': grade,
        'section': section,
        'studentCount': studentCount,
        'currentTopic': currentTopic,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (teacherId != null) {
        classData['teacherId'] = teacherId;
        classData['teacherName'] = teacherName;
      }

      final docRef = await _firestore.collection('classes').add(classData);

      return {
        'success': true,
        'classId': docRef.id,
        'message': 'Class created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get all classes
  static Future<List<Map<String, dynamic>>> getAllClasses() async {
    try {
      final snapshot = await _firestore.collection('classes').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting classes: $e');
      return [];
    }
  }

  /// Get classes assigned to a specific teacher
  static Future<List<Map<String, dynamic>>> getTeacherClasses(
      String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting teacher classes: $e');
      return [];
    }
  }

  /// Delete all classes (for testing/cleanup)
  static Future<Map<String, dynamic>> deleteAllClasses() async {
    try {
      final snapshot = await _firestore.collection('classes').get();

      int deleted = 0;
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        deleted++;
      }

      return {
        'success': true,
        'deleted': deleted,
        'message': 'Deleted $deleted classes',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Update class information
  static Future<Map<String, dynamic>> updateClass({
    required String classId,
    String? name,
    int? grade,
    String? section,
    int? studentCount,
    String? currentTopic,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (grade != null) updates['grade'] = grade;
      if (section != null) updates['section'] = section;
      if (studentCount != null) updates['studentCount'] = studentCount;
      if (currentTopic != null) updates['currentTopic'] = currentTopic;

      await _firestore.collection('classes').doc(classId).update(updates);

      return {
        'success': true,
        'message': 'Class updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if classes collection exists and has data
  static Future<Map<String, dynamic>> checkClassesStatus() async {
    try {
      final snapshot = await _firestore.collection('classes').limit(1).get();

      return {
        'exists': snapshot.docs.isNotEmpty,
        'count': snapshot.docs.length,
      };
    } catch (e) {
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }
}

/// UI Widget for class management in admin panel
class ClassManagementWidget extends StatefulWidget {
  const ClassManagementWidget({Key? key}) : super(key: key);

  @override
  State<ClassManagementWidget> createState() => _ClassManagementWidgetState();
}

class _ClassManagementWidgetState extends State<ClassManagementWidget> {
  bool _isLoading = false;
  String? _result;

  Future<void> _createSampleClasses() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await ClassManagementHelper.createSampleClasses();

    setState(() {
      _isLoading = false;
      _result = result['success']
          ? '✅ ${result['message']}'
          : '❌ Error: ${result['error']}';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success']
              ? result['message']
              : 'Error: ${result['error']}'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllClasses() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete ALL classes? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await ClassManagementHelper.deleteAllClasses();

    setState(() {
      _isLoading = false;
      _result = result['success']
          ? '✅ ${result['message']}'
          : '❌ Error: ${result['error']}';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success']
              ? result['message']
              : 'Error: ${result['error']}'),
          backgroundColor: result['success'] ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
    });

    final classes = await ClassManagementHelper.getAllClasses();

    setState(() {
      _isLoading = false;
      _result = 'Found ${classes.length} classes in database';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _checkStatus,
          icon: const Icon(Icons.info_outline),
          label: const Text('Check Classes Status'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _createSampleClasses,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.add_circle_outline),
          label: Text(_isLoading ? 'Creating...' : 'Create Sample Classes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _deleteAllClasses,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete All Classes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _result!,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
