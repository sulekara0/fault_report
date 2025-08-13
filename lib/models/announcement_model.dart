class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? validUntil;
  final bool isActive;
  final String? location; // Hangi bölge için geçerli
  final String priority; // 'normal', 'important', 'urgent'

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.createdAt,
    this.validUntil,
    required this.isActive,
    this.location,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'isActive': isActive,
      'location': location,
      'priority': priority,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      validUntil: map['validUntil'] != null ? DateTime.parse(map['validUntil']) : null,
      isActive: map['isActive'] ?? true,
      location: map['location'],
      priority: map['priority'] ?? 'normal',
    );
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    String? createdBy,
    DateTime? createdAt,
    DateTime? validUntil,
    bool? isActive,
    String? location,
    String? priority,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
      priority: priority ?? this.priority,
    );
  }
}
