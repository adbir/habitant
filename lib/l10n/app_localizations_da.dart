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
  String get pickHousingTitle => 'Vælg din boligforening';

  @override
  String get pickHousingSubtitle => 'Vælg den boligforening du bor i';

  @override
  String get pickAddressTitle => 'Vælg din adresse';

  @override
  String get pickAddressSubtitle => 'Vælg din lejlighed';

  @override
  String get noAddressesAvailable =>
      'Ingen ledige adresser i denne boligforening.';

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
}
