import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService) {
    _checkAuthStatus();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if user is logged in on app start
  Future<void> _checkAuthStatus() async {
    if (_apiService.isAuthenticated) {
      try {
        _currentUser = await _apiService.getCurrentUser();
        notifyListeners();
      } catch (e) {
        // Token might be expired, logout
        await logout();
      }
    }
  }

  // Login
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.login(
        username: username,
        password: password,
      );
      _currentUser = authResponse.user;
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

  // Register
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.register(
        username: username,
        email: email,
        password: password,
      );
      _currentUser = authResponse.user;
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

  // Logout
  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh user: $e');
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _apiService.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
