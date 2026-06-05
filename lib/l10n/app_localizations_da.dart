// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appName => 'Habitant';

  @override
  String get appTagline => 'Boligadministration';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Adgangskode';

  @override
  String get loginButton => 'Log ind';

  @override
  String get createAccountLink => 'Opret konto';

  @override
  String get errorEmptyFields => 'Udfyld venligst alle felter.';

  @override
  String get errorInvalidCredentials => 'Forkert e-mail eller adgangskode.';

  @override
  String get errorEmailNotConfirmed => 'Din e-mail er ikke bekræftet endnu.';

  @override
  String get errorRateLimited => 'For mange forsøg. Vent lidt og prøv igen.';

  @override
  String get goToVerification => 'Bekræft e-mail';

  @override
  String get errorGeneric => 'Noget gik galt. Prøv venligst igen.';

  @override
  String get nextButton => 'Næste';

  @override
  String get confirmPasswordLabel => 'Bekræft adgangskode';

  @override
  String get phoneLabel => 'Telefonnummer (valgfrit)';

  @override
  String get signupTitle => 'Opret konto';

  @override
  String get errorPasswordMismatch => 'Adgangskoderne stemmer ikke overens.';

  @override
  String get errorPasswordTooShort => 'Adgangskoden skal være mindst 8 tegn.';

  @override
  String get errorEmailTaken =>
      'Der findes allerede en konto med denne e-mail.';

  @override
  String get verifyEmailTitle => 'Tjek din e-mail';

  @override
  String verifyEmailSentTo(String email) {
    return 'Vi har sendt en 6-cifret kode til $email';
  }

  @override
  String get verifyButton => 'Bekræft';

  @override
  String get resendCode => 'Send kode igen';

  @override
  String get errorInvalidCode => 'Koden er forkert. Prøv venligst igen.';

  @override
  String get alreadyHaveAccount => 'Har du allerede en konto?';

  @override
  String get loginLink => 'Log ind';

  @override
  String get issueStatusPending => 'Afventer';

  @override
  String get issueStatusAssigned => 'Tildelt';

  @override
  String get issueStatusInProgress => 'I gang';

  @override
  String get issueStatusCompleted => 'Afsluttet';

  @override
  String get issueStatusRejected => 'Afvist';

  @override
  String get needsAssistanceLabel => 'Kræver hjælp';

  @override
  String get awaitingInvitationTitle => 'Afventer tildeling';

  @override
  String get awaitingInvitationBody =>
      'Din konto er oprettet. Når din boligforening sender dig et invitationslink, kan du bruge det til at tilknytte din bolig.';

  @override
  String get adminDashboardTitle => 'Overblik';

  @override
  String get adminHousingsSectionTitle => 'Boligforeninger';

  @override
  String get adminStatTotalAddresses => 'Boliger i alt';

  @override
  String get adminStatVacant => 'Ledige';

  @override
  String get adminStatOccupied => 'Beboede';

  @override
  String adminOpenIssues(int count) {
    return '$count åbne sager';
  }

  @override
  String get adminNoHousings => 'Ingen boligforeninger';

  @override
  String get housingAddressesSection => 'BOLIGER';

  @override
  String get housingOpenIssuesSection => 'ÅBNE SAGER';

  @override
  String get housingNoOpenIssues => 'Ingen åbne sager';

  @override
  String get addressStatusOccupied => 'Beboet';

  @override
  String get addressStatusVacant => 'Ledig';

  @override
  String get addressStatusInvitationPending => 'Invitation afventer';

  @override
  String get addressInviteTenant => 'Inviter lejer';

  @override
  String get addressCancelInvitation => 'Annuller';

  @override
  String get addressCancelInvitationFull => 'Annuller invitation';

  @override
  String get addressTenantsSection => 'Registrerede lejere';

  @override
  String get addressNoTenants => 'Ingen registrerede lejere';

  @override
  String get addressInviteExpires => 'Udløber';

  @override
  String get addressVacantHint => 'Ingen aktiv lejer';

  @override
  String get addressDetailHistorySection => 'Lejemålshistorik';

  @override
  String get addressDetailMovedIn => 'Indflyttet';

  @override
  String get addressDetailMovedOut => 'Fraflyttet';

  @override
  String get addressDetailCurrentTenant => 'Aktuel';

  @override
  String get addressDetailNoHistory => 'Ingen registrerede tidligere lejere';

  @override
  String get addressDetailPreviewTooltip => 'Hurtigt overblik';

  @override
  String addressDetailIssueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sager',
      one: '$count sag',
    );
    return '$_temp0';
  }

  @override
  String issueHandledBy(String name) {
    return 'Behandlet af $name';
  }

  @override
  String get inviteLinkCreatedTitle => 'Invitation oprettet';

  @override
  String get cancelButton => 'Annuller';

  @override
  String get confirmButton => 'Bekræft';

  @override
  String get myIssues => 'Mine meldinger';

  @override
  String get noIssuesYet => 'Ingen meldinger endnu';

  @override
  String get noIssuesYetSubtitle =>
      'Tryk på knappen nedenfor for at melde et problem i din bolig.';

  @override
  String get reportIssueTooltip => 'Meld problem';

  @override
  String get today => 'I dag';

  @override
  String get yesterday => 'I går';

  @override
  String daysAgo(int count) {
    return 'For $count dage siden';
  }

  @override
  String get errorRetry => 'Prøv igen';

  @override
  String get errorLoadFailed =>
      'Kunne ikke hente dine data. Prøv venligst igen.';

  @override
  String get reportIssueTitle => 'Meld problem';

  @override
  String get descriptionLabel => 'Beskrivelse';

  @override
  String get descriptionHint => 'Beskriv problemet i detaljer...';

  @override
  String get submitIssueButton => 'Send melding';

  @override
  String get alternativeContactHint =>
      'Hvis vi skal tale med en anden end dig om problemet, bedes du efterlade vedkommendes telefonnummer nedenfor.';

  @override
  String get alternativeContactPhoneLabel =>
      'Alternativt telefonnummer (valgfrit)';

  @override
  String get errorDescriptionEmpty => 'Beskriv venligst problemet.';

  @override
  String get errorPhotoUploadFailed =>
      'Et eller flere billeder kunne ikke uploades. Fjern dem og prøv igen.';

  @override
  String get maintenanceTitle => 'Sager';

  @override
  String get filterAll => 'Alle';

  @override
  String get noIssuesFound => 'Ingen sager';

  @override
  String get issueDetailTitle => 'Sag';

  @override
  String get addressSection => 'Adresse';

  @override
  String get alternativePhoneLabel => 'Alternativ kontakt';

  @override
  String get commentsSection => 'Kommentarer';

  @override
  String get maintenanceUpdatesSection => 'Opdateringer';

  @override
  String get noCommentsYet => 'Ingen kommentarer endnu';

  @override
  String get noUpdatesYet => 'Ingen opdateringer endnu';

  @override
  String get internalCommentLabel => 'Intern';

  @override
  String get publicCommentLabel => 'Offentlig';

  @override
  String get commentHint => 'Skriv en kommentar...';

  @override
  String get internalNoteToggle => 'Internt notat';

  @override
  String get sendButton => 'Send';

  @override
  String get logoutTooltip => 'Log ud';

  @override
  String get joinTitle => 'Opret adgang';

  @override
  String get joinSubtitle => 'Du er inviteret til at bo på:';

  @override
  String get joinContinueButton => 'Opret konto';

  @override
  String get joinAcceptButton => 'Accepter invitation';

  @override
  String get joinInvalidTokenTitle => 'Ugyldigt invitationslink';

  @override
  String get joinInvalidTokenBody =>
      'Dette link er udløbet eller ugyldigt. Kontakt din boligadministrator.';

  @override
  String get joinGoToLogin => 'Gå til login';

  @override
  String get inviteCreateTitle => 'Opret invitation';

  @override
  String get invitePickHousing => 'Vælg boligforening';

  @override
  String get invitePickAddress => 'Vælg adresse';

  @override
  String get inviteFilterAddresses => 'Søg adresse...';

  @override
  String get inviteNoAddressesFound => 'Ingen adresser matcher søgningen';

  @override
  String get inviteCreatedTitle => 'Invitation oprettet';

  @override
  String get inviteCreatedSubtitle => 'Del dette link med lejeren:';

  @override
  String get inviteCopyLink => 'Kopiér link';

  @override
  String get inviteLinkCopied => 'Link kopieret';

  @override
  String get inviteCreateAnother => 'Opret ny invitation';

  @override
  String get themeToggleToLight => 'Lyst tema';

  @override
  String get themeToggleToDark => 'Mørkt tema';
}
