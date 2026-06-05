// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Habitant';

  @override
  String get appTagline => 'Housing administration';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Log in';

  @override
  String get createAccountLink => 'Create account';

  @override
  String get errorEmptyFields => 'Please fill in all fields.';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errorEmailNotConfirmed => 'Your email has not been confirmed yet.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get goToVerification => 'Confirm email';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get nextButton => 'Next';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get phoneLabel => 'Phone number (optional)';

  @override
  String get signupTitle => 'Create account';

  @override
  String get errorPasswordMismatch => 'Passwords do not match.';

  @override
  String get errorPasswordTooShort => 'Password must be at least 8 characters.';

  @override
  String get errorEmailTaken => 'An account with this email already exists.';

  @override
  String get verifyEmailTitle => 'Check your email';

  @override
  String verifyEmailSentTo(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get verifyButton => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get errorInvalidCode => 'That code isn\'t right. Please try again.';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Log in';

  @override
  String get issueStatusPending => 'Pending';

  @override
  String get issueStatusAssigned => 'Assigned';

  @override
  String get issueStatusInProgress => 'In progress';

  @override
  String get issueStatusCompleted => 'Completed';

  @override
  String get issueStatusRejected => 'Rejected';

  @override
  String get needsAssistanceLabel => 'Needs assistance';

  @override
  String get awaitingInvitationTitle => 'Awaiting assignment';

  @override
  String get awaitingInvitationBody =>
      'Your account has been created. When your housing association sends you an invitation link, use it to connect your apartment.';

  @override
  String get adminDashboardTitle => 'Overview';

  @override
  String get adminHousingsSectionTitle => 'Housing associations';

  @override
  String get adminStatTotalAddresses => 'Total units';

  @override
  String get adminStatVacant => 'Vacant';

  @override
  String get adminStatOccupied => 'Occupied';

  @override
  String adminOpenIssues(int count) {
    return '$count open issues';
  }

  @override
  String get adminNoHousings => 'No housing associations';

  @override
  String get housingAddressesSection => 'UNITS';

  @override
  String get housingOpenIssuesSection => 'OPEN ISSUES';

  @override
  String get housingNoOpenIssues => 'No open issues';

  @override
  String get addressStatusOccupied => 'Occupied';

  @override
  String get addressStatusVacant => 'Vacant';

  @override
  String get addressStatusInvitationPending => 'Invitation pending';

  @override
  String get addressInviteTenant => 'Invite tenant';

  @override
  String get addressCancelInvitation => 'Cancel';

  @override
  String get addressCancelInvitationFull => 'Cancel invitation';

  @override
  String get addressTenantsSection => 'Registered tenants';

  @override
  String get addressNoTenants => 'No registered tenants';

  @override
  String get addressInviteExpires => 'Expires';

  @override
  String get addressVacantHint => 'No active tenant';

  @override
  String get addressDetailHistorySection => 'Tenancy history';

  @override
  String get addressDetailMovedIn => 'Moved in';

  @override
  String get addressDetailMovedOut => 'Moved out';

  @override
  String get addressDetailCurrentTenant => 'Current';

  @override
  String get addressDetailNoHistory => 'No previous tenants on record';

  @override
  String get addressDetailPreviewTooltip => 'Quick view';

  @override
  String addressDetailIssueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count issues',
      one: '$count issue',
    );
    return '$_temp0';
  }

  @override
  String issueHandledBy(String name) {
    return 'Handled by $name';
  }

  @override
  String get inviteLinkCreatedTitle => 'Invitation created';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get myIssues => 'My issues';

  @override
  String get noIssuesYet => 'No issues reported';

  @override
  String get noIssuesYetSubtitle =>
      'Tap the button below to report a problem in your home.';

  @override
  String get reportIssueTooltip => 'Report issue';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get errorRetry => 'Retry';

  @override
  String get errorLoadFailed => 'Could not load your data. Please try again.';

  @override
  String get reportIssueTitle => 'Report issue';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Describe the problem in detail...';

  @override
  String get submitIssueButton => 'Submit report';

  @override
  String get alternativeContactHint =>
      'If we need to talk to someone else than you about the issue, please leave their phone number below.';

  @override
  String get alternativeContactPhoneLabel =>
      'Alternative phone number (optional)';

  @override
  String get errorDescriptionEmpty => 'Please describe the problem.';

  @override
  String get errorPhotoUploadFailed =>
      'One or more photos failed to upload. Remove them and try again.';

  @override
  String get maintenanceTitle => 'Issues';

  @override
  String get filterAll => 'All';

  @override
  String get noIssuesFound => 'No issues';

  @override
  String get issueDetailTitle => 'Issue';

  @override
  String get addressSection => 'Location';

  @override
  String get alternativePhoneLabel => 'Alternative contact';

  @override
  String get commentsSection => 'Comments';

  @override
  String get maintenanceUpdatesSection => 'Updates';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get noUpdatesYet => 'No updates yet';

  @override
  String get internalCommentLabel => 'Internal';

  @override
  String get publicCommentLabel => 'Public';

  @override
  String get commentHint => 'Write a comment...';

  @override
  String get internalNoteToggle => 'Internal note';

  @override
  String get sendButton => 'Send';

  @override
  String get logoutTooltip => 'Log out';

  @override
  String get joinTitle => 'Set up access';

  @override
  String get joinSubtitle => 'You\'ve been invited to live at:';

  @override
  String get joinContinueButton => 'Create account';

  @override
  String get joinAcceptButton => 'Accept invitation';

  @override
  String get joinInvalidTokenTitle => 'Invalid invitation link';

  @override
  String get joinInvalidTokenBody =>
      'This link has expired or is invalid. Contact your housing administrator.';

  @override
  String get joinGoToLogin => 'Go to login';

  @override
  String get inviteCreateTitle => 'Create invitation';

  @override
  String get invitePickHousing => 'Select housing';

  @override
  String get invitePickAddress => 'Select address';

  @override
  String get inviteFilterAddresses => 'Search address...';

  @override
  String get inviteNoAddressesFound => 'No addresses found';

  @override
  String get inviteCreatedTitle => 'Invitation created';

  @override
  String get inviteCreatedSubtitle => 'Share this link with the tenant:';

  @override
  String get inviteCopyLink => 'Copy link';

  @override
  String get inviteLinkCopied => 'Link copied';

  @override
  String get inviteCreateAnother => 'Create another invitation';

  @override
  String get themeToggleToLight => 'Light theme';

  @override
  String get themeToggleToDark => 'Dark theme';
}
