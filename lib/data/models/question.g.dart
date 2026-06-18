// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Question _$QuestionFromJson(Map<String, dynamic> json) => _Question(
  id: json['id'] as String,
  categoryId: json['categoryId'] as String,
  text: json['text'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctIndex: (json['correctIndex'] as num?)?.toInt(),
  difficulty:
      $enumDecodeNullable(_$QuestionDifficultyEnumMap, json['difficulty']) ??
      QuestionDifficulty.medium,
);

Map<String, dynamic> _$QuestionToJson(_Question instance) => <String, dynamic>{
  'id': instance.id,
  'categoryId': instance.categoryId,
  'text': instance.text,
  'options': instance.options,
  'correctIndex': instance.correctIndex,
  'difficulty': _$QuestionDifficultyEnumMap[instance.difficulty]!,
};

const _$QuestionDifficultyEnumMap = {
  QuestionDifficulty.easy: 'easy',
  QuestionDifficulty.medium: 'medium',
  QuestionDifficulty.hard: 'hard',
};
