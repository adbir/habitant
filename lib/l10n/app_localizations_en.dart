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
  String get pickHousingTitle => 'Select your housing';

  @override
  String get pickHousingSubtitle =>
      'Choose the housing association you live in';

  @override
  String get pickAddressTitle => 'Select your address';

  @override
  String get pickAddressSubtitle => 'Choose your apartment';

  @override
  String get noAddressesAvailable => 'No available addresses in this housing.';

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
}
