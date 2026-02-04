import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'activity_system.dart';
import 'user_management_page.dart';
import 'user_migration_helper.dart';

/// Developer Tools & Settings Page
/// This page provides admin tools including:
/// - Database migration utilities
/// - User management access
/// - System diagnostics
/// - App settings

class DeveloperToolsPage extends StatefulWidget {
  const DeveloperToolsPage({Key? key}) : super(key: key);

  @override
  State<DeveloperToolsPage> createState() => _DeveloperToolsPageState();
}

class _DeveloperToolsPageState extends State<DeveloperToolsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migration state
  bool _isMigrationRunning = false;
  String? _migrationResult;

  // Stats state
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    final stats = await UserMigrationHelper.getMigrationStats();

    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  Future<void> _runMigration() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Run Migration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will update all users in your database with:',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '• isActive field\n• updatedAt field\n• Normalized roles\n• Unique IDs',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This is safe to run multiple times.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Run Migration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isMigrationRunning = true;
      _migrationResult = null;
    });

    try {
      final result = await UserMigrationHelper.runCompleteMigration();

      setState(() {
        _migrationResult = 'Migration completed successfully!\n\n'
            '✅ isActive: ${result['isActive']['updated']} users updated\n'
            '✅ updatedAt: ${result['updatedAt']['updated']} users updated\n'
            '✅ roles: ${result['roles']['updated']} roles normalized\n'
            '✅ uniqueIds: ${result['uniqueIds']['updated']} IDs generated';
        _isMigrationRunning = false;
      });

      // Reload stats
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Migration completed successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _migrationResult = '❌ Migration failed: $e';
        _isMigrationRunning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Migration failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Developer Tools',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),

            // User Management Button
            _buildActionCard(
              icon: Icons.people_outline,
              iconColor: const Color(0xFF2196F3),
              iconBgColor: const Color(0xFFDBEAFE),
              title: 'User Management',
              subtitle: 'Manage all users, roles, and permissions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Migration Section
            const Text(
              'Database Migration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),

            // Migration Stats Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoadingStats
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    )
                  : _stats != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE9FE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_outlined,
                                    color: Color(0xFF8B5CF6),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Migration Status',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _loadStats,
                                  color: const Color(0xFF2196F3),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildStatRow(
                              'Total Users',
                              _stats!['totalUsers'].toString(),
                              Icons.people,
                              const Color(0xFF2196F3),
                            ),
                            const Divider(height: 24),
                            _buildStatRow(
                              'Has isActive field',
                              _stats!['hasIsActive'].toString(),
                              Icons.check_circle_outline,
                              const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 12),
                            _buildStatRow(
                              'Has updatedAt field',
                              _stats!['hasUpdatedAt'].toString(),
                              Icons.update,
                              const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 12),
                            _buildStatRow(
                              'Has uniqueId field',
                              _stats!['hasUniqueId'].toString(),
                              Icons.badge_outlined,
                              const Color(0xFF10B981),
                            ),
                            const Divider(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _stats!['needsMigration']
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _stats!['needsMigration']
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle,
                                    color: _stats!['needsMigration']
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _stats!['needsMigration']
                                          ? 'Migration needed'
                                          : 'All users migrated',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _stats!['needsMigration']
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Text('Failed to load stats'),
                        ),
            ),
            const SizedBox(height: 20),

            // Migration Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isMigrationRunning ? null : _runMigration,
                icon: _isMigrationRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 24),
                label: Text(
                  _isMigrationRunning
                      ? 'Running Migration...'
                      : 'Run Migration',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF1F2937),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
            ),

            // Migration Result
            if (_migrationResult != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _migrationResult!.contains('failed')
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _migrationResult!.contains('failed')
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF10B981),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _migrationResult!.contains('failed')
                              ? Icons.error_outline
                              : Icons.check_circle,
                          color: _migrationResult!.contains('failed')
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _migrationResult!.contains('failed')
                              ? 'Migration Failed'
                              : 'Migration Complete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _migrationResult!.contains('failed')
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _migrationResult!,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: _migrationResult!.contains('failed')
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF065F46),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // 🎯 REPLACE OLD RECENT ACTIVITY WITH THIS:
            const RecentActivityWidget(
              maxActivities: 15,
              showFilters: true,
            ),

            const SizedBox(height: 40),

            // Information Section
            const Text(
              'Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'About Migration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'The migration tool updates your user database with new fields required for the user management system:\n\n'
                    '• isActive - Controls user account status\n'
                    '• updatedAt - Tracks last modification\n'
                    '• Normalized roles - Ensures consistent role formatting\n'
                    '• Unique IDs - Generates missing user IDs\n\n'
                    'This is safe to run multiple times and will only update users that need it.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E40AF),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9CA3AF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
