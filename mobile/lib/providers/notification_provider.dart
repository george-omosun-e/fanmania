import 'package:flutter/foundation.dart';
import '../models/leaderboard.dart';
import '../services/api_service.dart';

/// Provider for managing notification state
class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  NotificationProvider(this._apiService);

  // Getters
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasNotifications => _notifications.isNotEmpty;
  bool get hasUnread => _unreadCount > 0;

  /// Fetch notifications
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications();
      _notifications = response.notifications;
      _unreadCount = response.unreadCount;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          body: _notifications[index].body,
          notificationType: _notifications[index].notificationType,
          actionUrl: _notifications[index].actionUrl,
          isRead: true,
          isPushed: _notifications[index].isPushed,
          createdAt: _notifications[index].createdAt,
          expiresAt: _notifications[index].expiresAt,
          readAt: DateTime.now(),
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();

      // Update local state
      _notifications = _notifications.map((n) {
        if (!n.isRead) {
          return AppNotification(
            id: n.id,
            userId: n.userId,
            title: n.title,
            body: n.body,
            notificationType: n.notificationType,
            actionUrl: n.actionUrl,
            isRead: true,
            isPushed: n.isPushed,
            createdAt: n.createdAt,
            expiresAt: n.expiresAt,
            readAt: DateTime.now(),
          );
        }
        return n;
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking all notifications as read: $e');
      notifyListeners();
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await fetchNotifications();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
