// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get play => 'Oyna';

  @override
  String get playAgain => 'Tekrar oyna';

  @override
  String get spin => 'Çevir';

  @override
  String get settings => 'Ayarlar';

  @override
  String get menuNoGames => 'Henüz oyun yok';

  @override
  String bestPoints(int points) {
    return 'En iyi: $points puan';
  }

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get lobbyReady => 'Oynamaya hazır mısın?';

  @override
  String get outOfLives => 'Can kalmadı';

  @override
  String nextLifeIn(String time) {
    return 'Sonraki can: $time';
  }

  @override
  String questionProgress(int current, int total) {
    return 'Soru $current / $total';
  }

  @override
  String score(int score) {
    return 'Puan: $score';
  }

  @override
  String get next => 'Sonraki';

  @override
  String get seeResults => 'Sonuçlar';

  @override
  String get roundComplete => 'Tur bitti!';

  @override
  String points(int points) {
    return '$points puan';
  }

  @override
  String correctOutOf(int correct, int total) {
    return 'Doğru: $correct / $total';
  }

  @override
  String get newBest => 'Yeni rekor!';

  @override
  String get spinPrompt => 'Çarkı çevir!';

  @override
  String banked(int points) {
    return 'Banka: $points';
  }

  @override
  String pot(int points) {
    return 'Tencere: $points';
  }

  @override
  String multiplier(String value) {
    return '×$value';
  }

  @override
  String get bank => 'Bankala';

  @override
  String get riskIt => 'Risk et';

  @override
  String get finish => 'Bitir';

  @override
  String get runOver => 'Yanlış — koşu bitti';

  @override
  String get timeUp => 'Süre doldu — koşu bitti';

  @override
  String correctAnswers(int count) {
    return 'Doğru cevap: $count';
  }

  @override
  String crownsProgress(int earned, int total) {
    return 'Taçlar: $earned / $total';
  }

  @override
  String newCrown(String category) {
    return 'Yeni taç: $category!';
  }
}
