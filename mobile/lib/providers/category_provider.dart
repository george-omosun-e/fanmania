import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/api_service.dart';

/// Provider for managing category state
class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._apiService);

  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCategories => _categories.isNotEmpty;

  /// Fetch all categories
  Future<void> fetchCategories({bool includeUserStats = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories(
        includeUserStats: includeUserStats,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a category
  void selectCategory(Category category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Clear selected category
  void clearSelection() {
    _selectedCategory = null;
    notifyListeners();
  }

  /// Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Refresh categories
  Future<void> refresh() async {
    await fetchCategories(includeUserStats: true);
  }
}
