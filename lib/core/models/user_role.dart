enum UserRole { tenant, admin, maintenanceStaff, housingManager, rootAdmin }

extension UserRoleExtension on UserRole {
  String get label {
    return switch (this) {
      UserRole.tenant => 'Tenant',
      UserRole.admin => 'Admin',
      UserRole.maintenanceStaff => 'Maintenance Staff',
      UserRole.housingManager => 'Housing Manager',
      UserRole.rootAdmin => 'Root Admin',
    };
  }

  bool get isTenant => this == UserRole.tenant;
  bool get isAdmin => this == UserRole.admin;
  bool get isMaintenance => this == UserRole.maintenanceStaff;
  bool get isHousingManager => this == UserRole.housingManager;
  bool get isRootAdmin => this == UserRole.rootAdmin;
  bool get isStaff =>
      isAdmin || isMaintenance || isHousingManager || isRootAdmin;
}
