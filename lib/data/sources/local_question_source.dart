import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/category.dart';
import '../models/question.dart';

/// Reads and decodes the bundled `assets/questions.json` file.
///
/// This is the only place that knows about the asset format. The decoded
/// JSON is cached after the first read so repeated calls are cheap.
class LocalQuestionSource {
  LocalQuestionSource({this.assetPath = 'assets/questions.json'});

  final String assetPath;

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
    return list.map(Category.fromJson).toList(growable: false);
  }

  Future<List<Question>> loadQuestions() async {
    final data = await _load();
    final list = (data['questions'] as List).cast<Map<String, dynamic>>();
    return list.map(Question.fromJson).toList(growable: false);
  }
}
