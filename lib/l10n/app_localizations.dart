import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('lib/l10n/app_${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Convenience getters for common strings
  String get appTitle => translate('appTitle');
  String get home => translate('home');
  String get study => translate('study');
  String get myWords => translate('myWords');
  String get quiz => translate('quiz');
  String get more => translate('more');
  String get settings => translate('settings');
  String get language => translate('language');
  String get selectLanguage => translate('selectLanguage');
  String get english => translate('english');
  String get chinese => translate('chinese');
  String get welcome => translate('welcome');
  String get guest => translate('guest');
  String get login => translate('login');
  String get logout => translate('logout');
  String get profile => translate('profile');
  String get history => translate('history');
  String get rewards => translate('rewards');
  String get studySettings => translate('studySettings');
  String get studyWordsSource => translate('studyWordsSource');
  String get numStudyWords => translate('numStudyWords');
  String get spellRepeatCount => translate('spellRepeatCount');
  String get voiceSettings => translate('voiceSettings');
  String get selectVoice => translate('selectVoice');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get ok => translate('ok');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get settingsSaved => translate('settingsSaved');
  String get pleaseLoginToSaveSettings => translate('pleaseLoginToSaveSettings');
  String get failedToLoadSettings => translate('failedToLoadSettings');
  String get failedToSaveSettings => translate('failedToSaveSettings');
  String get userAccount => translate('userAccount');
  String get rewardsRedeem => translate('rewardsRedeem');
  String get loginHistory => translate('loginHistory');
  String get studyHistory => translate('studyHistory');
  String get studySuggestions => translate('studySuggestions');
  String get leaderboard => translate('leaderboard');
  String get legal => translate('legal');
  String get userManual => translate('userManual');
  String get suggestionsTestimonials => translate('suggestionsTestimonials');
  String get sendFeedback => translate('sendFeedback');
  String get loginRequired => translate('loginRequired');
  String get chineseVoiceSelection => translate('chineseVoiceSelection');
  String get selectChineseVoice => translate('selectChineseVoice');
  String get saveSettings => translate('saveSettings');
  String get goToLogin => translate('goToLogin');
  String get pleaseLogInToCustomizeSettings => translate('pleaseLogInToCustomizeSettings');
  
  // Home page
  String get youHavePoints => translate('youHavePoints');
  String get selectTag => translate('selectTag');
  String get showMeTheWord => translate('showMeTheWord');
  String get previous => translate('previous');
  String get play => translate('play');
  String get next => translate('next');
  String get pleaseAddWords => translate('pleaseAddWords');
  String get downloadApps => translate('downloadApps');
  String get couldNotOpenLink => translate('couldNotOpenLink');
  
  // Study page
  String get sessionSaved => translate('sessionSaved');
  String get youEarnedPoints => translate('youEarnedPoints');
  String get sessionComplete => translate('sessionComplete');
  String get studiedWords => translate('studiedWords');
  String get pleaseLoginFirst => translate('pleaseLoginFirst');
  
  // My Words page
  String get addMyWords => translate('addMyWords');
  String get manageExistWords => translate('manageExistWords');
  String get extractingWords => translate('extractingWords');
  String get editOcrResult => translate('editOcrResult');
  String get wordOrSentence => translate('wordOrSentence');
  String get suggestedTag => translate('suggestedTag');
  String get ocrNotSupported => translate('ocrNotSupported');
  String get pleaseConfigureAI => translate('pleaseConfigureAI');
  String get failedToExtractText => translate('failedToExtractText');
  String get assignUnassignClasses => translate('assignUnassignClasses');
  String get filterClasses => translate('filterClasses');
  String get availableClasses => translate('availableClasses');
  String get assignedClasses => translate('assignedClasses');
  String get assign => translate('assign');
  String get unassign => translate('unassign');
  String get addedWords => translate('addedWords');
  String get tagVisibility => translate('tagVisibility');
  String get privateTag => translate('privateTag');
  String get publicTag => translate('publicTag');
  String get pickImage => translate('pickImage');
  String get takePhoto => translate('takePhoto');
  String get submitWord => translate('submitWord');
  
  // Quiz page
  String get quizComplete => translate('quizComplete');
  String get yourScore => translate('yourScore');
  String get pointsEarned => translate('pointsEarned');
  String get shareQuizScoreWithPoints => translate('shareQuizScoreWithPoints');
  String get shareQuizScoreNoPoints => translate('shareQuizScoreNoPoints');
  String get shareStudyWithPoints => translate('shareStudyWithPoints');
  String get shareStudyNoPoints => translate('shareStudyNoPoints');
  String get shareYourScore => translate('shareYourScore');
  String get shareYourAchievement => translate('shareYourAchievement');
  
  // Login page
  String get userName => translate('userName');
  String get password => translate('password');
  String get loginAsGuest => translate('loginAsGuest');
  String get register => translate('register');
  String get pleaseEnterBothFields => translate('pleaseEnterBothFields');
  String get incorrectCredentials => translate('incorrectCredentials');
  String get loginFailed => translate('loginFailed');
  String get confirmPassword => translate('confirmPassword');
  String get grade => translate('grade');
  String get allFieldsRequired => translate('allFieldsRequired');
  String get passwordsDoNotMatch => translate('passwordsDoNotMatch');
  String get registrationFailed => translate('registrationFailed');
  String get usernameAlreadyExists => translate('usernameAlreadyExists');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
