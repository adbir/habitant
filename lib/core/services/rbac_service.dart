import '../models/user_role.dart';

class RbacService {
  /// Check if user role can access admin dashboard/features
  bool canAccessAdmin(UserRole role) {
    return role.isAdmin || role.isHousingManager || role.isRootAdmin;
  }

  /// Check if user role can perform maintenance tasks
  bool canPerformMaintenance(UserRole role) {
    return role.isMaintenance || role.isRootAdmin;
  }

  /// Check if user role can view analytics
  bool canViewAnalytics(UserRole role) {
    return role.isHousingManager || role.isRootAdmin;
  }

  /// Check if user role can mark issues for outside help
  bool canMarkForOutsideHelp(UserRole role) {
    return role.isAdmin || role.isRootAdmin;
  }

  /// Check if user role can mark tenant as moved out
  bool canMarkTenantMovedOut(UserRole role) {
    return role.isAdmin || role.isRootAdmin;
  }

  /// Check if user is a tenant
  bool isTenant(UserRole role) {
    return role.isTenant;
  }

  /// Check if user is staff (admin, maintenance, manager, or root)
  bool isStaff(UserRole role) {
    return role.isStaff;
  }

  /// Check if user can upload proof photos (maintenance staff)
  bool canUploadProofPhotos(UserRole role) {
    return role.isMaintenance || role.isRootAdmin;
  }

  /// Check if user can report issues (tenants)
  bool canReportIssues(UserRole role) {
    return role.isTenant;
  }
}
