import 'package:flutter/material.dart';

/// Metadata for a continent: display name, colour, adjacency graph, and the
/// quiz [categoryId] its questions are drawn from (so *which* continent you
/// attack decides the question category — choices matter).
/// The drawable geometry lives in the generated `world_shapes.dart`
/// (`kWorldShapes`), keyed by [id].
class ContinentDef {
  final String id;
  final String name;
  final String nameEn;
  final Color color;
  final List<String> adjacentIds;
  final String categoryId;

  const ContinentDef({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.color,
    required this.adjacentIds,
    required this.categoryId,
  });
}

/// Turkish display names for the quiz categories, keyed by category id.
const Map<String, String> kCategoryLabels = {
  'science': 'Bilim',
  'history': 'Tarih',
  'geography': 'Coğrafya',
  'sports': 'Spor',
  'art': 'Sanat',
  'entertainment': 'Eğlence',
};

const List<ContinentDef> kContinents = [
  ContinentDef(
    id: 'north_america',
    name: 'Kuzey Amerika',
    nameEn: 'North America',
    color: Color(0xFF6F5C99),
    adjacentIds: ['south_america', 'europe', 'asia'],
    categoryId: 'entertainment',
  ),
  ContinentDef(
    id: 'south_america',
    name: 'Güney Amerika',
    nameEn: 'South America',
    color: Color(0xFF3F8F84),
    adjacentIds: ['north_america', 'africa', 'antarctica'],
    categoryId: 'sports',
  ),
  ContinentDef(
    id: 'europe',
    name: 'Avrupa',
    nameEn: 'Europe',
    color: Color(0xFF6A8C5A),
    adjacentIds: ['africa', 'asia', 'north_america'],
    categoryId: 'art',
  ),
  ContinentDef(
    id: 'africa',
    name: 'Afrika',
    nameEn: 'Africa',
    color: Color(0xFFC2913F),
    adjacentIds: ['europe', 'asia', 'south_america'],
    categoryId: 'geography',
  ),
  ContinentDef(
    id: 'asia',
    name: 'Asya',
    nameEn: 'Asia',
    color: Color(0xFF5878A6),
    adjacentIds: ['europe', 'africa', 'north_america', 'australia'],
    categoryId: 'history',
  ),
  ContinentDef(
    id: 'australia',
    name: 'Avustralya',
    nameEn: 'Australia',
    color: Color(0xFFBE7848),
    adjacentIds: ['asia', 'antarctica'],
    categoryId: 'science',
  ),
  ContinentDef(
    id: 'antarctica',
    name: 'Antarktika',
    nameEn: 'Antarctica',
    color: Color(0xFF6B97A6),
    adjacentIds: ['south_america', 'australia'],
    categoryId: 'geography',
  ),
];

ContinentDef? continentById(String id) {
  try {
    return kContinents.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
