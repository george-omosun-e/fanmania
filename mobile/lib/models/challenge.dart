class Challenge {
  final String id;
  final String categoryId;
  final String title;
  final String? description;
  final QuestionData questionData;
  final int difficultyTier;
  final int basePoints;
  final int? timeLimitSeconds;
  final String challengeType;
  final bool aiGenerated;
  final bool isActive;
  final DateTime? activeUntil;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description,
    required this.questionData,
    required this.difficultyTier,
    required this.basePoints,
    this.timeLimitSeconds,
    required this.challengeType,
    required this.aiGenerated,
    required this.isActive,
    this.activeUntil,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      categoryId: json['category_id'],
      title: json['title'],
      description: json['description'],
      questionData: QuestionData.fromJson(json['question_data']),
      difficultyTier: json['difficulty_tier'] ?? 1,
      basePoints: json['base_points'] ?? 100,
      timeLimitSeconds: json['time_limit_seconds'],
      challengeType: json['challenge_type'] ?? 'multiple_choice',
      aiGenerated: json['ai_generated'] ?? true,
      isActive: json['is_active'] ?? true,
      activeUntil: json['active_until'] != null
          ? DateTime.parse(json['active_until'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'question_data': questionData.toJson(),
      'difficulty_tier': difficultyTier,
      'base_points': basePoints,
      'time_limit_seconds': timeLimitSeconds,
      'challenge_type': challengeType,
      'ai_generated': aiGenerated,
      'is_active': isActive,
      'active_until': activeUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get difficulty label
  String get difficultyLabel {
    switch (difficultyTier) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Unknown';
    }
  }
}

class QuestionData {
  final String type;
  final String question;
  final List<QuestionOption> options;

  QuestionData({
    required this.type,
    required this.question,
    required this.options,
  });

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    return QuestionData(
      type: json['type'] ?? 'multiple_choice',
      question: json['question'] ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => QuestionOption.fromJson(o))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class QuestionOption {
  final String id;
  final String text;

  QuestionOption({
    required this.id,
    required this.text,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }
}

class ChallengeResult {
  final bool isCorrect;
  final int pointsEarned;
  final String? explanation;
  final int newTotalPoints;
  final int? newRank;
  final bool streakUpdated;
  final int streakDays;

  ChallengeResult({
    required this.isCorrect,
    required this.pointsEarned,
    this.explanation,
    required this.newTotalPoints,
    this.newRank,
    required this.streakUpdated,
    required this.streakDays,
  });

  factory ChallengeResult.fromJson(Map<String, dynamic> json) {
    return ChallengeResult(
      isCorrect: json['is_correct'] ?? false,
      pointsEarned: json['points_earned'] ?? 0,
      explanation: json['explanation'],
      newTotalPoints: json['new_total_points'] ?? 0,
      newRank: json['new_rank'],
      streakUpdated: json['streak_updated'] ?? false,
      streakDays: json['streak_days'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_correct': isCorrect,
      'points_earned': pointsEarned,
      'explanation': explanation,
      'new_total_points': newTotalPoints,
      'new_rank': newRank,
      'streak_updated': streakUpdated,
      'streak_days': streakDays,
    };
  }
}
