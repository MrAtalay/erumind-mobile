# Map shapes generator

Generates `lib/features/map_game/data/world_shapes.dart` — the continent
polygons drawn by `WorldMapPainter` for the "Bil ve Fethet" map game.

Source data: Natural Earth 1:110m admin-0 countries (public domain).

## Regenerate

```bash
cd tool/map-shapes
curl -sL "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_admin_0_countries.geojson" -o countries.geojson
node gen_shapes.js
cp world_shapes.dart ../../lib/features/map_game/data/world_shapes.dart
```

## What the script does

- Projects each country's coastline through an equirectangular projection
  into normalised 0–1 coordinates (`x = (lng+180)/360`, latitude cropped to
  84°N…78°S).
- Simplifies each ring with Douglas–Peucker and drops tiny islands.
- Tags every polygon with one of the 7 game continents (Natural Earth's
  `CONTINENT` field; `Oceania` → `australia`, Russia forced to `asia` for
  visual coherence) and emits `kWorldShapes` + `kMapAspect`.

`countries.geojson` is not committed (≈840 KB); re-download it with the curl
line above before regenerating.
