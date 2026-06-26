import 'package:flutter/material.dart';

/// Metadata for a continent: display name, colour, and adjacency graph.
/// The drawable geometry lives in the generated `world_shapes.dart`
/// (`kWorldShapes`), keyed by [id].
class ContinentDef {
  final String id;
  final String name;
  final String nameEn;
  final Color color;
  final List<String> adjacentIds;

  const ContinentDef({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.color,
    required this.adjacentIds,
  });
}

const List<ContinentDef> kContinents = [
  ContinentDef(
    id: 'north_america',
    name: 'Kuzey Amerika',
    nameEn: 'North America',
    color: Color(0xFF7C3AED),
    adjacentIds: ['south_america', 'europe', 'asia'],
  ),
  ContinentDef(
    id: 'south_america',
    name: 'Güney Amerika',
    nameEn: 'South America',
    color: Color(0xFF0D9488),
    adjacentIds: ['north_america', 'africa', 'antarctica'],
  ),
  ContinentDef(
    id: 'europe',
    name: 'Avrupa',
    nameEn: 'Europe',
    color: Color(0xFF059669),
    adjacentIds: ['africa', 'asia', 'north_america'],
  ),
  ContinentDef(
    id: 'africa',
    name: 'Afrika',
    nameEn: 'Africa',
    color: Color(0xFFD97706),
    adjacentIds: ['europe', 'asia', 'south_america'],
  ),
  ContinentDef(
    id: 'asia',
    name: 'Asya',
    nameEn: 'Asia',
    color: Color(0xFF2563EB),
    adjacentIds: ['europe', 'africa', 'north_america', 'australia'],
  ),
  ContinentDef(
    id: 'australia',
    name: 'Avustralya',
    nameEn: 'Australia',
    color: Color(0xFFEA580C),
    adjacentIds: ['asia', 'antarctica'],
  ),
  ContinentDef(
    id: 'antarctica',
    name: 'Antarktika',
    nameEn: 'Antarctica',
    color: Color(0xFF0891B2),
    adjacentIds: ['south_america', 'australia'],
  ),
];

ContinentDef? continentById(String id) {
  try {
    return kContinents.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
