import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Settings page translations
  String get settings => locale.languageCode == 'tr' ? 'Ayarlar' : 'Settings';
  String get language => locale.languageCode == 'tr' ? 'Dil' : 'Language';
  String get theme => locale.languageCode == 'tr' ? 'Tema' : 'Theme';
  String get appLanguage => locale.languageCode == 'tr' ? 'Uygulama Dili' : 'App Language';
  String get interfaceLanguage => locale.languageCode == 'tr' ? 'Arayüz Dili' : 'Interface Language';
  String get learningLanguage => locale.languageCode == 'tr' ? 'Öğrenilen Dil' : 'Learning Language';
  String get selectedLanguage => locale.languageCode == 'tr' ? 'Seçili Dil' : 'Selected Language';
  String get selectAppLanguage => locale.languageCode == 'tr' ? 'Uygulama Dilini Seç' : 'Select App Language';
  String get english => locale.languageCode == 'tr' ? 'İngilizce' : 'English';
  String get turkish => locale.languageCode == 'tr' ? 'Türkçe' : 'Turkish';
  String get cancel => locale.languageCode == 'tr' ? 'İptal' : 'Cancel';
  String get appLanguageChangedToEnglish => 'App language changed to English';
  String get appLanguageChangedToTurkish => 'Uygulama dili Türkçe olarak değiştirildi';
  
  // Dashboard translations
  String get dashboard => locale.languageCode == 'tr' ? 'Ana Sayfa' : 'Dashboard';
  String get stories => locale.languageCode == 'tr' ? 'Hikayeler' : 'Stories';
  String get wordLists => locale.languageCode == 'tr' ? 'Kelime Listeleri' : 'Word Lists';
  String get translator => locale.languageCode == 'tr' ? 'Çevirmen' : 'Translator';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
