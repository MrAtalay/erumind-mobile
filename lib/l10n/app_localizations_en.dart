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
  String get settingsSound => 'Sound';

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

  @override
  String get spinPrompt => 'Spin the wheel!';

  @override
  String banked(int points) {
    return 'Banked: $points';
  }

  @override
  String pot(int points) {
    return 'Pot: $points';
  }

  @override
  String multiplier(String value) {
    return '×$value';
  }

  @override
  String get bank => 'Bank';

  @override
  String get riskIt => 'Risk it';

  @override
  String get finish => 'Finish';

  @override
  String get wrongAnswer => 'Wrong!';

  @override
  String get timeUp => 'Time\'s up!';

  @override
  String get gameOverNoLives => 'Out of lives — game over';

  @override
  String get continuePlaying => 'Continue';

  @override
  String correctAnswers(int count) {
    return 'Correct answers: $count';
  }

  @override
  String crownsProgress(int earned, int total) {
    return 'Crowns: $earned / $total';
  }

  @override
  String newCrown(String category) {
    return 'New crown: $category!';
  }

  @override
  String get onboardingTitle1 => 'Spin the wheel';

  @override
  String get onboardingBody1 =>
      'Each round starts with a spin. Wherever it lands, that\'s your next question\'s category.';

  @override
  String get onboardingTitle2 => 'Answer to grow your pot';

  @override
  String get onboardingBody2 =>
      'A correct answer adds points to your pot — keep a streak going and the multiplier climbs.';

  @override
  String get onboardingTitle3 => 'Bank it or risk it';

  @override
  String get onboardingBody3 =>
      'Bank your pot to keep it safe, or risk it for an even bigger multiplier. A wrong answer costs a life, not your pot — the game only ends when your lives run out.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get menuSinglePlayer => 'Solo';

  @override
  String get menuMultiplayer => 'Versus';

  @override
  String get menuPlayer => 'Player';

  @override
  String get menuTagline => 'Learn while having fun';

  @override
  String get menuComingSoon => 'COMING SOON';

  @override
  String get settingsGameSection => 'Game';

  @override
  String get settingsHowToPlay => 'How to play?';
}
