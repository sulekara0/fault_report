class AdminModel {
  final String uid;
  final String email;
  final String display; // Firebase'de 'display' olarak kaydediliyor
  final String role; // 'admin' veya 'personel'
  final DateTime createdAt;
  final bool active; // Firebase'de 'active' olarak kaydediliyor
  final String? phone; // Firebase'de 'phone' alanı var
  final String? createdBy; // Firebase'de 'createdBy' alanı var

  AdminModel({
    required this.uid,
    required this.email,
    required this.display,
    required this.role,
    required this.createdAt,
    required this.active,
    this.phone,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display': display,
      'role': role,
      'createdAt': createdAt.toIso8601String(), // JSON serialization için string'e çevir
      'active': active,
      'phone': phone,
      'createdBy': createdBy,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    // createdAt alanını Firestore Timestamp veya String olarak handle et
    DateTime createdAtDateTime;
    if (map['createdAt'] is String) {
      createdAtDateTime = DateTime.parse(map['createdAt']);
    } else if (map['createdAt'] != null) {
      // Firestore Timestamp'i DateTime'a çevir
      final timestamp = map['createdAt'];
      createdAtDateTime = timestamp.toDate();
    } else {
      createdAtDateTime = DateTime.now();
    }

    return AdminModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      display: map['display'] ?? '',
      role: map['role'] ?? 'personel',
      createdAt: createdAtDateTime,
      active: map['active'] ?? true,
      phone: map['phone'],
      createdBy: map['createdBy'],
    );
  }

  AdminModel copyWith({
    String? uid,
    String? email,
    String? display,
    String? role,
    DateTime? createdAt,
    bool? active,
    String? phone,
    String? createdBy,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      display: display ?? this.display,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
      phone: phone ?? this.phone,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // name alanına erişim için getter (geriye uyumluluk için)
  String get name => display;
}
