import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// A quiz category (e.g. Science, History).
///
/// Pure data: no Flutter/UI types here so the data layer stays
/// framework-agnostic. [colorValue] is a 32-bit ARGB int that the
/// presentation layer turns into a `Color`.
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required int colorValue,
    String? description,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
