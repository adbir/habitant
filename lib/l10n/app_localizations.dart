import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Habitant'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Housing administration'**
  String get appTagline;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @createAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountLink;

  /// No description provided for @errorEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get errorEmptyFields;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your email has not been confirmed yet.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @goToVerification.
  ///
  /// In en, this message translates to:
  /// **'Confirm email'**
  String get goToVerification;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get phoneLabel;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupTitle;

  /// No description provided for @errorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get errorPasswordMismatch;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get errorPasswordTooShort;

  /// No description provided for @errorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailTaken;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String verifyEmailSentTo(String email);

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t right. Please try again.'**
  String get errorInvalidCode;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginLink;

  /// No description provided for @issueStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get issueStatusPending;

  /// No description provided for @issueStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get issueStatusAssigned;

  /// No description provided for @issueStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get issueStatusInProgress;

  /// No description provided for @issueStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get issueStatusCompleted;

  /// No description provided for @issueStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get issueStatusRejected;

  /// No description provided for @needsAssistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs assistance'**
  String get needsAssistanceLabel;

  /// No description provided for @awaitingInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting assignment'**
  String get awaitingInvitationTitle;

  /// No description provided for @awaitingInvitationBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created. When your housing association sends you an invitation link, use it to connect your apartment.'**
  String get awaitingInvitationBody;

  /// No description provided for @formerTenantBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve moved out'**
  String get formerTenantBannerTitle;

  /// No description provided for @formerTenantBannerBody.
  ///
  /// In en, this message translates to:
  /// **'You are no longer linked to an address. Your past issues are shown below.'**
  String get formerTenantBannerBody;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminDashboardTitle;

  /// No description provided for @adminHousingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Housing associations'**
  String get adminHousingsSectionTitle;

  /// No description provided for @adminStatTotalAddresses.
  ///
  /// In en, this message translates to:
  /// **'Total units'**
  String get adminStatTotalAddresses;

  /// No description provided for @adminStatVacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get adminStatVacant;

  /// No description provided for @adminStatOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get adminStatOccupied;

  /// No description provided for @adminOpenIssues.
  ///
  /// In en, this message translates to:
  /// **'{count} open issues'**
  String adminOpenIssues(int count);

  /// No description provided for @adminNoHousings.
  ///
  /// In en, this message translates to:
  /// **'No housing associations'**
  String get adminNoHousings;

  /// No description provided for @housingAddressesSection.
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
  String get housingAddressesSection;

  /// No description provided for @housingOpenIssuesSection.
  ///
  /// In en, this message translates to:
  /// **'OPEN ISSUES'**
  String get housingOpenIssuesSection;

  /// No description provided for @housingNoOpenIssues.
  ///
  /// In en, this message translates to:
  /// **'No open issues'**
  String get housingNoOpenIssues;

  /// No description provided for @addressStatusOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get addressStatusOccupied;

  /// No description provided for @addressStatusVacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get addressStatusVacant;

  /// No description provided for @addressStatusInvitationPending.
  ///
  /// In en, this message translates to:
  /// **'Invitation pending'**
  String get addressStatusInvitationPending;

  /// No description provided for @addressInviteTenant.
  ///
  /// In en, this message translates to:
  /// **'Invite tenant'**
  String get addressInviteTenant;

  /// No description provided for @addressCancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get addressCancelInvitation;

  /// No description provided for @addressCancelInvitationFull.
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation'**
  String get addressCancelInvitationFull;

  /// No description provided for @addressTenantsSection.
  ///
  /// In en, this message translates to:
  /// **'Registered tenants'**
  String get addressTenantsSection;

  /// No description provided for @addressNoTenants.
  ///
  /// In en, this message translates to:
  /// **'No registered tenants'**
  String get addressNoTenants;

  /// No description provided for @addressInviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get addressInviteExpires;

  /// No description provided for @addressVacantHint.
  ///
  /// In en, this message translates to:
  /// **'No active tenant'**
  String get addressVacantHint;

  /// No description provided for @addressDetailHistorySection.
  ///
  /// In en, this message translates to:
  /// **'Tenancy history'**
  String get addressDetailHistorySection;

  /// No description provided for @addressDetailMovedIn.
  ///
  /// In en, this message translates to:
  /// **'Moved in'**
  String get addressDetailMovedIn;

  /// No description provided for @addressDetailMovedOut.
  ///
  /// In en, this message translates to:
  /// **'Moved out'**
  String get addressDetailMovedOut;

  /// No description provided for @addressDetailCurrentTenant.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get addressDetailCurrentTenant;

  /// No description provided for @addressDetailNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No previous tenants on record'**
  String get addressDetailNoHistory;

  /// No description provided for @addressDetailPreviewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick view'**
  String get addressDetailPreviewTooltip;

  /// No description provided for @addressDetailIssueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} issue} other{{count} issues}}'**
  String addressDetailIssueCount(int count);

  /// No description provided for @issueHandledBy.
  ///
  /// In en, this message translates to:
  /// **'Handled by {name}'**
  String issueHandledBy(String name);

  /// No description provided for @inviteLinkCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get inviteLinkCreatedTitle;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @myIssues.
  ///
  /// In en, this message translates to:
  /// **'My issues'**
  String get myIssues;

  /// No description provided for @noIssuesYet.
  ///
  /// In en, this message translates to:
  /// **'No issues reported'**
  String get noIssuesYet;

  /// No description provided for @noIssuesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to report a problem in your home.'**
  String get noIssuesYetSubtitle;

  /// No description provided for @reportIssueTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssueTooltip;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetry;

  /// No description provided for @errorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your data. Please try again.'**
  String get errorLoadFailed;

  /// No description provided for @reportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssueTitle;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem in detail...'**
  String get descriptionHint;

  /// No description provided for @submitIssueButton.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitIssueButton;

  /// No description provided for @alternativeContactHint.
  ///
  /// In en, this message translates to:
  /// **'If we need to talk to someone else than you about the issue, please leave their phone number below.'**
  String get alternativeContactHint;

  /// No description provided for @alternativeContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Alternative phone number (optional)'**
  String get alternativeContactPhoneLabel;

  /// No description provided for @errorDescriptionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please describe the problem.'**
  String get errorDescriptionEmpty;

  /// No description provided for @errorPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'One or more photos failed to upload. Remove them and try again.'**
  String get errorPhotoUploadFailed;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get maintenanceTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noIssuesFound.
  ///
  /// In en, this message translates to:
  /// **'No issues'**
  String get noIssuesFound;

  /// No description provided for @issueDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueDetailTitle;

  /// No description provided for @addressSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get addressSection;

  /// No description provided for @alternativePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Alternative contact'**
  String get alternativePhoneLabel;

  /// No description provided for @commentsSection.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsSection;

  /// No description provided for @maintenanceUpdatesSection.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get maintenanceUpdatesSection;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @noUpdatesYet.
  ///
  /// In en, this message translates to:
  /// **'No updates yet'**
  String get noUpdatesYet;

  /// No description provided for @internalCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get internalCommentLabel;

  /// No description provided for @publicCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicCommentLabel;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get commentHint;

  /// No description provided for @internalNoteToggle.
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get internalNoteToggle;

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// No description provided for @logoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTooltip;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up access'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited to live at:'**
  String get joinSubtitle;

  /// No description provided for @joinContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get joinContinueButton;

  /// No description provided for @joinAcceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get joinAcceptButton;

  /// No description provided for @joinInvalidTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid invitation link'**
  String get joinInvalidTokenTitle;

  /// No description provided for @joinInvalidTokenBody.
  ///
  /// In en, this message translates to:
  /// **'This link has expired or is invalid. Contact your housing administrator.'**
  String get joinInvalidTokenBody;

  /// No description provided for @joinGoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to login'**
  String get joinGoToLogin;

  /// No description provided for @inviteCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create invitation'**
  String get inviteCreateTitle;

  /// No description provided for @invitePickHousing.
  ///
  /// In en, this message translates to:
  /// **'Select housing'**
  String get invitePickHousing;

  /// No description provided for @invitePickAddress.
  ///
  /// In en, this message translates to:
  /// **'Select address'**
  String get invitePickAddress;

  /// No description provided for @inviteFilterAddresses.
  ///
  /// In en, this message translates to:
  /// **'Search address...'**
  String get inviteFilterAddresses;

  /// No description provided for @inviteNoAddressesFound.
  ///
  /// In en, this message translates to:
  /// **'No addresses found'**
  String get inviteNoAddressesFound;

  /// No description provided for @inviteCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get inviteCreatedTitle;

  /// No description provided for @inviteCreatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share this link with the tenant:'**
  String get inviteCreatedSubtitle;

  /// No description provided for @inviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get inviteCopyLink;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get inviteLinkCopied;

  /// No description provided for @inviteCreateAnother.
  ///
  /// In en, this message translates to:
  /// **'Create another invitation'**
  String get inviteCreateAnother;

  /// No description provided for @themeToggleToLight.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeToggleToLight;

  /// No description provided for @themeToggleToDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeToggleToDark;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileAccountSection.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get profileAccountSection;

  /// No description provided for @profileAddressSection.
  ///
  /// In en, this message translates to:
  /// **'YOUR ADDRESS'**
  String get profileAddressSection;

  /// No description provided for @profileNoAddress.
  ///
  /// In en, this message translates to:
  /// **'Not linked to an address'**
  String get profileNoAddress;

  /// No description provided for @profileClaimInvitation.
  ///
  /// In en, this message translates to:
  /// **'Claim invitation'**
  String get profileClaimInvitation;

  /// No description provided for @claimInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter invitation'**
  String get claimInvitationTitle;

  /// No description provided for @claimInvitationFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation link or token'**
  String get claimInvitationFieldLabel;

  /// No description provided for @claimInvitationFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Paste link or bare token'**
  String get claimInvitationFieldHint;

  /// No description provided for @claimInvitationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get claimInvitationContinue;

  /// No description provided for @claimInvitationEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an invitation link or token'**
  String get claimInvitationEmptyError;

  /// No description provided for @claimInvitationInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Could not find a valid token in the provided link'**
  String get claimInvitationInvalidError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['da', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
