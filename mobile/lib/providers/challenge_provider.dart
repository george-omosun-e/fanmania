import 'package:flutter/foundation.dart' hide Category;
import '../models/challenge.dart';
import '../models/category.dart';
import '../services/api_service.dart';

/// Provider for managing challenge/quiz state
class ChallengeProvider extends ChangeNotifier {
  final ApiService _apiService;

  // Current challenge session state
  Category? _currentCategory;
  int _selectedDifficulty = 1;
  List<Challenge> _challenges = [];
  int _currentChallengeIndex = 0;
  ChallengeResult? _lastResult;

  // Loading states
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // Timer state
  int _remainingSeconds = 0;
  bool _timerActive = false;

  ChallengeProvider(this._apiService);

  // ==========================================
  // GETTERS
  // ==========================================

  Category? get currentCategory => _currentCategory;
  int get selectedDifficulty => _selectedDifficulty;
  List<Challenge> get challenges => _challenges;
  int get currentChallengeIndex => _currentChallengeIndex;
  Challenge? get currentChallenge =>
      _challenges.isNotEmpty && _currentChallengeIndex < _challenges.length
          ? _challenges[_currentChallengeIndex]
          : null;
  ChallengeResult? get lastResult => _lastResult;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  int get remainingSeconds => _remainingSeconds;
  bool get timerActive => _timerActive;
  bool get hasMoreChallenges =>
      _currentChallengeIndex < _challenges.length - 1;
  int get totalChallenges => _challenges.length;
  int get completedChallenges => _currentChallengeIndex;

  // ==========================================
  // ACTIONS
  // ==========================================

  /// Start a new challenge session for a category
  void startSession(Category category) {
    _currentCategory = category;
    _selectedDifficulty = 1;
    _challenges = [];
    _currentChallengeIndex = 0;
    _lastResult = null;
    _error = null;
    notifyListeners();
  }

  /// Set the difficulty level
  void setDifficulty(int difficulty) {
    _selectedDifficulty = difficulty.clamp(1, 5);
    notifyListeners();
  }

  /// Fetch challenges for the current category and difficulty
  Future<bool> fetchChallenges({int limit = 5}) async {
    if (_currentCategory == null) {
      _error = 'No category selected';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _challenges = await _apiService.getChallenges(
        categoryId: _currentCategory!.id,
        difficultyTier: _selectedDifficulty,
        limit: limit,
      );
      _currentChallengeIndex = 0;
      _lastResult = null;

      if (_challenges.isEmpty) {
        _error = 'No challenges available for this difficulty';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Start timer for first challenge
      _startTimer();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit answer for current challenge
  Future<bool> submitAnswer(String selectedAnswer) async {
    final challenge = currentChallenge;
    if (challenge == null) {
      _error = 'No active challenge';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _timerActive = false;
    notifyListeners();

    try {
      final timeTaken = challenge.timeLimitSeconds != null
          ? challenge.timeLimitSeconds! - _remainingSeconds
          : null;

      _lastResult = await _apiService.submitChallenge(
        challengeId: challenge.id,
        selectedAnswer: selectedAnswer,
        timeTakenSeconds: timeTaken,
      );

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Move to next challenge
  bool nextChallenge() {
    if (!hasMoreChallenges) {
      return false;
    }

    _currentChallengeIndex++;
    _lastResult = null;
    _startTimer();
    notifyListeners();
    return true;
  }

  /// Handle time expiry (auto-submit with no answer)
  Future<void> onTimeExpired() async {
    _timerActive = false;
    // Submit with empty answer (will be marked wrong)
    await submitAnswer('');
  }

  /// Update timer (called from UI every second)
  void updateTimer(int seconds) {
    _remainingSeconds = seconds;
    if (seconds <= 0 && _timerActive) {
      onTimeExpired();
    }
    notifyListeners();
  }

  /// Start timer for current challenge
  void _startTimer() {
    final challenge = currentChallenge;
    if (challenge?.timeLimitSeconds != null) {
      _remainingSeconds = challenge!.timeLimitSeconds!;
      _timerActive = true;
    } else {
      _remainingSeconds = 60; // Default 60 seconds
      _timerActive = true;
    }
  }

  /// Pause timer
  void pauseTimer() {
    _timerActive = false;
    notifyListeners();
  }

  /// Resume timer
  void resumeTimer() {
    _timerActive = true;
    notifyListeners();
  }

  /// End the current session
  void endSession() {
    _currentCategory = null;
    _challenges = [];
    _currentChallengeIndex = 0;
    _lastResult = null;
    _timerActive = false;
    _remainingSeconds = 0;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get difficulty label
  String getDifficultyLabel(int tier) {
    switch (tier) {
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

  /// Check if difficulty is unlocked (placeholder - implement based on user stats)
  bool isDifficultyUnlocked(int tier) {
    // For now, all difficulties are unlocked
    // TODO: Implement based on user's mastery percentage
    return true;
  }
}
