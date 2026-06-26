import 'package:flutter/material.dart';

/// Static definition of a continent: display data, adjacency graph, and
/// normalized polygon coordinates (0–1) for the CustomPainter.
class ContinentDef {
  final String id;
  final String name;
  final String nameEn;
  final Color color;
  final List<String> adjacentIds;
  final List<Offset> polygon;   // normalized 0–1 x/y
  final Offset labelOffset;     // normalized 0–1, center of label

  const ContinentDef({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.color,
    required this.adjacentIds,
    required this.polygon,
    required this.labelOffset,
  });
}

const List<ContinentDef> kContinents = [
  ContinentDef(
    id: 'north_america',
    name: 'Kuzey\nAmerika',
    nameEn: 'North\nAmerica',
    color: Color(0xFF8B5CF6),
    adjacentIds: ['south_america', 'europe', 'asia'],
    polygon: [
      Offset(0.04, 0.12), Offset(0.16, 0.06), Offset(0.27, 0.07),
      Offset(0.32, 0.13), Offset(0.30, 0.21), Offset(0.28, 0.31),
      Offset(0.25, 0.44), Offset(0.18, 0.51), Offset(0.10, 0.47),
      Offset(0.03, 0.38), Offset(0.02, 0.24),
    ],
    labelOffset: Offset(0.15, 0.27),
  ),
  ContinentDef(
    id: 'south_america',
    name: 'Güney\nAmerika',
    nameEn: 'South\nAmerica',
    color: Color(0xFF14B8A6),
    adjacentIds: ['north_america', 'africa', 'antarctica'],
    polygon: [
      Offset(0.17, 0.53), Offset(0.29, 0.51), Offset(0.36, 0.56),
      Offset(0.37, 0.67), Offset(0.33, 0.79), Offset(0.26, 0.89),
      Offset(0.20, 0.89), Offset(0.14, 0.79), Offset(0.13, 0.64),
    ],
    labelOffset: Offset(0.24, 0.69),
  ),
  ContinentDef(
    id: 'europe',
    name: 'Avrupa',
    nameEn: 'Europe',
    color: Color(0xFF10B981),
    adjacentIds: ['africa', 'asia', 'north_america'],
    polygon: [
      Offset(0.42, 0.10), Offset(0.52, 0.07), Offset(0.59, 0.10),
      Offset(0.61, 0.18), Offset(0.59, 0.26), Offset(0.53, 0.31),
      Offset(0.45, 0.29), Offset(0.41, 0.22),
    ],
    labelOffset: Offset(0.51, 0.19),
  ),
  ContinentDef(
    id: 'africa',
    name: 'Afrika',
    nameEn: 'Africa',
    color: Color(0xFFF59E0B),
    adjacentIds: ['europe', 'asia', 'south_america'],
    polygon: [
      Offset(0.44, 0.31), Offset(0.55, 0.29), Offset(0.62, 0.33),
      Offset(0.63, 0.45), Offset(0.61, 0.57), Offset(0.56, 0.71),
      Offset(0.50, 0.79), Offset(0.44, 0.73), Offset(0.40, 0.59),
      Offset(0.40, 0.45),
    ],
    labelOffset: Offset(0.52, 0.53),
  ),
  ContinentDef(
    id: 'asia',
    name: 'Asya',
    nameEn: 'Asia',
    color: Color(0xFF3B82F6),
    adjacentIds: ['europe', 'africa', 'north_america', 'australia'],
    polygon: [
      Offset(0.59, 0.07), Offset(0.74, 0.04), Offset(0.90, 0.06),
      Offset(0.98, 0.14), Offset(0.97, 0.29), Offset(0.90, 0.41),
      Offset(0.80, 0.51), Offset(0.68, 0.51), Offset(0.62, 0.41),
      Offset(0.61, 0.29), Offset(0.61, 0.18),
    ],
    labelOffset: Offset(0.79, 0.27),
  ),
  ContinentDef(
    id: 'australia',
    name: 'Avustralya',
    nameEn: 'Australia',
    color: Color(0xFFF97316),
    adjacentIds: ['asia', 'antarctica'],
    polygon: [
      Offset(0.74, 0.57), Offset(0.85, 0.54), Offset(0.94, 0.58),
      Offset(0.96, 0.67), Offset(0.92, 0.77), Offset(0.84, 0.81),
      Offset(0.74, 0.77), Offset(0.71, 0.68),
    ],
    labelOffset: Offset(0.83, 0.67),
  ),
  ContinentDef(
    id: 'antarctica',
    name: 'Antarktika',
    nameEn: 'Antarctica',
    color: Color(0xFF06B6D4),
    adjacentIds: ['south_america', 'australia'],
    polygon: [
      Offset(0.01, 0.88), Offset(0.99, 0.88),
      Offset(0.99, 0.97), Offset(0.01, 0.97),
    ],
    labelOffset: Offset(0.50, 0.93),
  ),
];

ContinentDef? continentById(String id) {
  try {
    return kContinents.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
