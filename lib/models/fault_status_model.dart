enum FaultStatus {
  pending('pending', 'Bekliyor', 'Arıza bildirimi alındı, henüz işleme alınmadı'),
  reviewing('reviewing', 'İnceleniyor', 'Arıza inceleniyor ve değerlendiriliyor'),
  teamAssigned('teamAssigned', 'Ekip Atandı', 'Teknik ekip arıza için atandı'),
  onTheWay('onTheWay', 'Yolda', 'Ekip arıza yerine doğru yolda'),
  onSite('onSite', 'Sahada', 'Ekip arıza yerinde çalışmaya başladı'),
  inProgress('in_progress', 'İşlemde', 'Arıza işleme alındı ve çözüm sürecinde'),
  testing('testing', 'Test Ediliyor', 'Onarım tamamlandı, test ediliyor'),
  resolved('resolved', 'Çözüldü', 'Arıza başarıyla çözüldü'),
  completed('completed', 'Tamamlandı', 'Arıza başarıyla çözüldü ve tamamlandı');

  const FaultStatus(this.value, this.title, this.description);

  final String value;
  final String title;
  final String description;

  static FaultStatus fromValue(String value) {
    return FaultStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FaultStatus.pending,
    );
  }

  // Personel paneli için basit kategori
  String get category {
    switch (this) {
      case FaultStatus.pending:
        return 'pending';
      case FaultStatus.reviewing:
      case FaultStatus.teamAssigned:
      case FaultStatus.onTheWay:
      case FaultStatus.onSite:
      case FaultStatus.inProgress:
      case FaultStatus.testing:
      case FaultStatus.resolved:
        return 'in_progress';
      case FaultStatus.completed:
        return 'completed';
    }
  }

  // Personel paneli için basit başlık
  String get categoryTitle {
    switch (this) {
      case FaultStatus.pending:
        return 'Bekliyor';
      case FaultStatus.reviewing:
      case FaultStatus.teamAssigned:
      case FaultStatus.onTheWay:
      case FaultStatus.onSite:
      case FaultStatus.inProgress:
      case FaultStatus.testing:
      case FaultStatus.resolved:
        return 'İşlemde';
      case FaultStatus.completed:
        return 'Tamamlandı';
    }
  }
}

class FaultStatusUpdate {
  final String id;
  final String faultReportId;
  final FaultStatus status;
  final String updatedBy; // Personnel ID
  final String updatedByName; // Personnel name
  final DateTime updatedAt;
  final String? note; // Optional note from personnel
  final String? location; // Current location if needed

  FaultStatusUpdate({
    required this.id,
    required this.faultReportId,
    required this.status,
    required this.updatedBy,
    required this.updatedByName,
    required this.updatedAt,
    this.note,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'faultReportId': faultReportId,
      'status': status.value,
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
      'updatedAt': updatedAt.toIso8601String(),
      'note': note,
      'location': location,
    };
  }

  factory FaultStatusUpdate.fromMap(Map<String, dynamic> map) {
    return FaultStatusUpdate(
      id: map['id'] ?? '',
      faultReportId: map['faultReportId'] ?? '',
      status: FaultStatus.fromValue(map['status'] ?? 'pending'),
      updatedBy: map['updatedBy'] ?? '',
      updatedByName: map['updatedByName'] ?? '',
      updatedAt: DateTime.parse(map['updatedAt']),
      note: map['note'],
      location: map['location'],
    );
  }
}

class FaultTrackingModel {
  final String faultReportId;
  final List<FaultStatusUpdate> statusHistory;
  final FaultStatus currentStatus;
  final DateTime lastUpdated;

  FaultTrackingModel({
    required this.faultReportId,
    required this.statusHistory,
    required this.currentStatus,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'faultReportId': faultReportId,
      'statusHistory': statusHistory.map((update) => update.toMap()).toList(),
      'currentStatus': currentStatus.value,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory FaultTrackingModel.fromMap(Map<String, dynamic> map) {
    final statusHistoryList = (map['statusHistory'] as List?)
        ?.map((item) => FaultStatusUpdate.fromMap(item))
        .toList() ?? [];

    return FaultTrackingModel(
      faultReportId: map['faultReportId'] ?? '',
      statusHistory: statusHistoryList,
      currentStatus: FaultStatus.fromValue(map['currentStatus'] ?? 'pending'),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  FaultTrackingModel copyWith({
    String? faultReportId,
    List<FaultStatusUpdate>? statusHistory,
    FaultStatus? currentStatus,
    DateTime? lastUpdated,
  }) {
    return FaultTrackingModel(
      faultReportId: faultReportId ?? this.faultReportId,
      statusHistory: statusHistory ?? this.statusHistory,
      currentStatus: currentStatus ?? this.currentStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
