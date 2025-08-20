import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/fault_status_model.dart';
import '../models/fault_report_model.dart';
import '../services/notification_service.dart';

class FaultTrackingService {
  static const String _trackingKey = 'fault_tracking_data';
  static const String _reportsKey = 'fault_reports_data';

  // Arıza takip verilerini kaydet
  static Future<void> saveFaultTracking(List<FaultTrackingModel> trackingList) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> trackingJsonList = trackingList
        .map((tracking) => jsonEncode(tracking.toMap()))
        .toList();
    await prefs.setStringList(_trackingKey, trackingJsonList);
  }

  // Arıza takip verilerini getir
  static Future<List<FaultTrackingModel>> getFaultTrackingList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? trackingJsonList = prefs.getStringList(_trackingKey);
      if (trackingJsonList != null) {
        return trackingJsonList
            .map((json) => FaultTrackingModel.fromMap(jsonDecode(json)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Arıza raporlarını kaydet
  static Future<void> saveFaultReports(List<FaultReportModel> reportsList) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> reportsJsonList = reportsList
        .map((report) => jsonEncode(report.toMap()))
        .toList();
    await prefs.setStringList(_reportsKey, reportsJsonList);
  }

  // Arıza raporlarını getir
  static Future<List<FaultReportModel>> getFaultReportsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? reportsJsonList = prefs.getStringList(_reportsKey);
      if (reportsJsonList != null) {
        return reportsJsonList
            .map((json) => FaultReportModel.fromMap(jsonDecode(json)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Belirli bir arıza için takip verisi getir
  static Future<FaultTrackingModel?> getFaultTracking(String faultReportId) async {
    final trackingList = await getFaultTrackingList();
    try {
      return trackingList.firstWhere((tracking) => tracking.faultReportId == faultReportId);
    } catch (e) {
      return null;
    }
  }

  // Arıza durumu güncelle
  static Future<void> updateFaultStatus({
    required String faultReportId,
    required FaultStatus newStatus,
    required String updatedBy,
    required String updatedByName,
    String? note,
    String? location,
  }) async {
    final trackingList = await getFaultTrackingList();
    final reportsList = await getFaultReportsList();
    
    // Yeni status update oluştur
    final statusUpdate = FaultStatusUpdate(
      id: 'update_${DateTime.now().millisecondsSinceEpoch}',
      faultReportId: faultReportId,
      status: newStatus,
      updatedBy: updatedBy,
      updatedByName: updatedByName,
      updatedAt: DateTime.now(),
      note: note,
      location: location,
    );

    // Mevcut tracking'i bul veya yeni oluştur
    final existingIndex = trackingList.indexWhere(
      (tracking) => tracking.faultReportId == faultReportId,
    );

    if (existingIndex != -1) {
      // Mevcut tracking'i güncelle
      final existingTracking = trackingList[existingIndex];
      final updatedHistory = [...existingTracking.statusHistory, statusUpdate];
      
      trackingList[existingIndex] = existingTracking.copyWith(
        statusHistory: updatedHistory,
        currentStatus: newStatus,
        lastUpdated: DateTime.now(),
      );
    } else {
      // Yeni tracking oluştur
      final newTracking = FaultTrackingModel(
        faultReportId: faultReportId,
        statusHistory: [statusUpdate],
        currentStatus: newStatus,
        lastUpdated: DateTime.now(),
      );
      trackingList.add(newTracking);
    }

    // Fault report'un status'unu da güncelle
    final reportIndex = reportsList.indexWhere((report) => report.id == faultReportId);
    if (reportIndex != -1) {
      reportsList[reportIndex] = reportsList[reportIndex].copyWith(status: newStatus.value);
    }

    // Verileri kaydet
    await saveFaultTracking(trackingList);
    await saveFaultReports(reportsList);

    // Bildirim oluştur
    if (reportIndex != -1) {
      final report = reportsList[reportIndex];
      await NotificationService.createFaultUpdateNotification(
        faultId: faultReportId,
        faultTitle: report.title,
        newStatus: newStatus.value,
        updatedBy: updatedByName,
      );
    }
  }

  // Test verileri oluştur
  static Future<void> createTestData() async {
    try {
      // Firebase Firestore'a test verilerini ekle
      final testReports = [
        {
          'id': 'test_1',
          'userId': 'test_user',
          'category': 'Su Kesintisi',
          'priority': 'Yüksek',
          'location': 'Nilüfer Mahallesi, Atatürk Caddesi No:123',
          'photos': [],
          'videoUrl': null,
          'title': 'Ana şebeke patlağı',
          'description': 'Suyun rengi kahverengi, 2 saattir akmıyor. Acil müdahale gerekiyor.',
          'tags': ['Yol', 'Cadde'],
          'contactPermission': true,
          'contactPhone': '0555 123 45 67',
          'contactName': 'Test Kullanıcı',
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
          'status': 'inprogress',
          'trackingNumber': 'RPT-20241201-0001',
        },
        {
          'id': 'test_2',
          'userId': 'test_user',
          'category': 'Kaçak',
          'priority': 'Orta',
          'location': 'Osmangazi Mahallesi, İnönü Sokak No:45',
          'photos': [],
          'videoUrl': null,
          'title': 'Su kaçağı tespit edildi',
          'description': 'Yol kenarında su birikintisi var. Muhtemelen yer altı boru kaçağı.',
          'tags': ['Sokak', 'Yol'],
          'contactPermission': false,
          'contactPhone': '',
          'contactName': 'Test Kullanıcı',
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
          'status': 'teamassigned',
          'trackingNumber': 'RPT-20241201-0002',
        },
        {
          'id': 'test_3',
          'userId': 'test_user',
          'category': 'Sayaç',
          'priority': 'Düşük',
          'location': 'Yıldırım Mahallesi, Cumhuriyet Caddesi No:78',
          'photos': [],
          'videoUrl': null,
          'title': 'Sayaç arızası',
          'description': 'Sayaç okuma yapılamıyor. Teknik servis gerekiyor.',
          'tags': ['Bina', 'Daire'],
          'contactPermission': true,
          'contactPhone': '0555 123 45 67',
          'contactName': 'Test Kullanıcı',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
          'status': 'pending',
          'trackingNumber': 'RPT-20241201-0003',
        },
      ];

      // Firebase Firestore'a ekle
      final batch = FirebaseFirestore.instance.batch();
      
      for (final reportData in testReports) {
        final docRef = FirebaseFirestore.instance
            .collection('reports')
            .doc(reportData['id'] as String);
        batch.set(docRef, reportData);
      }
      
      await batch.commit();

      // Test tracking verileri oluştur
      final testTracking = [
        FaultTrackingModel(
          faultReportId: 'test_1',
          statusHistory: [
            FaultStatusUpdate(
              id: 'update_1',
              faultReportId: 'test_1',
              status: FaultStatus.pending,
              updatedBy: 'system',
              updatedByName: 'Sistem',
              updatedAt: DateTime.now().subtract(const Duration(days: 2)),
              note: 'Arıza bildirimi alındı ve incelenmeye alındı.',
            ),
            FaultStatusUpdate(
              id: 'update_2',
              faultReportId: 'test_1',
              status: FaultStatus.reviewing,
              updatedBy: 'admin_1',
              updatedByName: 'Ahmet Yılmaz',
              updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 12)),
              note: 'Arıza inceleniyor, ekip hazırlanıyor.',
            ),
            FaultStatusUpdate(
              id: 'update_3',
              faultReportId: 'test_1',
              status: FaultStatus.teamAssigned,
              updatedBy: 'admin_1',
              updatedByName: 'Ahmet Yılmaz',
              updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
              note: 'Teknik ekip atandı, yola çıkıyor.',
            ),
            FaultStatusUpdate(
              id: 'update_4',
              faultReportId: 'test_1',
              status: FaultStatus.onTheWay,
              updatedBy: 'tech_1',
              updatedByName: 'Mehmet Demir',
              updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
              note: 'Yoldayız, 30 dakika içinde varacağız.',
            ),
            FaultStatusUpdate(
              id: 'update_5',
              faultReportId: 'test_1',
              status: FaultStatus.onSite,
              updatedBy: 'tech_1',
              updatedByName: 'Mehmet Demir',
              updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
              note: 'Sahaya vardık, çalışmaya başlıyoruz.',
            ),
            FaultStatusUpdate(
              id: 'update_6',
              faultReportId: 'test_1',
              status: FaultStatus.inProgress,
              updatedBy: 'tech_1',
              updatedByName: 'Mehmet Demir',
              updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
              note: 'Arıza tespit edildi, onarım devam ediyor.',
            ),
          ],
          currentStatus: FaultStatus.onSite,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        FaultTrackingModel(
          faultReportId: 'test_2',
          statusHistory: [
            FaultStatusUpdate(
              id: 'update_7',
              faultReportId: 'test_2',
              status: FaultStatus.pending,
              updatedBy: 'system',
              updatedByName: 'Sistem',
              updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
              note: 'Arıza bildirimi alındı ve incelenmeye alındı.',
            ),
            FaultStatusUpdate(
              id: 'update_8',
              faultReportId: 'test_2',
              status: FaultStatus.reviewing,
              updatedBy: 'admin_1',
              updatedByName: 'Ahmet Yılmaz',
              updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
              note: 'Kaçak tespit edildi, ekip atanıyor.',
            ),
            FaultStatusUpdate(
              id: 'update_9',
              faultReportId: 'test_2',
              status: FaultStatus.teamAssigned,
              updatedBy: 'admin_1',
              updatedByName: 'Ahmet Yılmaz',
              updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
              note: 'Kaçak onarım ekibi atandı.',
            ),
          ],
          currentStatus: FaultStatus.teamAssigned,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        FaultTrackingModel(
          faultReportId: 'test_3',
          statusHistory: [
            FaultStatusUpdate(
              id: 'update_10',
              faultReportId: 'test_3',
              status: FaultStatus.pending,
              updatedBy: 'system',
              updatedByName: 'Sistem',
              updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
              note: 'Arıza bildirimi alındı ve incelenmeye alındı.',
            ),
          ],
          currentStatus: FaultStatus.pending,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      await saveFaultTracking(testTracking);

      // Test bildirimleri oluştur
      await NotificationService.createFaultUpdateNotification(
        faultId: 'test_1',
        faultTitle: 'Ana şebeke patlağı',
        newStatus: 'inprogress',
        updatedBy: 'Mehmet Demir',
      );

      await NotificationService.createFaultUpdateNotification(
        faultId: 'test_2',
        faultTitle: 'Su kaçağı tespit edildi',
        newStatus: 'teamassigned',
        updatedBy: 'Ahmet Yılmaz',
      );
    } catch (e) {
      throw Exception('Test verileri oluşturulurken hata oluştu: $e');
    }
  }

  // Test verilerini temizle
  static Future<void> clearTestData() async {
    try {
      // Firebase Firestore'dan test verilerini sil
      final testIds = ['test_1', 'test_2', 'test_3'];
      final batch = FirebaseFirestore.instance.batch();
      
      for (final id in testIds) {
        final docRef = FirebaseFirestore.instance
            .collection('reports')
            .doc(id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      
      // Local verileri de temizle
      await saveFaultReports([]);
      await saveFaultTracking([]);
      await NotificationService.clearAllNotifications();
    } catch (e) {
      throw Exception('Test verileri temizlenirken hata oluştu: $e');
    }
  }

  // Belirli bir arıza takibini sil
  static Future<void> deleteFaultTracking(String faultReportId) async {
    try {
      // Local storage'dan sil
      final trackingList = await getFaultTrackingList();
      trackingList.removeWhere((tracking) => tracking.faultReportId == faultReportId);
      await saveFaultTracking(trackingList);
    } catch (e) {
      throw Exception('Arıza takibi silinirken hata oluştu: $e');
    }
  }
}
