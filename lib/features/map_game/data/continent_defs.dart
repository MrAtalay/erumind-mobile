import 'package:flutter/material.dart';

/// Static definition of a continent: display data, adjacency graph, and
/// normalized polygon coordinates (0–1) for the CustomPainter.
///
/// Coordinates use a simplified equirectangular projection:
///   x = (longitude + 180) / 360
///   y = (80 - latitude) / 135   [covers lat 80°N → ~55°S]
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
  // ── North America ─────────────────────────────────────────────────────────
  ContinentDef(
    id: 'north_america',
    name: 'Kuzey\nAmerika',
    nameEn: 'North\nAmerica',
    color: Color(0xFF8B5CF6),
    adjacentIds: ['south_america', 'europe', 'asia'],
    polygon: [
      Offset(0.03, 0.23), // Alaska SW coast
      Offset(0.05, 0.13), // W Alaska
      Offset(0.07, 0.07), // N Alaska (Barrow)
      Offset(0.14, 0.04), // NW Canada
      Offset(0.25, 0.03), // N Canada
      Offset(0.31, 0.05), // Hudson Bay N
      Offset(0.35, 0.14), // Labrador / NE Canada
      Offset(0.34, 0.22), // Maritime provinces
      Offset(0.31, 0.29), // New England
      Offset(0.28, 0.38), // Mid-Atlantic / Virginia
      Offset(0.26, 0.46), // Florida
      Offset(0.22, 0.52), // Mexico / Yucatan
      Offset(0.17, 0.52), // W Mexico
      Offset(0.12, 0.47), // Baja California
      Offset(0.08, 0.39), // SW US / California
      Offset(0.05, 0.31), // Pacific NW
      Offset(0.03, 0.27), // SE Alaska
    ],
    labelOffset: Offset(0.17, 0.26),
  ),

  // ── South America ─────────────────────────────────────────────────────────
  ContinentDef(
    id: 'south_america',
    name: 'Güney\nAmerika',
    nameEn: 'South\nAmerica',
    color: Color(0xFF14B8A6),
    adjacentIds: ['north_america', 'africa', 'antarctica'],
    polygon: [
      Offset(0.20, 0.53), // NW Colombia
      Offset(0.29, 0.50), // N Venezuela
      Offset(0.37, 0.54), // Guyana / NE Brazil
      Offset(0.40, 0.60), // NE Brazil bulge
      Offset(0.40, 0.68), // E Brazil coast
      Offset(0.37, 0.77), // SE Brazil
      Offset(0.32, 0.86), // Uruguay / Buenos Aires
      Offset(0.27, 0.91), // S Argentina / Patagonia
      Offset(0.23, 0.89), // S Chile
      Offset(0.17, 0.77), // W Chile
      Offset(0.16, 0.64), // Peru / Ecuador W coast
      Offset(0.17, 0.55), // Colombia W coast
    ],
    labelOffset: Offset(0.27, 0.70),
  ),

  // ── Europe ────────────────────────────────────────────────────────────────
  ContinentDef(
    id: 'europe',
    name: 'Avrupa',
    nameEn: 'Europe',
    color: Color(0xFF10B981),
    adjacentIds: ['africa', 'asia', 'north_america'],
    polygon: [
      Offset(0.44, 0.29), // Portugal SW
      Offset(0.43, 0.18), // Ireland / W Britain
      Offset(0.46, 0.09), // Norway SW
      Offset(0.52, 0.06), // Scandinavia N
      Offset(0.57, 0.08), // Finland
      Offset(0.62, 0.11), // Russia NW (Kola)
      Offset(0.63, 0.21), // Ukraine / Russia
      Offset(0.60, 0.28), // Balkans
      Offset(0.56, 0.32), // Greece / W Turkey
      Offset(0.50, 0.32), // Italy S / Spain E
      Offset(0.46, 0.30), // Spain S
    ],
    labelOffset: Offset(0.52, 0.18),
  ),

  // ── Africa ────────────────────────────────────────────────────────────────
  ContinentDef(
    id: 'africa',
    name: 'Afrika',
    nameEn: 'Africa',
    color: Color(0xFFF59E0B),
    adjacentIds: ['europe', 'asia', 'south_america'],
    polygon: [
      Offset(0.44, 0.34), // NW Morocco
      Offset(0.52, 0.31), // N Tunisia
      Offset(0.62, 0.34), // NE Libya / Egypt
      Offset(0.65, 0.41), // Horn N (Ethiopia)
      Offset(0.66, 0.49), // Horn S (Somalia)
      Offset(0.63, 0.61), // E Africa (Kenya / Tanzania)
      Offset(0.57, 0.74), // Mozambique
      Offset(0.50, 0.82), // S tip (Cape of Good Hope)
      Offset(0.43, 0.74), // SW (Namibia)
      Offset(0.39, 0.60), // W (Nigeria)
      Offset(0.38, 0.48), // W (Senegal)
      Offset(0.41, 0.36), // NW coast
    ],
    labelOffset: Offset(0.52, 0.56),
  ),

  // ── Asia ──────────────────────────────────────────────────────────────────
  ContinentDef(
    id: 'asia',
    name: 'Asya',
    nameEn: 'Asia',
    color: Color(0xFF3B82F6),
    adjacentIds: ['europe', 'africa', 'north_america', 'australia'],
    polygon: [
      Offset(0.63, 0.11), // W Russia (Urals)
      Offset(0.67, 0.04), // N Russia W
      Offset(0.83, 0.02), // N Siberia
      Offset(0.97, 0.06), // NE Siberia (Chukotka)
      Offset(0.98, 0.21), // E Russia
      Offset(0.93, 0.36), // E China / Korea
      Offset(0.88, 0.46), // SE Asia (Vietnam)
      Offset(0.82, 0.52), // Malaysia / Indonesia
      Offset(0.75, 0.56), // India E
      Offset(0.70, 0.57), // India tip (Cape Comorin)
      Offset(0.64, 0.51), // India W / Arabia
      Offset(0.62, 0.42), // Arabia / Persian Gulf
      Offset(0.62, 0.33), // Turkey / Middle East
      Offset(0.62, 0.22), // Caucasus / Turkey
    ],
    labelOffset: Offset(0.80, 0.26),
  ),

  // ── Australia ─────────────────────────────────────────────────────────────
  ContinentDef(
    id: 'australia',
    name: 'Avustralya',
    nameEn: 'Australia',
    color: Color(0xFFF97316),
    adjacentIds: ['asia', 'antarctica'],
    polygon: [
      Offset(0.73, 0.58), // NW (Broome)
      Offset(0.81, 0.55), // N (Darwin)
      Offset(0.88, 0.55), // Gulf of Carpentaria E
      Offset(0.94, 0.59), // NE Queensland
      Offset(0.97, 0.67), // E coast (Brisbane)
      Offset(0.96, 0.75), // E coast (Sydney)
      Offset(0.92, 0.81), // SE (Melbourne)
      Offset(0.83, 0.85), // S coast (Adelaide)
      Offset(0.73, 0.80), // SW (Perth S)
      Offset(0.70, 0.70), // W coast
    ],
    labelOffset: Offset(0.83, 0.68),
  ),

  // ── Antarctica ────────────────────────────────────────────────────────────
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
