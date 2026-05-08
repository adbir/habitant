class MaintenanceUpdate {
  final String id;
  final String maintenanceStaffId;
  final String description;
  final List<String> proofPhotoUrls;
  final DateTime completedAt;

  const MaintenanceUpdate({
    required this.id,
    required this.maintenanceStaffId,
    required this.description,
    required this.proofPhotoUrls,
    required this.completedAt,
  });

  MaintenanceUpdate copyWith({
    String? id,
    String? maintenanceStaffId,
    String? description,
    List<String>? proofPhotoUrls,
    DateTime? completedAt,
  }) {
    return MaintenanceUpdate(
      id: id ?? this.id,
      maintenanceStaffId: maintenanceStaffId ?? this.maintenanceStaffId,
      description: description ?? this.description,
      proofPhotoUrls: proofPhotoUrls ?? this.proofPhotoUrls,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory MaintenanceUpdate.fromJson(Map<String, dynamic> json) {
    return MaintenanceUpdate(
      id: json['id'] as String,
      maintenanceStaffId: json['maintenanceStaffId'] as String,
      description: json['description'] as String,
      proofPhotoUrls: List<String>.from(json['proofPhotoUrls'] as List),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'maintenanceStaffId': maintenanceStaffId,
        'description': description,
        'proofPhotoUrls': proofPhotoUrls,
        'completedAt': completedAt.toIso8601String(),
      };
}
