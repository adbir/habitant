import 'issue_comment.dart';
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

  /// Set by admin when the issue requires intervention beyond what
  /// maintenance staff can handle on their own.
  final bool needAssistance;

  /// Alternative contact phone for whoever will be home during the visit
  /// (e.g. a spouse or room mate). Null if the tenant's own number is used.
  final String? alternativeContactPhone;

  final String? maintenanceStaffId;

  /// First name of the assigned maintenance worker, denormalized from the
  /// staff profile so callers don't need a separate lookup.
  final String? assignedToName;
  final List<MaintenanceUpdate> updates;
  final List<IssueComment> comments;
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
    required this.needAssistance,
    this.alternativeContactPhone,
    this.maintenanceStaffId,
    this.assignedToName,
    required this.updates,
    required this.comments,
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
    bool? needAssistance,
    String? alternativeContactPhone,
    String? maintenanceStaffId,
    String? assignedToName,
    List<MaintenanceUpdate>? updates,
    List<IssueComment>? comments,
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
      needAssistance: needAssistance ?? this.needAssistance,
      alternativeContactPhone:
          alternativeContactPhone ?? this.alternativeContactPhone,
      maintenanceStaffId: maintenanceStaffId ?? this.maintenanceStaffId,
      assignedToName: assignedToName ?? this.assignedToName,
      updates: updates ?? this.updates,
      comments: comments ?? this.comments,
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
      needAssistance: json['needAssistance'] as bool? ?? false,
      alternativeContactPhone: json['alternativeContactPhone'] as String?,
      maintenanceStaffId: json['maintenanceStaffId'] as String?,
      assignedToName: json['assignedToName'] as String?,
      updates: (json['updates'] as List<dynamic>? ?? [])
          .map((u) => MaintenanceUpdate.fromJson(u as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => IssueComment.fromJson(c as Map<String, dynamic>))
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
        'needAssistance': needAssistance,
        'alternativeContactPhone': alternativeContactPhone,
        'maintenanceStaffId': maintenanceStaffId,
        'assignedToName': assignedToName,
        'updates': updates.map((u) => u.toJson()).toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
