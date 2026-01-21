class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int points;
  final double? masteryPercentage;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.points,
    this.masteryPercentage,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      points: json['points'] ?? 0,
      masteryPercentage: json['mastery_percentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'points': points,
      'mastery_percentage': masteryPercentage,
    };
  }

  String get displayNameOrUsername => displayName ?? username;
}

class LeaderboardResponse {
  final String scope;
  final String? categoryId;
  final List<LeaderboardEntry> entries;
  final int? userRank;
  final int totalUsers;

  LeaderboardResponse({
    required this.scope,
    this.categoryId,
    required this.entries,
    this.userRank,
    required this.totalUsers,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      scope: json['scope'] ?? 'weekly',
      categoryId: json['category_id'],
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e))
              .toList() ??
          [],
      userRank: json['user_rank'],
      totalUsers: json['total_users'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scope': scope,
      'category_id': categoryId,
      'entries': entries.map((e) => e.toJson()).toList(),
      'user_rank': userRank,
      'total_users': totalUsers,
    };
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String notificationType;
  final String? actionUrl;
  final bool isRead;
  final bool isPushed;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.notificationType,
    this.actionUrl,
    required this.isRead,
    required this.isPushed,
    required this.createdAt,
    this.expiresAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      notificationType: json['notification_type'] ?? 'general',
      actionUrl: json['action_url'],
      isRead: json['is_read'] ?? false,
      isPushed: json['is_pushed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'notification_type': notificationType,
      'action_url': actionUrl,
      'is_read': isRead,
      'is_pushed': isPushed,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}

class NotificationResponse {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['notifications'] as List<dynamic>?)
              ?.map((n) => AppNotification.fromJson(n))
              .toList() ??
          [],
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'unread_count': unreadCount,
    };
  }
}
