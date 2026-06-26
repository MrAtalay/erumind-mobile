import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/category.dart';
import '../models/question.dart';

/// Reads and decodes the bundled `assets/questions.json` file.
///
/// Pass [locale] = 'en' to get English text/options; defaults to 'tr'.
/// The raw JSON is cached; locale switching is handled by swapping the
/// field used (text vs textEn, options vs optionsEn) before parsing.
class LocalQuestionSource {
  LocalQuestionSource({
    this.assetPath = 'assets/questions.json',
    this.locale = 'tr',
  });

  final String assetPath;
  final String locale;

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    _cache = decoded;
    return decoded;
  }

  Future<List<Category>> loadCategories() async {
    final data = await _load();
    final list = (data['categories'] as List).cast<Map<String, dynamic>>();
    return list.map((raw) {
      if (locale != 'en') return Category.fromJson(raw);
      return Category.fromJson({
        ...raw,
        'name': (raw['nameEn'] as String?) ?? raw['name'] as String,
      });
    }).toList(growable: false);
  }

  Future<List<Question>> loadQuestions() async {
    final data = await _load();
    final list = (data['questions'] as List).cast<Map<String, dynamic>>();
    return list.map((raw) {
      if (locale != 'en') return Question.fromJson(raw);
      return Question.fromJson({
        ...raw,
        'text': (raw['textEn'] as String?) ?? raw['text'] as String,
        'options': (raw['optionsEn'] as List?) ?? raw['options'],
      });
    }).toList(growable: false);
  }
}
