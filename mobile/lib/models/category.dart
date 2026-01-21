class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String iconType;
  final String colorPrimary;
  final String colorSecondary;
  final bool isActive;
  final DateTime createdAt;
  final int sortOrder;
  final CategoryUserStats? userStats;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.iconType,
    required this.colorPrimary,
    required this.colorSecondary,
    required this.isActive,
    required this.createdAt,
    required this.sortOrder,
    this.userStats,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      iconType: json['icon_type'] ?? 'cube',
      colorPrimary: json['color_primary'] ?? '#00F2FF',
      colorSecondary: json['color_secondary'] ?? '#8A2BE2',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      sortOrder: json['sort_order'] ?? 0,
      userStats: json['user_stats'] != null
          ? CategoryUserStats.fromJson(json['user_stats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon_type': iconType,
      'color_primary': colorPrimary,
      'color_secondary': colorSecondary,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'sort_order': sortOrder,
      'user_stats': userStats?.toJson(),
    };
  }
}

class CategoryUserStats {
  final int points;
  final int? rank;
  final double masteryPercentage;
  final int streakDays;

  CategoryUserStats({
    required this.points,
    this.rank,
    required this.masteryPercentage,
    required this.streakDays,
  });

  factory CategoryUserStats.fromJson(Map<String, dynamic> json) {
    return CategoryUserStats(
      points: json['points'] ?? 0,
      rank: json['rank'],
      masteryPercentage: (json['mastery_percentage'] ?? 0.0).toDouble(),
      streakDays: json['streak_days'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'rank': rank,
      'mastery_percentage': masteryPercentage,
      'streak_days': streakDays,
    };
  }
}
