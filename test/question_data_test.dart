import 'dart:convert';
import 'dart:io';

import 'package:erumind/data/models/category.dart';
import 'package:erumind/data/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates the shape of the bundled `assets/questions.json` so a typo or a
/// missing field is caught at test time instead of at runtime on a device.
void main() {
  final raw = File('assets/questions.json').readAsStringSync();
  final data = json.decode(raw) as Map<String, dynamic>;

  final categories = (data['categories'] as List)
      .cast<Map<String, dynamic>>()
      .map(Category.fromJson)
      .toList();
  final questions = (data['questions'] as List)
      .cast<Map<String, dynamic>>()
      .map(Question.fromJson)
      .toList();

  test('category ids are unique', () {
    final ids = categories.map((c) => c.id).toSet();
    expect(ids, hasLength(categories.length));
  });

  test('question ids are unique', () {
    final ids = questions.map((q) => q.id).toSet();
    expect(ids, hasLength(questions.length));
  });

  test('every question references a known category', () {
    final categoryIds = categories.map((c) => c.id).toSet();
    for (final question in questions) {
      expect(
        categoryIds.contains(question.categoryId),
        isTrue,
        reason: '${question.id} references unknown category '
            '${question.categoryId}',
      );
    }
  });

  test('every question has exactly 4 options', () {
    for (final question in questions) {
      expect(question.options, hasLength(4), reason: question.id);
    }
  });

  test('every question has a correctIndex within range', () {
    for (final question in questions) {
      expect(
        question.correctIndex,
        inInclusiveRange(0, 3),
        reason: question.id,
      );
    }
  });

  test('every category has at least one question', () {
    final usedCategoryIds = questions.map((q) => q.categoryId).toSet();
    for (final category in categories) {
      expect(usedCategoryIds.contains(category.id), isTrue, reason: category.id);
    }
  });
}
