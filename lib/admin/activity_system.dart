import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Activity Types in the system
enum ActivityType {
  // Teacher Activities
  teacherSignup,
  teacherLogin,
  contentUpload,
  quizCreated,
  quizPublished,
  quizUpdated,
  quizDeleted,
  topicCreated,
  topicUpdated,
  studentGraded,
  rewardIssued,
  badgeAwarded,

  // Student Activities
  studentSignup,
  studentLogin,
  contentViewed,
  quizStarted,
  quizCompleted,
  quizSubmitted,
  rewardEarned,
  badgeReceived,
  achievementUnlocked,

  // System Activities
  userActivated,
  userDeactivated,
  roleChanged,
}

/// Activity Model to track all user actions
class Activity {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final String userRole;
  final String? userAvatar;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String description;

  Activity({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.userAvatar,
    required this.timestamp,
    required this.metadata,
    required this.description,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${data['type']}',
        orElse: () => ActivityType.studentLogin,
      ),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      userRole: data['userRole'] ?? 'student',
      userAvatar: data['userAvatar'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'userAvatar': userAvatar,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'description': description,
    };
  }

  String getIcon() {
    switch (type) {
      case ActivityType.teacherSignup:
      case ActivityType.teacherLogin:
        return '👨‍🏫';
      case ActivityType.contentUpload:
        return '📤';
      case ActivityType.quizCreated:
      case ActivityType.quizPublished:
        return '📝';
      case ActivityType.quizUpdated:
        return '✏️';
      case ActivityType.quizDeleted:
        return '🗑️';
      case ActivityType.topicCreated:
      case ActivityType.topicUpdated:
        return '📚';
      case ActivityType.studentGraded:
        return '✅';
      case ActivityType.rewardIssued:
        return '🎁';
      case ActivityType.badgeAwarded:
        return '🏆';
      case ActivityType.studentSignup:
      case ActivityType.studentLogin:
        return '👨‍🎓';
      case ActivityType.contentViewed:
        return '👀';
      case ActivityType.quizStarted:
        return '🎯';
      case ActivityType.quizCompleted:
      case ActivityType.quizSubmitted:
        return '✔️';
      case ActivityType.rewardEarned:
        return '💰';
      case ActivityType.badgeReceived:
        return '🏅';
      case ActivityType.achievementUnlocked:
        return '🌟';
      case ActivityType.userActivated:
        return '✅';
      case ActivityType.userDeactivated:
        return '❌';
      case ActivityType.roleChanged:
        return '🔄';
      default:
        return '📌';
    }
  }

  Color getActionColor() {
    switch (type) {
      case ActivityType.teacherSignup:
      case ActivityType.teacherLogin:
        return const Color(0xFF2196F3);
      case ActivityType.quizCreated:
      case ActivityType.quizPublished:
        return const Color(0xFF8B5CF6);
      case ActivityType.studentSignup:
      case ActivityType.studentLogin:
        return const Color(0xFF10B981);
      case ActivityType.rewardEarned:
      case ActivityType.badgeReceived:
        return const Color(0xFFF59E0B);
      case ActivityType.quizCompleted:
        return const Color(0xFF059669);
      case ActivityType.userDeactivated:
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  String getActionTitle() {
    switch (type) {
      case ActivityType.teacherSignup:
        return 'Joined as Teacher';
      case ActivityType.teacherLogin:
        return 'Logged In';
      case ActivityType.studentSignup:
        return 'Joined as Student';
      case ActivityType.studentLogin:
        return 'Logged In';
      case ActivityType.contentUpload:
        return 'Uploaded Content';
      case ActivityType.quizCreated:
        return 'Created Quiz';
      case ActivityType.quizPublished:
        return 'Published Quiz';
      case ActivityType.quizUpdated:
        return 'Updated Quiz';
      case ActivityType.quizDeleted:
        return 'Deleted Quiz';
      case ActivityType.quizStarted:
        return 'Started Quiz';
      case ActivityType.quizCompleted:
        return 'Completed Quiz';
      case ActivityType.quizSubmitted:
        return 'Submitted Quiz';
      case ActivityType.topicCreated:
        return 'Created Topic';
      case ActivityType.topicUpdated:
        return 'Updated Topic';
      case ActivityType.contentViewed:
        return 'Viewed Content';
      case ActivityType.rewardEarned:
        return 'Earned Reward';
      case ActivityType.rewardIssued:
        return 'Issued Reward';
      case ActivityType.badgeReceived:
        return 'Received Badge';
      case ActivityType.badgeAwarded:
        return 'Awarded Badge';
      case ActivityType.achievementUnlocked:
        return 'Unlocked Achievement';
      case ActivityType.studentGraded:
        return 'Graded Student';
      case ActivityType.userActivated:
        return 'Account Activated';
      case ActivityType.userDeactivated:
        return 'Account Deactivated';
      case ActivityType.roleChanged:
        return 'Role Changed';
      default:
        return 'Performed Action';
    }
  }

  String? getActionDetails() {
    if (metadata.containsKey('quizTitle')) {
      return metadata['quizTitle'];
    } else if (metadata.containsKey('contentTitle')) {
      return metadata['contentTitle'];
    } else if (metadata.containsKey('topicName')) {
      return metadata['topicName'];
    } else if (metadata.containsKey('reward')) {
      return metadata['reward'];
    } else if (metadata.containsKey('badge')) {
      return metadata['badge'];
    } else if (metadata.containsKey('achievement')) {
      return metadata['achievement'];
    } else if (metadata.containsKey('studentName')) {
      return 'Student: ${metadata['studentName']}';
    }
    return null;
  }
}

// ============================================================================
// PART 2: ENHANCED ACTIVITY SERVICE WITH USER NAME FETCHING
// ============================================================================

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'activities';

  /// 🔥 NEW: Get user info from Firestore by userId
  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'name': data['name'] ??
              data['fullName'] ??
              data['email'] ??
              'Unknown User',
          'role': data['role'] ?? 'student',
          'avatar': data['avatar'] ?? data['profilePicture'],
        };
      }
    } catch (e) {
      print('❌ Error fetching user info: $e');
    }

    return {
      'name': 'Unknown User',
      'role': 'student',
      'avatar': null,
    };
  }

  /// 🔥 UPDATED: Log activity with automatic user info fetching
  Future<void> logActivity({
    required ActivityType type,
    required String userId,
    String? userName, // Now optional
    String? userRole, // Now optional
    String? userAvatar,
    Map<String, dynamic>? metadata,
    String? customDescription,
  }) async {
    try {
      // 🔥 If userName or userRole not provided, fetch from Firestore
      String finalUserName = userName ?? '';
      String finalUserRole = userRole ?? '';
      String? finalUserAvatar = userAvatar;

      if (userName == null || userRole == null) {
        final userInfo = await _getUserInfo(userId);
        finalUserName = userName ?? userInfo['name'];
        finalUserRole = userRole ?? userInfo['role'];
        finalUserAvatar = userAvatar ?? userInfo['avatar'];
      }

      final description = customDescription ??
          _generateDescription(
            type,
            finalUserName,
            metadata ?? {},
          );

      final activity = Activity(
        id: '',
        type: type,
        userId: userId,
        userName: finalUserName,
        userRole: finalUserRole,
        userAvatar: finalUserAvatar,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
        description: description,
      );

      await _firestore.collection(_collection).add(activity.toFirestore());
      print('✅ Activity logged: ${activity.description}');
    } catch (e) {
      print('❌ Error logging activity: $e');
    }
  }

  String _generateDescription(
    ActivityType type,
    String userName,
    Map<String, dynamic> metadata,
  ) {
    switch (type) {
      case ActivityType.teacherSignup:
        return '$userName joined as a teacher';
      case ActivityType.teacherLogin:
        return '$userName logged in';
      case ActivityType.contentUpload:
        final contentTitle = metadata['contentTitle'] ?? 'content';
        return '$userName uploaded "$contentTitle"';
      case ActivityType.quizCreated:
        final quizTitle = metadata['quizTitle'] ?? 'a quiz';
        return '$userName created quiz "$quizTitle"';
      case ActivityType.quizPublished:
        final quizTitle = metadata['quizTitle'] ?? 'a quiz';
        return '$userName published quiz "$quizTitle"';
      case ActivityType.quizUpdated:
        final quizTitle = metadata['quizTitle'] ?? 'a quiz';
        return '$userName updated quiz "$quizTitle"';
      case ActivityType.quizDeleted:
        final quizTitle = metadata['quizTitle'] ?? 'a quiz';
        return '$userName deleted quiz "$quizTitle"';
      case ActivityType.topicCreated:
        final topicName = metadata['topicName'] ?? 'a topic';
        return '$userName created topic "$topicName"';
      case ActivityType.topicUpdated:
        final topicName = metadata['topicName'] ?? 'a topic';
        return '$userName updated topic "$topicName"';
      case ActivityType.studentGraded:
        final studentName = metadata['studentName'] ?? 'a student';
        final score = metadata['score'] ?? 'N/A';
        return '$userName graded $studentName - Score: $score';
      case ActivityType.rewardIssued:
        final studentName = metadata['studentName'] ?? 'a student';
        final reward = metadata['reward'] ?? 'a reward';
        return '$userName issued "$reward" to $studentName';
      case ActivityType.badgeAwarded:
        final studentName = metadata['studentName'] ?? 'a student';
        final badge = metadata['badge'] ?? 'a badge';
        return '$userName awarded "$badge" badge to $studentName';
      case ActivityType.studentSignup:
        return '$userName joined as a student';
      case ActivityType.studentLogin:
        return '$userName logged in';
      case ActivityType.contentViewed:
        final contentTitle = metadata['contentTitle'] ?? 'content';
        return '$userName viewed "$contentTitle"';
      case ActivityType.quizStarted:
        final quizTitle = metadata['quizTitle'] ?? 'a quiz';
        return '$userName started quiz "$quizTitle"';
      case ActivityType.quizCompleted:
        final quizTitle = metadata['quizTitle'] ?? 'a quiz';
        final score = metadata['score'];
        if (score != null) {
          return '$userName completed "$quizTitle" - Score: $score%';
        }
        return '$userName completed "$quizTitle"';
      case ActivityType.quizSubmitted:
        final quizTitle = metadata['quizTitle'] ?? 'a quiz';
        return '$userName submitted "$quizTitle"';
      case ActivityType.rewardEarned:
        final reward = metadata['reward'] ?? 'a reward';
        final points = metadata['points'];
        if (points != null) {
          return '$userName earned "$reward" (+$points points)';
        }
        return '$userName earned "$reward"';
      case ActivityType.badgeReceived:
        final badge = metadata['badge'] ?? 'a badge';
        return '$userName received "$badge" badge';
      case ActivityType.achievementUnlocked:
        final achievement = metadata['achievement'] ?? 'an achievement';
        return '$userName unlocked "$achievement"';
      case ActivityType.userActivated:
        return '$userName account was activated';
      case ActivityType.userDeactivated:
        return '$userName account was deactivated';
      case ActivityType.roleChanged:
        final newRole = metadata['newRole'] ?? 'new role';
        return '$userName role changed to $newRole';
      default:
        return '$userName performed an action';
    }
  }

  Stream<List<Activity>> getRecentActivities({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Activity>> getActivitiesByRole(String role, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('userRole', isEqualTo: role)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
    });
  }

  // 🔥 SIMPLIFIED: Quick logging methods - now only need userId!
  Future<void> logTeacherSignup(String userId) async {
    await logActivity(
      type: ActivityType.teacherSignup,
      userId: userId,
    );
  }

  Future<void> logStudentSignup(String userId) async {
    await logActivity(
      type: ActivityType.studentSignup,
      userId: userId,
    );
  }

  Future<void> logTeacherLogin(String userId) async {
    await logActivity(
      type: ActivityType.teacherLogin,
      userId: userId,
    );
  }

  Future<void> logStudentLogin(String userId) async {
    await logActivity(
      type: ActivityType.studentLogin,
      userId: userId,
    );
  }

  Future<void> logContentUpload(String userId, String contentTitle) async {
    await logActivity(
      type: ActivityType.contentUpload,
      userId: userId,
      metadata: {'contentTitle': contentTitle},
    );
  }

  Future<void> logQuizCreated(String userId, String quizTitle,
      {int? questionCount}) async {
    await logActivity(
      type: ActivityType.quizCreated,
      userId: userId,
      metadata: {
        'quizTitle': quizTitle,
        if (questionCount != null) 'questionCount': questionCount,
      },
    );
  }

  Future<void> logQuizCompleted(
      String userId, String quizTitle, double score) async {
    await logActivity(
      type: ActivityType.quizCompleted,
      userId: userId,
      metadata: {
        'quizTitle': quizTitle,
        'score': score.toStringAsFixed(1),
      },
    );
  }

  Future<void> logRewardEarned(String userId, String reward,
      {int? points}) async {
    await logActivity(
      type: ActivityType.rewardEarned,
      userId: userId,
      metadata: {
        'reward': reward,
        if (points != null) 'points': points,
      },
    );
  }

  Future<void> logBadgeReceived(String userId, String badge) async {
    await logActivity(
      type: ActivityType.badgeReceived,
      userId: userId,
      metadata: {'badge': badge},
    );
  }
}

// ============================================================================
// PART 3: RECENT ACTIVITY WIDGET (unchanged)
// ============================================================================

class RecentActivityWidget extends StatefulWidget {
  final int maxActivities;
  final bool showFilters;

  const RecentActivityWidget({
    Key? key,
    this.maxActivities = 10,
    this.showFilters = true,
  }) : super(key: key);

  @override
  State<RecentActivityWidget> createState() => _RecentActivityWidgetState();
}

class _RecentActivityWidgetState extends State<RecentActivityWidget> {
  final ActivityService _activityService = ActivityService();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            if (widget.showFilters)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isDense: true,
                    icon: const Icon(Icons.filter_list, size: 18),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(
                          value: 'teacher', child: Text('Teachers')),
                      DropdownMenuItem(
                          value: 'student', child: Text('Students')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Activity>>(
          stream: _getFilteredActivities(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final activities = snapshot.data ?? [];

            if (activities.isEmpty) {
              return _buildEmptyState();
            }

            return _buildActivityList(activities);
          },
        ),
      ],
    );
  }

  Stream<List<Activity>> _getFilteredActivities() {
    if (_selectedFilter == 'teacher') {
      return _activityService.getActivitiesByRole('teacher',
          limit: widget.maxActivities);
    } else if (_selectedFilter == 'student') {
      return _activityService.getActivitiesByRole('student',
          limit: widget.maxActivities);
    } else {
      return _activityService.getRecentActivities(limit: widget.maxActivities);
    }
  }

  Widget _buildActivityList(List<Activity> activities) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildActivityItem(activities[index]);
        },
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    final isTeacher = activity.userRole == 'teacher';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          Row(
            children: [
              // User Avatar
              _buildUserAvatar(activity),
              const SizedBox(width: 12),

              // User Name and Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTeacher
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isTeacher ? '👨‍🏫 Teacher' : '👨‍🎓 Student',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isTeacher
                              ? const Color(0xFF1E40AF)
                              : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Time Ago
              Text(
                activity.getTimeAgo(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Action Description with Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activity.getActionColor().withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon Badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activity.getActionColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activity.getIcon(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),

                // Action Title
                Expanded(
                  child: Text(
                    activity.getActionTitle(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: activity.getActionColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Details (if available)
          if (activity.getActionDetails() != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.getActionDetails()!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Metadata Row (Score, Points, etc.)
          if (activity.metadata.containsKey('score') ||
              activity.metadata.containsKey('points') ||
              activity.metadata.containsKey('questionCount')) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (activity.metadata.containsKey('score')) ...[
                  _buildMetadataChip(
                    icon: Icons.star,
                    label: '${activity.metadata['score']}%',
                    color: activity.getActionColor(),
                  ),
                  const SizedBox(width: 8),
                ],
                if (activity.metadata.containsKey('points')) ...[
                  _buildMetadataChip(
                    icon: Icons.emoji_events,
                    label: '+${activity.metadata['points']} pts',
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                ],
                if (activity.metadata.containsKey('questionCount')) ...[
                  _buildMetadataChip(
                    icon: Icons.quiz,
                    label: '${activity.metadata['questionCount']} questions',
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(Activity activity) {
    final isTeacher = activity.userRole == 'teacher';
    final Color backgroundColor =
        isTeacher ? const Color(0xFF2196F3) : const Color(0xFF10B981);

    if (activity.userAvatar != null && activity.userAvatar!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: backgroundColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            activity.userAvatar!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(activity, backgroundColor);
            },
          ),
        ),
      );
    } else {
      return _buildDefaultAvatar(activity, backgroundColor);
    }
  }

  Widget _buildDefaultAvatar(Activity activity, Color backgroundColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          activity.userName.isNotEmpty
              ? activity.userName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 40, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text(
              'No recent activities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Activities will appear here',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: const Center(
        child: Text('Error loading activities'),
      ),
    );
  }
}
