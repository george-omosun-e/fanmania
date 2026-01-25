import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/api_config.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/challenge.dart';
import '../models/leaderboard.dart';

class ApiService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;

  ApiService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  // Load tokens from storage
  Future<void> loadTokens() async {
    _accessToken = await _storage.read(key: ApiConfig.accessTokenKey);
    _refreshToken = await _storage.read(key: ApiConfig.refreshTokenKey);
  }

  // Save tokens to storage
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: ApiConfig.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
  }

  // Clear tokens
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: ApiConfig.accessTokenKey);
    await _storage.delete(key: ApiConfig.refreshTokenKey);
    await _storage.delete(key: ApiConfig.userIdKey);
    await _storage.delete(key: ApiConfig.usernameKey);
  }

  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  // Get headers
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  // Handle API errors
  void _handleError(http.Response response) {
    final body = json.decode(response.body);
    final message = body['error'] ?? 'Unknown error occurred';
    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      code: body['code'],
    );
  }

  // ==========================================
  // AUTH ENDPOINTS
  // ==========================================

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.auth}/register');
    final response = await _client.post(
      url,
      headers: _getHeaders(),
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      await saveTokens(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    } else {
      _handleError(response);
      throw Exception('Registration failed');
    }
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.auth}/login');
    final response = await _client.post(
      url,
      headers: _getHeaders(),
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      await saveTokens(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    } else {
      _handleError(response);
      throw Exception('Login failed');
    }
  }

  Future<void> logout() async {
    await clearTokens();
  }

  // ==========================================
  // USER ENDPOINTS
  // ==========================================

  Future<User> getCurrentUser() async {
    final url = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.users}/me');
    final response = await _client.get(
      url,
      headers: _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to get user');
    }
  }

  Future<UserStats> getUserStats() async {
    final url = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.users}/me/stats');
    final response = await _client.get(
      url,
      headers: _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      return UserStats.fromJson(json.decode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to get stats');
    }
  }

  Future<User> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final url = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.users}/me');
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await _client.patch(
      url,
      headers: _getHeaders(includeAuth: true),
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to update profile');
    }
  }

  // ==========================================
  // CATEGORY ENDPOINTS
  // ==========================================

  Future<List<Category>> getCategories({bool includeUserStats = false}) async {
    final url = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.categories}').replace(
      queryParameters: {
        if (includeUserStats) 'include_user_stats': 'true',
      },
    );

    final response = await _client.get(
      url,
      headers: _getHeaders(includeAuth: includeUserStats),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final categories = data['categories'] as List<dynamic>?;
      if (categories == null) {
        return [];
      }
      return categories
          .map((c) => Category.fromJson(c))
          .toList();
    } else {
      _handleError(response);
      throw Exception('Failed to get categories');
    }
  }

  Future<Category> getCategory(String categoryId) async {
    final url = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.categories}/$categoryId');
    final response = await _client.get(
      url,
      headers: _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to get category');
    }
  }

  // ==========================================
  // CHALLENGE ENDPOINTS
  // ==========================================

  Future<List<Challenge>> getChallenges({
    required String categoryId,
    int? difficultyTier,
    int limit = 10,
  }) async {
    final queryParams = {
      'category_id': categoryId,
      'limit': limit.toString(),
    };
    if (difficultyTier != null) {
      queryParams['difficulty_tier'] = difficultyTier.toString();
    }

    final url = Uri.parse('${ApiConfig.apiUrl}${ApiConfig.challenges}')
        .replace(queryParameters: queryParams);

    final response = await _client.get(
      url,
      headers: _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final challenges = data['challenges'] as List<dynamic>?;
      if (challenges == null || challenges.isEmpty) {
        return [];
      }
      return challenges
          .map((c) => Challenge.fromJson(c))
          .toList();
    } else {
      _handleError(response);
      throw Exception('Failed to get challenges');
    }
  }

  Future<ChallengeResult> submitChallenge({
    required String challengeId,
    required String selectedAnswer,
    int? timeTakenSeconds,
  }) async {
    final url = Uri.parse(
        '${ApiConfig.apiUrl}${ApiConfig.challenges}/$challengeId/attempt');

    final response = await _client.post(
      url,
      headers: _getHeaders(includeAuth: true),
      body: json.encode({
        'selected_answer': selectedAnswer,
        if (timeTakenSeconds != null) 'time_taken_seconds': timeTakenSeconds,
      }),
    );

    if (response.statusCode == 200) {
      return ChallengeResult.fromJson(json.decode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to submit challenge');
    }
  }

  // ==========================================
  // LEADERBOARD ENDPOINTS
  // ==========================================

  Future<LeaderboardResponse> getGlobalLeaderboard({
    String scope = 'weekly',
    int limit = 100,
  }) async {
    final url =
    Uri.parse('${ApiConfig.apiUrl}${ApiConfig.leaderboards}/global')
        .replace(queryParameters: {
      'scope': scope,
      'limit': limit.toString(),
    });

    final response = await _client.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      return LeaderboardResponse.fromJson(json.decode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to get leaderboard');
    }
  }

  Future<LeaderboardResponse> getCategoryLeaderboard({
    required String categoryId,
    String scope = 'weekly',
    int limit = 100,
  }) async {
    final url = Uri.parse(
        '${ApiConfig.apiUrl}${ApiConfig.leaderboards}/category/$categoryId')
        .replace(queryParameters: {
      'scope': scope,
      'limit': limit.toString(),
    });

    final response = await _client.get(
      url,
      headers: _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      return LeaderboardResponse.fromJson(json.decode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to get leaderboard');
    }
  }

  // ==========================================
  // NOTIFICATION ENDPOINTS
  // ==========================================

  Future<NotificationResponse> getNotifications({int limit = 50}) async {
    final url =
    Uri.parse('${ApiConfig.apiUrl}${ApiConfig.notifications}').replace(
      queryParameters: {'limit': limit.toString()},
    );

    final response = await _client.get(
      url,
      headers: _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      return NotificationResponse.fromJson(json.decode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to get notifications');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final url = Uri.parse(
        '${ApiConfig.apiUrl}${ApiConfig.notifications}/$notificationId/read');

    final response = await _client.post(
      url,
      headers: _getHeaders(includeAuth: true),
    );

    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final url = Uri.parse(
        '${ApiConfig.apiUrl}${ApiConfig.notifications}/read-all');

    final response = await _client.post(
      url,
      headers: _getHeaders(includeAuth: true),
    );

    if (response.statusCode != 200) {
      _handleError(response);
    }
  }

  Future<void> registerDevice({
    required String fcmToken,
    required String deviceType,
  }) async {
    final url = Uri.parse(
        '${ApiConfig.apiUrl}${ApiConfig.notifications}/register-device');

    final response = await _client.post(
      url,
      headers: _getHeaders(includeAuth: true),
      body: json.encode({
        'fcm_token': fcmToken,
        'device_type': deviceType,
      }),
    );

    if (response.statusCode != 200) {
      _handleError(response);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;

  ApiException({
    required this.message,
    required this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}