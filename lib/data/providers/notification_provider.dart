import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  int get readCount => _notifications.where((n) => n.isRead).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetch notifications
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Not logged in");

      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _notifications = List<Map<String, dynamic>>.from(
        response,
      ).map((json) => NotificationModel.fromJson(json)).toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint("Error fetch notifications: $e");
      // Don't clear existing notifications on error, they might just be offline or tables don't exist yet
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      // Optimistic update
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error mark as read: $e");
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      fetchNotifications();
    } catch (e) {
      debugPrint("Error mark all as read: $e");
    }
  }

  /// Delete notifications that have already been read
  Future<bool> deleteReadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('is_read', true);

      _notifications = _notifications.where((n) => !n.isRead).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error delete read notifications: $e");
      return false;
    }
  }
}
