class FaultReportModel {
  final String id;
  final String userId;
  final String category;
  final String priority;
  final String location;
  final List<String> photos;
  final String? videoUrl;
  final String title;
  final String description;
  final List<String> tags;
  final bool contactPermission;
  final String contactPhone;
  final String contactName;
  final DateTime createdAt;
  final String status;
  final String trackingNumber;
  final String? assignedTo; // Atanan personel ID'si
  final String? assignedByName; // Atanan personel adı
  final DateTime? assignedAt; // Atama tarihi

  FaultReportModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.priority,
    required this.location,
    required this.photos,
    this.videoUrl,
    required this.title,
    required this.description,
    required this.tags,
    required this.contactPermission,
    required this.contactPhone,
    required this.contactName,
    required this.createdAt,
    required this.status,
    required this.trackingNumber,
    this.assignedTo,
    this.assignedByName,
    this.assignedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'priority': priority,
      'location': location,
      'photos': photos,
      'videoUrl': videoUrl,
      'title': title,
      'description': description,
      'tags': tags,
      'contactPermission': contactPermission,
      'contactPhone': contactPhone,
      'contactName': contactName,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'trackingNumber': trackingNumber,
      'assignedTo': assignedTo,
      'assignedByName': assignedByName,
      'assignedAt': assignedAt?.toIso8601String(),
    };
  }

  factory FaultReportModel.fromMap(Map<String, dynamic> map) {
    return FaultReportModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? '',
      location: map['location'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      videoUrl: map['videoUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      contactPermission: map['contactPermission'] ?? false,
      contactPhone: map['contactPhone'] ?? '',
      contactName: map['contactName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'pending',
      trackingNumber: map['trackingNumber'] ?? '',
      assignedTo: map['assignedTo'],
      assignedByName: map['assignedByName'],
      assignedAt: map['assignedAt'] != null ? DateTime.parse(map['assignedAt']) : null,
    );
  }

  FaultReportModel copyWith({
    String? id,
    String? userId,
    String? category,
    String? priority,
    String? location,
    List<String>? photos,
    String? videoUrl,
    String? title,
    String? description,
    List<String>? tags,
    bool? contactPermission,
    String? contactPhone,
    String? contactName,
    DateTime? createdAt,
    String? status,
    String? trackingNumber,
    String? assignedTo,
    String? assignedByName,
    DateTime? assignedAt,
  }) {
    return FaultReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      videoUrl: videoUrl ?? this.videoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      contactPermission: contactPermission ?? this.contactPermission,
      contactPhone: contactPhone ?? this.contactPhone,
      contactName: contactName ?? this.contactName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedByName: assignedByName ?? this.assignedByName,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }
}

