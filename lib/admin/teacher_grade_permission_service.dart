import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service to manage and check teacher grade permissions
///
/// Features:
/// - Real-time permission checking with streams
/// - Caching to reduce Firebase reads
/// - Support for legacy permission fields
/// - Admin bypass logic
class TeacherGradePermissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for assigned grades to reduce Firebase reads
  final Map<String, List<String>> _assignedGradesCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheValidDuration = const Duration(minutes: 5);

  /// Check if a teacher has access to a specific grade
  ///
  /// Checks multiple sources for backward compatibility:
  /// 1. assignedGrades array (preferred)
  /// 2. individual gradeXAccess boolean fields (legacy)
  /// 3. grade5Access boolean field (legacy)
  ///
  /// Usage:
  /// ```dart
  /// final hasAccess = await TeacherGradePermissionService().hasGradeAccess(
  ///   teacherId: currentTeacherId,
  ///   grade: 'Grade 6',
  /// );
  ///
  /// if (!hasAccess) {
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text('You do not have access to this grade')),
  ///   );
  ///   return;
  /// }
  /// ```
  Future<bool> hasGradeAccess({
    required String teacherId,
    required String grade,
    bool useCache = true,
  }) async {
    try {
      // Check if user is admin first (admins have access to everything)
      if (await isAdmin(teacherId)) {
        debugPrint('✅ User is admin - granting access to $grade');
        return true;
      }

      // Try to get from cache first
      if (useCache && _isCacheValid(teacherId)) {
        final cachedGrades = _assignedGradesCache[teacherId] ?? [];
        debugPrint('📦 Using cached grades for $teacherId: $cachedGrades');
        return cachedGrades.contains(grade);
      }

      // Fetch from Firebase
      final doc = await _firestore.collection('users').doc(teacherId).get();

      if (!doc.exists) {
        debugPrint('❌ Teacher document not found: $teacherId');
        return false;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('❌ Teacher document has no data: $teacherId');
        return false;
      }

      // Get all assigned grades using multiple methods
      final assignedGrades = _extractAssignedGrades(data);

      // Update cache
      _assignedGradesCache[teacherId] = assignedGrades;
      _cacheTimestamps[teacherId] = DateTime.now();

      debugPrint('✅ Fetched grades for $teacherId: $assignedGrades');
      return assignedGrades.contains(grade);
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking grade access: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get list of grades assigned to a teacher
  ///
  /// Returns a list of grade strings like ['Grade 5', 'Grade 6', 'Grade 8']
  /// Checks multiple sources for backward compatibility
  Future<List<String>> getAssignedGrades(
    String teacherId, {
    bool useCache = true,
  }) async {
    try {
      // Check if user is admin first (admins get all grades)
      if (await isAdmin(teacherId)) {
        debugPrint('✅ User is admin - returning all grades');
        return _getAllGrades();
      }

      // Try to get from cache first
      if (useCache && _isCacheValid(teacherId)) {
        final cachedGrades = _assignedGradesCache[teacherId] ?? [];
        debugPrint('📦 Using cached grades for $teacherId: $cachedGrades');
        return cachedGrades;
      }

      // Fetch from Firebase
      final doc = await _firestore.collection('users').doc(teacherId).get();

      if (!doc.exists) {
        debugPrint('❌ Teacher document not found: $teacherId');
        return [];
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('❌ Teacher document has no data: $teacherId');
        return [];
      }

      // Extract assigned grades from multiple sources
      final assignedGrades = _extractAssignedGrades(data);

      // Update cache
      _assignedGradesCache[teacherId] = assignedGrades;
      _cacheTimestamps[teacherId] = DateTime.now();

      debugPrint(
          '✅ Fetched ${assignedGrades.length} grades for $teacherId: $assignedGrades');
      return assignedGrades;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting assigned grades: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Stream of assigned grades for real-time updates
  ///
  /// Usage:
  /// ```dart
  /// StreamBuilder<List<String>>(
  ///   stream: TeacherGradePermissionService().getAssignedGradesStream(teacherId),
  ///   builder: (context, snapshot) {
  ///     if (!snapshot.hasData) return CircularProgressIndicator();
  ///     final grades = snapshot.data!;
  ///     // Use grades...
  ///   },
  /// )
  /// ```
  Stream<List<String>> getAssignedGradesStream(String teacherId) {
    return _firestore
        .collection('users')
        .doc(teacherId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) {
        debugPrint('❌ Teacher document not found: $teacherId');
        return <String>[];
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('❌ Teacher document has no data: $teacherId');
        return <String>[];
      }

      // Check if admin
      if (data['role'] == 'admin') {
        debugPrint('✅ User is admin - returning all grades');
        return _getAllGrades();
      }

      // Extract assigned grades
      final assignedGrades = _extractAssignedGrades(data);

      // Update cache
      _assignedGradesCache[teacherId] = assignedGrades;
      _cacheTimestamps[teacherId] = DateTime.now();

      debugPrint(
          '📡 Stream updated - ${assignedGrades.length} grades for $teacherId');
      return assignedGrades;
    });
  }

  /// Check if teacher is admin (admins have access to all grades)
  Future<bool> isAdmin(String teacherId) async {
    try {
      final doc = await _firestore.collection('users').doc(teacherId).get();

      if (!doc.exists) {
        debugPrint('❌ User document not found: $teacherId');
        return false;
      }

      final data = doc.data();
      final role = data?['role'];
      final isAdminUser = role == 'admin';

      debugPrint(
          '🔍 Checking admin status for $teacherId: $isAdminUser (role: $role)');
      return isAdminUser;
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  /// Filter grades list based on teacher permissions
  /// Returns only the grades the teacher has access to
  ///
  /// Usage in MatterTopicsPage:
  /// ```dart
  /// final filteredGrades = await TeacherGradePermissionService()
  ///     .filterGradesForTeacher(
  ///   teacherId: currentTeacherId,
  ///   allGrades: ['Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10'],
  /// );
  /// ```
  Future<List<String>> filterGradesForTeacher({
    required String teacherId,
    required List<String> allGrades,
    bool useCache = true,
  }) async {
    try {
      // Check if admin - admins see all grades
      if (await isAdmin(teacherId)) {
        debugPrint('✅ Admin user - showing all ${allGrades.length} grades');
        return allGrades;
      }

      // Get teacher's assigned grades
      final assignedGrades =
          await getAssignedGrades(teacherId, useCache: useCache);

      // Filter to only show assigned grades
      final filteredGrades =
          allGrades.where((grade) => assignedGrades.contains(grade)).toList();

      debugPrint(
          '🔍 Filtered ${allGrades.length} grades to ${filteredGrades.length} for $teacherId');
      debugPrint('   Available: $filteredGrades');

      return filteredGrades;
    } catch (e, stackTrace) {
      debugPrint('❌ Error filtering grades: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Validate if teacher can perform an action on a grade
  /// Shows appropriate error message if access denied
  ///
  /// Returns true if access granted, false otherwise
  ///
  /// Usage:
  /// ```dart
  /// final canAccess = await TeacherGradePermissionService().validateGradeAccess(
  ///   teacherId: currentTeacherId,
  ///   grade: 'Grade 6',
  ///   onAccessDenied: (message) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(content: Text(message)),
  ///     );
  ///   },
  /// );
  ///
  /// if (!canAccess) return;
  /// // Proceed with action...
  /// ```
  Future<bool> validateGradeAccess({
    required String teacherId,
    required String grade,
    required Function(String) onAccessDenied,
  }) async {
    final hasAccess = await hasGradeAccess(
      teacherId: teacherId,
      grade: grade,
    );

    if (!hasAccess) {
      final message = 'You do not have permission to access $grade';
      debugPrint('⛔ Access denied: $message');
      onAccessDenied(message);
      return false;
    }

    debugPrint('✅ Access granted to $grade for teacher $teacherId');
    return true;
  }

  /// Show a permission error dialog
  ///
  /// Usage:
  /// ```dart
  /// await TeacherGradePermissionService().showPermissionError(
  ///   context: context,
  ///   grade: 'Grade 6',
  /// );
  /// ```
  Future<void> showPermissionError({
    required BuildContext context,
    required String grade,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You do not have permission to access $grade.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFBBF24)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please contact your administrator to request access.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Clear cache for a specific teacher or all teachers
  void clearCache([String? teacherId]) {
    if (teacherId != null) {
      _assignedGradesCache.remove(teacherId);
      _cacheTimestamps.remove(teacherId);
      debugPrint('🗑️ Cleared cache for teacher: $teacherId');
    } else {
      _assignedGradesCache.clear();
      _cacheTimestamps.clear();
      debugPrint('🗑️ Cleared all permission cache');
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  /// Check if cache is still valid for a teacher
  bool _isCacheValid(String teacherId) {
    final timestamp = _cacheTimestamps[teacherId];
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age < _cacheValidDuration;
  }

  /// Extract assigned grades from user data with multiple fallback methods
  List<String> _extractAssignedGrades(Map<String, dynamic> data) {
    Set<String> assignedGradesSet = {};

    // Method 1: Check 'assignedGrades' array field (PREFERRED)
    if (data.containsKey('assignedGrades')) {
      final gradesData = data['assignedGrades'];
      if (gradesData is List) {
        for (var grade in gradesData) {
          if (grade is String && grade.isNotEmpty) {
            assignedGradesSet.add(grade);
          }
        }
        debugPrint('  ✓ Found assignedGrades array: $assignedGradesSet');
      }
    }

    // Method 2: Check 'grade5Access' boolean field (legacy support)
    if (data.containsKey('grade5Access') && data['grade5Access'] == true) {
      assignedGradesSet.add('Grade 5');
      debugPrint('  ✓ Found grade5Access = true');
    }

    // Method 3: Check individual grade access fields (gradeXAccess)
    for (int i = 5; i <= 10; i++) {
      final gradeKey = 'grade${i}Access';
      if (data.containsKey(gradeKey) && data[gradeKey] == true) {
        assignedGradesSet.add('Grade $i');
        debugPrint('  ✓ Found $gradeKey = true');
      }
    }

    // Convert to sorted list
    final gradesList = assignedGradesSet.toList();
    gradesList.sort((a, b) {
      final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });

    return gradesList;
  }

  /// Get all available grades (for admin users)
  List<String> _getAllGrades() {
    return [
      'Grade 5',
      'Grade 6',
      'Grade 7',
      'Grade 8',
      'Grade 9',
      'Grade 10',
    ];
  }
}
