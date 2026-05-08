import 'maintenance_update.dart';

enum IssueStatus {
  pending,
  assigned,
  inProgress,
  completed,
  rejected,
}

extension IssueStatusExtension on IssueStatus {
  String get label => switch (this) {
        IssueStatus.pending => 'Pending',
        IssueStatus.assigned => 'Assigned',
        IssueStatus.inProgress => 'In Progress',
        IssueStatus.completed => 'Completed',
        IssueStatus.rejected => 'Rejected',
      };
}

class Issue {
  final String id;
  final String tenantId;
  final String addressId;
  final String housingId;
  final String description;
  final List<String> photoUrls;
  final IssueStatus status;
  final bool needsOutsideHelp;
  final bool tooComplexForMaintenance;
  final String? maintenanceStaffId;
  final List<MaintenanceUpdate> updates;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Issue({
    required this.id,
    required this.tenantId,
    required this.addressId,
    required this.housingId,
    required this.description,
    required this.photoUrls,
    required this.status,
    required this.needsOutsideHelp,
    required this.tooComplexForMaintenance,
    this.maintenanceStaffId,
    required this.updates,
    required this.createdAt,
    this.updatedAt,
  });

  Issue copyWith({
    String? id,
    String? tenantId,
    String? addressId,
    String? housingId,
    String? description,
    List<String>? photoUrls,
    IssueStatus? status,
    bool? needsOutsideHelp,
    bool? tooComplexForMaintenance,
    String? maintenanceStaffId,
    List<MaintenanceUpdate>? updates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Issue(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      addressId: addressId ?? this.addressId,
      housingId: housingId ?? this.housingId,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      needsOutsideHelp: needsOutsideHelp ?? this.needsOutsideHelp,
      tooComplexForMaintenance:
          tooComplexForMaintenance ?? this.tooComplexForMaintenance,
      maintenanceStaffId: maintenanceStaffId ?? this.maintenanceStaffId,
      updates: updates ?? this.updates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      addressId: json['addressId'] as String,
      housingId: json['housingId'] as String,
      description: json['description'] as String,
      photoUrls: List<String>.from(json['photoUrls'] as List? ?? []),
      status: IssueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IssueStatus.pending,
      ),
      needsOutsideHelp: json['needsOutsideHelp'] as bool? ?? false,
      tooComplexForMaintenance:
          json['tooComplexForMaintenance'] as bool? ?? false,
      maintenanceStaffId: json['maintenanceStaffId'] as String?,
      updates: (json['updates'] as List<dynamic>? ?? [])
          .map((u) => MaintenanceUpdate.fromJson(u as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'addressId': addressId,
        'housingId': housingId,
        'description': description,
        'photoUrls': photoUrls,
        'status': status.name,
        'needsOutsideHelp': needsOutsideHelp,
        'tooComplexForMaintenance': tooComplexForMaintenance,
        'maintenanceStaffId': maintenanceStaffId,
        'updates': updates.map((u) => u.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
