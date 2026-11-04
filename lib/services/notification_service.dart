import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel('com.hireflow.app/notifications');

  static Future<bool> showSystemNotification({
    required String title,
    required String message,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('showSystemNotification', {
        'title': title,
        'message': message,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('Native notification error: $e');
      return false;
    }
  }
}

class NotificationProvider extends ChangeNotifier {
  List<UserNotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  Timer? _pollingTimer;
  final Set<int> _knownNotificationIds = {};
  bool _hasInitialLoaded = false;

  // Callback to display in-app banner/dialog if UI wants to listen
  void Function(UserNotificationModel notification)? onNewNotificationReceived;

  List<UserNotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  void startPolling({Duration interval = const Duration(seconds: 4)}) {
    _pollingTimer?.cancel();
    fetchNotifications(isBackground: true);
    _pollingTimer = Timer.periodic(interval, (_) {
      fetchNotifications(isBackground: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchNotifications({bool isBackground = false}) async {
    if (!isBackground) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final token = await ApiService.getToken();
      if (token == null) {
        stopPolling();
        return;
      }

      final res = await ApiService.get('/api/notifications');
      if (res is List) {
        final List<UserNotificationModel> fetched = res
            .map((item) => UserNotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Detect new unread notifications that were not seen before
        if (_hasInitialLoaded) {
          for (final n in fetched) {
            if (!_knownNotificationIds.contains(n.notificationId) && !n.isRead) {
              // Trigger Native Android System Notification
              NativeNotificationService.showSystemNotification(
                title: n.title,
                message: n.message,
              );

              // Trigger In-app banner callback
              if (onNewNotificationReceived != null) {
                onNewNotificationReceived!(n);
              }
            }
          }
        }

        // Cache known IDs
        for (final n in fetched) {
          _knownNotificationIds.add(n.notificationId);
        }
        _hasInitialLoaded = true;

        _notifications = fetched;
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      debugPrint('Fetch notifications error: $e');
    } finally {
      if (!isBackground) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.patch('/api/notifications/$notificationId/read');
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        final old = _notifications[index];
        _notifications[index] = UserNotificationModel(
          notificationId: old.notificationId,
          title: old.title,
          message: old.message,
          type: old.type,
          referenceId: old.referenceId,
          isRead: true,
          createdAt: old.createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.post('/api/notifications/mark-all-read');
      _notifications = _notifications.map((n) {
        return UserNotificationModel(
          notificationId: n.notificationId,
          title: n.title,
          message: n.message,
          type: n.type,
          referenceId: n.referenceId,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Mark all read error: $e');
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

