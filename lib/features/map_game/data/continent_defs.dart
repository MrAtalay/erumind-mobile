import 'package:flutter/material.dart';

/// Static continent definitions for the game map.
///
/// Coordinates are intentionally stylised (not pixel-perfect Mercator) so that
/// all 7 continents appear clearly separated on a portrait phone screen.
/// Europe is shifted up, Africa shifted down, creating a visible Mediterranean gap.
class ContinentDef {
  final String id;
  final String name;
  final String nameEn;
  final Color color;
  final List<String> adjacentIds;
  final List<Offset> polygon; // normalised 0–1 (x: left→right, y: top→bottom)
  final Offset labelOffset;   // centre of text label

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
  // ── North America ──────────────────────────────────────────────────────────
  // Bounding box approx: x 0.02–0.36, y 0.03–0.52
  ContinentDef(
    id: 'north_america',
    name: 'Kuzey\nAmerika',
    nameEn: 'North\nAmerica',
    color: Color(0xFF7C3AED),
    adjacentIds: ['south_america', 'europe', 'asia'],
    polygon: [
      Offset(0.03, 0.24), // Alaska SW tip
      Offset(0.04, 0.13), // W Alaska coast
      Offset(0.07, 0.06), // N Alaska (Barrow)
      Offset(0.13, 0.03), // NW Canada
      Offset(0.23, 0.02), // N Canada
      Offset(0.29, 0.04), // N Canada E
      Offset(0.35, 0.12), // Labrador
      Offset(0.33, 0.20), // Maritime provinces
      Offset(0.31, 0.27), // New England
      Offset(0.28, 0.36), // Mid-Atlantic
      Offset(0.25, 0.45), // Carolina / Georgia
      Offset(0.24, 0.50), // Florida
      Offset(0.21, 0.54), // Yucatan
      Offset(0.16, 0.54), // W Mexico
      Offset(0.11, 0.48), // Baja California tip
      Offset(0.07, 0.40), // SW US
      Offset(0.04, 0.31), // Pacific NW
      Offset(0.03, 0.27), // SE Alaska
    ],
    labelOffset: Offset(0.16, 0.25),
  ),

  // ── South America ──────────────────────────────────────────────────────────
  // Bounding box approx: x 0.13–0.40, y 0.54–0.92
  ContinentDef(
    id: 'south_america',
    name: 'Güney\nAmerika',
    nameEn: 'South\nAmerica',
    color: Color(0xFF0D9488),
    adjacentIds: ['north_america', 'africa', 'antarctica'],
    polygon: [
      Offset(0.18, 0.55), // NW Colombia
      Offset(0.27, 0.52), // N Venezuela
      Offset(0.35, 0.55), // Guyana / NE Brazil
      Offset(0.40, 0.61), // NE Brazil bulge
      Offset(0.40, 0.70), // E Brazil coast
      Offset(0.37, 0.79), // SE Brazil
      Offset(0.31, 0.88), // Buenos Aires area
      Offset(0.26, 0.92), // Patagonia S
      Offset(0.21, 0.90), // S Chile
      Offset(0.17, 0.79), // W Chile
      Offset(0.15, 0.66), // Peru / Ecuador
      Offset(0.16, 0.56), // Colombia W coast
    ],
    labelOffset: Offset(0.27, 0.72),
  ),

  // ── Europe ─────────────────────────────────────────────────────────────────
  // Shifted UP relative to geography so a visible gap separates it from Africa.
  // Bounding box approx: x 0.40–0.58, y 0.04–0.26
  ContinentDef(
    id: 'europe',
    name: 'Avrupa',
    nameEn: 'Europe',
    color: Color(0xFF059669),
    adjacentIds: ['africa', 'asia', 'north_america'],
    polygon: [
      Offset(0.41, 0.24), // Portugal / Spain SW
      Offset(0.40, 0.14), // UK / Ireland W
      Offset(0.44, 0.07), // Norway / Scandinavia W
      Offset(0.50, 0.04), // N Scandinavia
      Offset(0.56, 0.06), // Finland N
      Offset(0.58, 0.10), // Russia NW (Kola Peninsula)
      Offset(0.58, 0.19), // Ukraine / Romania
      Offset(0.56, 0.25), // Balkans
      Offset(0.52, 0.27), // Greece / Turkey W tip
      Offset(0.48, 0.27), // Italy S / Spain E
      Offset(0.43, 0.24), // Spain S
    ],
    labelOffset: Offset(0.49, 0.16),
  ),

  // ── Africa ─────────────────────────────────────────────────────────────────
  // Shifted DOWN so it starts well below Europe (Mediterranean gap y 0.26–0.34).
  // Bounding box approx: x 0.37–0.64, y 0.34–0.86
  ContinentDef(
    id: 'africa',
    name: 'Afrika',
    nameEn: 'Africa',
    color: Color(0xFFD97706),
    adjacentIds: ['europe', 'asia', 'south_america'],
    polygon: [
      Offset(0.43, 0.36), // NW Morocco
      Offset(0.51, 0.34), // N Tunisia
      Offset(0.60, 0.36), // NE (Egypt / Libya)
      Offset(0.63, 0.43), // Horn N (Ethiopia)
      Offset(0.64, 0.51), // Horn S (Somalia tip)
      Offset(0.61, 0.62), // E Africa (Kenya / Tanzania)
      Offset(0.57, 0.75), // Mozambique
      Offset(0.50, 0.84), // S tip (Cape of Good Hope)
      Offset(0.43, 0.76), // SW Namibia
      Offset(0.38, 0.61), // W (Nigeria / Ghana)
      Offset(0.37, 0.48), // W (Senegal)
      Offset(0.40, 0.37), // NW coast
    ],
    labelOffset: Offset(0.51, 0.58),
  ),

  // ── Asia ───────────────────────────────────────────────────────────────────
  // Bounding box approx: x 0.60–0.99, y 0.02–0.58
  ContinentDef(
    id: 'asia',
    name: 'Asya',
    nameEn: 'Asia',
    color: Color(0xFF2563EB),
    adjacentIds: ['europe', 'africa', 'north_america', 'australia'],
    polygon: [
      Offset(0.60, 0.10), // Urals (Europe–Asia border)
      Offset(0.65, 0.03), // N Russia W
      Offset(0.83, 0.01), // N Siberia
      Offset(0.97, 0.06), // NE Siberia (Chukotka)
      Offset(0.98, 0.20), // E Russia
      Offset(0.93, 0.35), // E China / Korea
      Offset(0.88, 0.47), // SE Asia (Vietnam / Thailand)
      Offset(0.82, 0.54), // Malaysia / Indonesia N
      Offset(0.75, 0.57), // India E (Bay of Bengal)
      Offset(0.70, 0.58), // India tip (Cape Comorin)
      Offset(0.65, 0.52), // India W / Arabian Sea
      Offset(0.62, 0.43), // Persian Gulf / Arabia
      Offset(0.62, 0.34), // Middle East / Turkey
      Offset(0.60, 0.22), // Caucasus / Turkey N
    ],
    labelOffset: Offset(0.80, 0.25),
  ),

  // ── Australia ──────────────────────────────────────────────────────────────
  // Bounding box approx: x 0.70–0.98, y 0.56–0.86
  ContinentDef(
    id: 'australia',
    name: 'Avustralya',
    nameEn: 'Australia',
    color: Color(0xFFEA580C),
    adjacentIds: ['asia', 'antarctica'],
    polygon: [
      Offset(0.72, 0.58), // NW (Broome)
      Offset(0.80, 0.55), // N (Darwin)
      Offset(0.87, 0.55), // Gulf of Carpentaria E
      Offset(0.93, 0.59), // NE Queensland
      Offset(0.97, 0.68), // E coast (Brisbane)
      Offset(0.95, 0.76), // E coast (Sydney)
      Offset(0.91, 0.82), // SE (Melbourne)
      Offset(0.83, 0.86), // S coast (Adelaide)
      Offset(0.72, 0.81), // SW (Perth S)
      Offset(0.70, 0.70), // W coast (Perth N)
    ],
    labelOffset: Offset(0.83, 0.69),
  ),

  // ── Antarctica ─────────────────────────────────────────────────────────────
  ContinentDef(
    id: 'antarctica',
    name: 'Antarktika',
    nameEn: 'Antarctica',
    color: Color(0xFF0891B2),
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
