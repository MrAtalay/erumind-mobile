// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get play => 'Play';

  @override
  String get playAgain => 'Play again';

  @override
  String get spin => 'Spin';

  @override
  String get settings => 'Settings';

  @override
  String get menuNoGames => 'No games yet';

  @override
  String bestPoints(int points) {
    return 'Best: $points points';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get lobbyReady => 'Ready to play?';

  @override
  String get outOfLives => 'Out of lives';

  @override
  String nextLifeIn(String time) {
    return 'Next life in $time';
  }

  @override
  String questionProgress(int current, int total) {
    return 'Question $current / $total';
  }

  @override
  String score(int score) {
    return 'Score: $score';
  }

  @override
  String get next => 'Next';

  @override
  String get seeResults => 'See results';

  @override
  String get roundComplete => 'Round complete!';

  @override
  String points(int points) {
    return '$points points';
  }

  @override
  String correctOutOf(int correct, int total) {
    return 'Correct: $correct / $total';
  }

  @override
  String get newBest => 'New best!';
}
