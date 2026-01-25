import 'package:flutter/foundation.dart';
import '../models/leaderboard.dart';
import '../services/api_service.dart';

/// Provider for managing leaderboard state
class LeaderboardProvider extends ChangeNotifier {
  final ApiService _apiService;

  LeaderboardResponse? _globalLeaderboard;
  LeaderboardResponse? _categoryLeaderboard;
  String _currentScope = 'weekly';
  String? _currentCategoryId;
  bool _isLoading = false;
  String? _error;

  LeaderboardProvider(this._apiService);

  // Getters
  LeaderboardResponse? get globalLeaderboard => _globalLeaderboard;
  LeaderboardResponse? get categoryLeaderboard => _categoryLeaderboard;
  String get currentScope => _currentScope;
  String? get currentCategoryId => _currentCategoryId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<LeaderboardEntry> get currentEntries {
    if (_currentCategoryId != null) {
      return _categoryLeaderboard?.entries ?? [];
    }
    return _globalLeaderboard?.entries ?? [];
  }

  int? get userRank {
    if (_currentCategoryId != null) {
      return _categoryLeaderboard?.userRank;
    }
    return _globalLeaderboard?.userRank;
  }

  int get totalUsers {
    if (_currentCategoryId != null) {
      return _categoryLeaderboard?.totalUsers ?? 0;
    }
    return _globalLeaderboard?.totalUsers ?? 0;
  }

  /// Fetch global leaderboard
  Future<void> fetchGlobalLeaderboard({String? scope}) async {
    _isLoading = true;
    _error = null;
    _currentCategoryId = null;
    if (scope != null) _currentScope = scope;
    notifyListeners();

    try {
      _globalLeaderboard = await _apiService.getGlobalLeaderboard(
        scope: _currentScope,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching global leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch category leaderboard
  Future<void> fetchCategoryLeaderboard({
    required String categoryId,
    String? scope,
  }) async {
    _isLoading = true;
    _error = null;
    _currentCategoryId = categoryId;
    if (scope != null) _currentScope = scope;
    notifyListeners();

    try {
      _categoryLeaderboard = await _apiService.getCategoryLeaderboard(
        categoryId: categoryId,
        scope: _currentScope,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching category leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change time scope
  void setScope(String scope) {
    if (_currentScope != scope) {
      _currentScope = scope;
      refresh();
    }
  }

  /// Refresh current leaderboard
  Future<void> refresh() async {
    if (_currentCategoryId != null) {
      await fetchCategoryLeaderboard(categoryId: _currentCategoryId!);
    } else {
      await fetchGlobalLeaderboard();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
