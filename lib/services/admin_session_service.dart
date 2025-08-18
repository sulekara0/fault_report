import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/admin_model.dart';

class AdminSessionService {
  static const String _adminSessionKey = 'admin_session';
  static const String _personnelListKey = 'personnel_list';

  // Admin session'ını kaydet
  static Future<void> saveAdminSession(AdminModel admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminSessionKey, jsonEncode(admin.toMap()));
  }

  // Admin session'ını getir
  static Future<AdminModel?> getAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_adminSessionKey);
      if (sessionData != null) {
        final Map<String, dynamic> adminMap = jsonDecode(sessionData);
        return AdminModel.fromMap(adminMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Admin session'ını temizle
  static Future<void> clearAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminSessionKey);
    await prefs.remove(_personnelListKey);
  }

  // Personel listesini kaydet
  static Future<void> savePersonnelList(List<AdminModel> personnelList) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> personnelJsonList = personnelList
        .map((personnel) => jsonEncode(personnel.toMap()))
        .toList();
    await prefs.setStringList(_personnelListKey, personnelJsonList);
  }

  // Personel listesini getir
  static Future<List<AdminModel>> getPersonnelList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? personnelJsonList = prefs.getStringList(_personnelListKey);
      if (personnelJsonList != null) {
        return personnelJsonList
            .map((json) => AdminModel.fromMap(jsonDecode(json)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Admin session'ı var mı kontrol et
  static Future<bool> hasAdminSession() async {
    final admin = await getAdminSession();
    return admin != null;
  }
}
