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
  Future<bool> fetchChallenges({int limit = 10}) async {
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
      // Try to fetch more challenges in the background
      _fetchMoreChallenges();
      return false;
    }

    _currentChallengeIndex++;
    _lastResult = null;
    _startTimer();
    notifyListeners();

    // Prefetch more challenges if running low
    if (_challenges.length - _currentChallengeIndex <= 2) {
      _fetchMoreChallenges();
    }

    return true;
  }

  /// Fetch more challenges and append to current list
  Future<void> _fetchMoreChallenges() async {
    if (_currentCategory == null || _isLoading) return;

    try {
      final newChallenges = await _apiService.getChallenges(
        categoryId: _currentCategory!.id,
        difficultyTier: _selectedDifficulty,
        limit: 5,
      );

      // Filter out challenges we already have
      final existingIds = _challenges.map((c) => c.id).toSet();
      final uniqueNew = newChallenges.where((c) => !existingIds.contains(c.id)).toList();

      if (uniqueNew.isNotEmpty) {
        _challenges.addAll(uniqueNew);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch more challenges: $e');
    }
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

  /// Check if difficulty is unlocked based on category mastery
  /// - Tier 1: Always unlocked
  /// - Tier 2: Requires 60% mastery on Tier 1
  /// - Tier 3: Requires 60% mastery on Tier 2
  /// - Tier 4: Requires 70% mastery on Tier 3
  /// - Tier 5: Requires 80% mastery on Tier 4
  bool isDifficultyUnlocked(int tier) {
    if (tier <= 1) return true;

    final categoryMastery = _currentCategory?.userStats?.masteryPercentage ?? 0;

    // Calculate required mastery based on tier
    // Using category mastery as a proxy until we have tier-specific data
    final requiredMastery = getUnlockRequirement(tier);
    final previousTierMastery = _estimateTierMastery(tier - 1, categoryMastery);

    return previousTierMastery >= requiredMastery;
  }

  /// Get the mastery percentage required to unlock a tier
  double getUnlockRequirement(int tier) {
    switch (tier) {
      case 2:
        return 60.0;
      case 3:
        return 60.0;
      case 4:
        return 70.0;
      case 5:
        return 80.0;
      default:
        return 0.0;
    }
  }

  /// Estimate tier mastery from overall category mastery
  /// This is a simplified calculation until we have tier-specific data
  double _estimateTierMastery(int tier, double overallMastery) {
    // Assume mastery is distributed across tiers
    // As users progress, earlier tiers should have higher mastery
    if (tier == 1) {
      // Tier 1 mastery is typically higher than overall
      return overallMastery * 1.5;
    } else if (tier == 2) {
      return overallMastery * 1.2;
    } else if (tier == 3) {
      return overallMastery;
    } else if (tier == 4) {
      return overallMastery * 0.8;
    } else {
      return overallMastery * 0.6;
    }
  }

  /// Get unlock requirement text for a locked tier
  String getUnlockRequirementText(int tier) {
    if (tier <= 1) return '';

    final required = getUnlockRequirement(tier);
    final previousTierName = getDifficultyLabel(tier - 1);

    return 'Complete ${required.toInt()}% of $previousTierName challenges to unlock';
  }

  /// Get current progress towards unlocking a tier
  double getUnlockProgress(int tier) {
    if (tier <= 1) return 1.0;

    final categoryMastery = _currentCategory?.userStats?.masteryPercentage ?? 0;
    final requiredMastery = getUnlockRequirement(tier);
    final previousTierMastery = _estimateTierMastery(tier - 1, categoryMastery);

    return (previousTierMastery / requiredMastery).clamp(0.0, 1.0);
  }
}
