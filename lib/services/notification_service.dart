import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationService {
  static const String _notificationsKey = 'app_notifications';

  // Bildirimleri kaydet
  static Future<void> saveNotifications(List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationJsonList = notifications
        .map((notification) => jsonEncode(notification.toMap()))
        .toList();
    await prefs.setStringList(_notificationsKey, notificationJsonList);
  }

  // Bildirimleri getir
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? notificationJsonList = prefs.getStringList(_notificationsKey);
      if (notificationJsonList != null) {
        return notificationJsonList
            .map((json) => NotificationModel.fromMap(jsonDecode(json)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // En yeni önce
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Yeni bildirim ekle
  static Future<void> addNotification(NotificationModel notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification); // En başa ekle
    
    // En fazla 50 bildirim sakla
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }
    
    await saveNotifications(notifications);
  }

  // Bildirimi okundu olarak işaretle
  static Future<void> markAsRead(String notificationId) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);
    
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await saveNotifications(notifications);
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  static Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    final updatedNotifications = notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await saveNotifications(updatedNotifications);
  }

  // Okunmamış bildirim sayısını getir
  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  // Arıza durumu güncellemesi için bildirim oluştur
  static Future<void> createFaultUpdateNotification({
    required String faultId,
    required String faultTitle,
    required String newStatus,
    required String updatedBy,
  }) async {
    final statusText = _getStatusText(newStatus);
    
    final notification = NotificationModel(
      id: 'fault_update_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Arıza Durumu Güncellendi',
      message: '"$faultTitle" arızası $statusText durumuna geçirildi. (Güncelleyen: $updatedBy)',
      type: 'fault_update',
      relatedId: faultId,
      createdAt: DateTime.now(),
      actionType: 'view_fault',
    );

    await addNotification(notification);
  }

  // Durum metni çevirisi
  static String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Bekliyor';
      case 'reviewing':
        return 'İnceleniyor';
      case 'teamassigned':
        return 'Ekip Atandı';
      case 'ontheway':
        return 'Yolda';
      case 'onsite':
        return 'Sahada';
      case 'inprogress':
        return 'İşlemde';
      case 'testing':
        return 'Test Ediliyor';
      case 'resolved':
        return 'Çözüldü';
      case 'closed':
        return 'Kapatıldı';
      default:
        return status;
    }
  }

  // Bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }
}
