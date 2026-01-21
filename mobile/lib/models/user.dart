class User {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final int totalPoints;
  final int? globalRank;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.totalPoints,
    this.globalRank,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      totalPoints: json['total_points'] ?? 0,
      globalRank: json['global_rank'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'global_rank': globalRank,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  String get displayNameOrUsername => displayName ?? username;
}

class UserStats {
  final int totalPoints;
  final int? globalRank;
  final int challengesCompleted;
  final int challengesCorrect;
  final double accuracyPercentage;
  final int currentStreak;
  final int longestStreak;

  UserStats({
    required this.totalPoints,
    this.globalRank,
    required this.challengesCompleted,
    required this.challengesCorrect,
    required this.accuracyPercentage,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalPoints: json['total_points'] ?? 0,
      globalRank: json['global_rank'],
      challengesCompleted: json['challenges_completed'] ?? 0,
      challengesCorrect: json['challenges_correct'] ?? 0,
      accuracyPercentage: (json['accuracy_percentage'] ?? 0.0).toDouble(),
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: User.fromJson(json['user']),
    );
  }
}
