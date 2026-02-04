import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Migration Helper for User Management System
/// This file contains utility functions to migrate existing users
/// and maintain the user database.

class UserMigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds 'isActive' field to all existing users
  /// This should be run ONCE after implementing the user management system
  static Future<Map<String, dynamic>> migrateUsersAddIsActive() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();

          // Only update if isActive doesn't exist
          if (!data.containsKey('isActive')) {
            await doc.reference.update({
              'isActive': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            successCount++;
            print('✅ Updated user: ${data['email']}');
          } else {
            print('⏭️ Skipped user (already has isActive): ${data['email']}');
          }
        } catch (e) {
          errorCount++;
          errors.add('${doc.id}: $e');
          print('❌ Error updating user ${doc.id}: $e');
        }
      }

      final result = {
        'success': true,
        'totalUsers': usersSnapshot.docs.length,
        'updated': successCount,
        'errors': errorCount,
        'errorDetails': errors,
      };

      print('🎉 Migration complete!');
      print('Total users: ${usersSnapshot.docs.length}');
      print('Updated: $successCount');
      print('Errors: $errorCount');

      return result;
    } catch (e) {
      print('❌ Migration failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Adds 'updatedAt' field to all users who don't have it
  static Future<Map<String, dynamic>> addUpdatedAtField() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      int successCount = 0;
      int errorCount = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();

          if (!data.containsKey('updatedAt')) {
            await doc.reference.update({
              'updatedAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
            });
            successCount++;
          }
        } catch (e) {
          errorCount++;
          print('❌ Error: $e');
        }
      }

      return {
        'success': true,
        'updated': successCount,
        'errors': errorCount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Fixes role inconsistencies (ensures lowercase)
  static Future<Map<String, dynamic>> normalizeUserRoles() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      int successCount = 0;
      int errorCount = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final role = data['role'] as String?;

          if (role != null && role != role.toLowerCase()) {
            await doc.reference.update({
              'role': role.toLowerCase(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            successCount++;
            print('✅ Normalized role for: ${data['email']}');
          }
        } catch (e) {
          errorCount++;
          print('❌ Error: $e');
        }
      }

      return {
        'success': true,
        'updated': successCount,
        'errors': errorCount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Generates unique IDs for users who don't have them
  static Future<Map<String, dynamic>> generateMissingUniqueIds() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      int successCount = 0;
      int errorCount = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final role = data['role'] as String?;

          if (!data.containsKey('uniqueId') && !data.containsKey('studentId')) {
            String uniqueId;
            switch (role?.toLowerCase()) {
              case 'admin':
                uniqueId = 'ADM-${DateTime.now().millisecondsSinceEpoch}';
                break;
              case 'teacher':
                uniqueId = 'TCH-${DateTime.now().millisecondsSinceEpoch}';
                break;
              default:
                uniqueId = 'STU-${DateTime.now().millisecondsSinceEpoch}';
            }

            await doc.reference.update({
              'uniqueId': uniqueId,
              if (role == 'student') 'studentId': uniqueId,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            successCount++;
            print('✅ Generated ID for: ${data['email']}');

            // Small delay to ensure unique timestamps
            await Future.delayed(const Duration(milliseconds: 10));
          }
        } catch (e) {
          errorCount++;
          print('❌ Error: $e');
        }
      }

      return {
        'success': true,
        'updated': successCount,
        'errors': errorCount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Complete migration: runs all migration functions
  static Future<Map<String, dynamic>> runCompleteMigration() async {
    print('🚀 Starting complete user migration...');

    final results = <String, dynamic>{};

    // 1. Add isActive field
    print('\n1️⃣ Adding isActive field...');
    results['isActive'] = await migrateUsersAddIsActive();

    // 2. Add updatedAt field
    print('\n2️⃣ Adding updatedAt field...');
    results['updatedAt'] = await addUpdatedAtField();

    // 3. Normalize roles
    print('\n3️⃣ Normalizing roles...');
    results['roles'] = await normalizeUserRoles();

    // 4. Generate unique IDs
    print('\n4️⃣ Generating unique IDs...');
    results['uniqueIds'] = await generateMissingUniqueIds();

    print('\n✅ Complete migration finished!');
    return results;
  }

  /// Get migration statistics
  static Future<Map<String, dynamic>> getMigrationStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      int hasIsActive = 0;
      int hasUpdatedAt = 0;
      int hasUniqueId = 0;
      int hasStudentId = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('isActive')) hasIsActive++;
        if (data.containsKey('updatedAt')) hasUpdatedAt++;
        if (data.containsKey('uniqueId')) hasUniqueId++;
        if (data.containsKey('studentId')) hasStudentId++;
      }

      return {
        'totalUsers': usersSnapshot.docs.length,
        'hasIsActive': hasIsActive,
        'hasUpdatedAt': hasUpdatedAt,
        'hasUniqueId': hasUniqueId,
        'hasStudentId': hasStudentId,
        'needsMigration': usersSnapshot.docs.length > hasIsActive,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

/// UI Widget to run migrations from admin panel
class MigrationButton extends StatefulWidget {
  const MigrationButton({Key? key}) : super(key: key);

  @override
  State<MigrationButton> createState() => _MigrationButtonState();
}

class _MigrationButtonState extends State<MigrationButton> {
  bool _isLoading = false;
  String? _result;

  Future<void> _runMigration() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await UserMigrationHelper.runCompleteMigration();

      setState(() {
        _result = 'Migration completed!\n'
            'isActive: ${result['isActive']['updated']} users updated\n'
            'updatedAt: ${result['updatedAt']['updated']} users updated\n'
            'roles: ${result['roles']['updated']} users updated\n'
            'uniqueIds: ${result['uniqueIds']['updated']} users updated';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Migration completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _result = 'Migration failed: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkStats() async {
    setState(() {
      _isLoading = true;
    });

    final stats = await UserMigrationHelper.getMigrationStats();

    setState(() {
      _result = 'Migration Statistics:\n'
          'Total Users: ${stats['totalUsers']}\n'
          'Has isActive: ${stats['hasIsActive']}\n'
          'Has updatedAt: ${stats['hasUpdatedAt']}\n'
          'Has uniqueId: ${stats['hasUniqueId']}\n'
          'Has studentId: ${stats['hasStudentId']}\n\n'
          '${stats['needsMigration'] ? '⚠️ Migration needed!' : '✅ All users migrated!'}';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _checkStats,
          icon: const Icon(Icons.analytics),
          label: const Text('Check Migration Status'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runMigration,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.update),
          label: Text(_isLoading ? 'Running...' : 'Run Complete Migration'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFBBF24),
            foregroundColor: const Color(0xFF1F2937),
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
