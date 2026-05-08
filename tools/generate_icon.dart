// Premium app-icon generator for CaratOne.
//
// Renders three deliverables to assets/icon/ :
//   1. app_icon.png            (1024x1024, full mark + rounded-square bg) — used by
//                              flutter_launcher_icons as the legacy launcher and as
//                              a generic fallback on iOS/macOS/web/desktop.
//   2. app_icon_foreground.png (1024x1024, transparent, content within the
//                              66% adaptive-icon safe zone) — Android adaptive
//                              foreground for Android 8+.
//   3. play_store_icon.png     (512x512, full bleed, no rounded corners) — Google
//                              Play Console "App icon" upload (Play applies its own
//                              system mask, so corners must NOT be rounded).
//
// Design: top-down brilliant-cut diamond, 8 crown + 8 star facets, gold/champagne
// palette with platinum highlights, on a deep-navy gradient with a warm radial
// glow at upper-left. No text — text in launcher icons is illegible at 48dp and
// is discouraged by both Material and iOS guidelines.
//
// Run:  dart run tools/generate_icon.dart
// then: flutter pub run flutter_launcher_icons

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

// ─── Palette ─────────────────────────────────────────────────────────────────

class C {
  final int r, g, b, a;
  const C(this.r, this.g, this.b, [this.a = 255]);
  img.ColorRgba8 toImg() => img.ColorRgba8(r, g, b, a);
}

// Background — deep navy, harmonised with the app's #1a1a2e theme.
// The diagonal goes from a slightly warm upper-left to a near-black lower-right
// so the gold rim and platinum highlights pop without competing with the mark.
const navyTop    = C(0x10, 0x1c, 0x3e); // upper-left, hint of indigo
const navyMid    = C(0x0a, 0x12, 0x28);
const navyDeep   = C(0x03, 0x06, 0x10); // lower-right, near-black
const glowWarm   = C(0xf3, 0xcd, 0x7a); // faint warm radial glow at upper-left
const rimGold    = C(0xc8, 0x99, 0x3a); // hairline gold between facets

// Brand-blue / platinum facet ramp — keyed off the app's #4F8AF4 primary so the
// icon and the in-app theme share DNA. Bright "lit" facets read as polished
// platinum; the deep facets push toward sapphire.
const fGold0 = C(0xf5, 0xfa, 0xff); // platinum highlight (almost white)
const fGold1 = C(0xc8, 0xdc, 0xf5);
const fGold2 = C(0x8e, 0xb2, 0xea);
const fGold3 = C(0x4f, 0x8a, 0xf4); // app primary (#4F8AF4)
const fGold4 = C(0x27, 0x55, 0xa3);
const fGold5 = C(0x10, 0x29, 0x55); // deepest shadow / culet

// ─── Geometry helpers ────────────────────────────────────────────────────────

class V {
  final double x, y;
  const V(this.x, this.y);
  V scale(double s, double cx, double cy) => V(cx + x * s, cy + y * s);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
int _lerpI(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);

C lerpC(C a, C b, double t) => C(
      _lerpI(a.r, b.r, t),
      _lerpI(a.g, b.g, t),
      _lerpI(a.b, b.b, t),
      _lerpI(a.a, b.a, t),
    );

/// Inside a rounded square [0,N] × [0,N] with corner radius r.
bool inRoundedSquare(double x, double y, double N, double r) {
  if (x < 0 || y < 0 || x > N || y > N) return false;
  final cx = x.clamp(r, N - r);
  final cy = y.clamp(r, N - r);
  final dx = x - cx;
  final dy = y - cy;
  return (dx * dx + dy * dy) <= r * r;
}

/// Soft alpha for rounded-square edge (1px feather for AA) at supersampled scale.
double roundedAlpha(double x, double y, double N, double r) {
  if (x < -1 || y < -1 || x > N + 1 || y > N + 1) return 0;
  final cx = x.clamp(r, N - r);
  final cy = y.clamp(r, N - r);
  final dx = x - cx;
  final dy = y - cy;
  final d = math.sqrt(dx * dx + dy * dy);
  if (d <= r - 0.5) return 1.0;
  if (d >= r + 0.5) return 0.0;
  return (r + 0.5 - d).clamp(0.0, 1.0);
}

/// Point-in-convex-polygon via signed cross-products (CW or CCW agnostic).
bool inConvex(double x, double y, List<V> poly) {
  bool? sign;
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i];
    final b = poly[(i + 1) % poly.length];
    final cross = (b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x);
    if (cross == 0) continue;
    final s = cross > 0;
    sign ??= s;
    if (s != sign) return false;
  }
  return true;
}

// ─── Diamond mark (top-down brilliant cut, 16 facets) ────────────────────────
//
// Vertex naming (normalised in [-1, +1] before scaling):
//   O0..O7 — outer octagon (girdle), starting at angle -90° (top), CCW
//   I0..I7 — inner octagon (table) at radius rInner, same angles
//   STAR0..7 — star facets are inside the table; centre point Z = (0,0)
//
// Facets:
//   8 crown trapezoids:  (O_i, O_{i+1}, I_{i+1}, I_i)
//   8 star triangles:    (I_i, I_{i+1}, Z)
//
// Each facet gets a flat colour from the gold ramp, shaded by the facet's
// midpoint angle relative to a light direction at upper-left (-1, -1).

const double _rInner = 0.46; // table-octagon radius as fraction of outer

List<V> _octagon(double r) {
  // Start angle so we get a flat-top octagon: angles at -π/2 ± kπ/4
  final verts = <V>[];
  for (var i = 0; i < 8; i++) {
    final a = -math.pi / 2 + (math.pi / 4) * i + math.pi / 8; // 22.5° rotation
    verts.add(V(r * math.cos(a), r * math.sin(a)));
  }
  return verts;
}

class Facet {
  final List<V> verts; // normalised [-1,1]
  final C color;
  final double centroidX, centroidY;
  Facet(this.verts, this.color)
      : centroidX = verts.map((v) => v.x).reduce((a, b) => a + b) / verts.length,
        centroidY = verts.map((v) => v.y).reduce((a, b) => a + b) / verts.length;
}

List<Facet> _buildFacets() {
  final outer = _octagon(1.0);
  final inner = _octagon(_rInner);
  const z = V(0, 0);

  // Light direction (unit vector, points from surface toward light)
  // Upper-left light gives the classic premium-jewelry feel.
  final lx = -0.78, ly = -0.62;

  C shade(double cxN, double cyN, {required double bias, required double range}) {
    // Dot product of (centroid-direction-from-Z) with light direction.
    // Bright when facet faces upper-left.
    final mag = math.sqrt(cxN * cxN + cyN * cyN);
    final nx = mag == 0 ? 0.0 : cxN / mag;
    final ny = mag == 0 ? 0.0 : cyN / mag;
    final dot = nx * lx + ny * ly; // [-1, +1]
    // Map [-1,+1] → [0,1] with bias
    var t = (1.0 - (dot + 1) / 2) * range + bias; // 0 = brightest, 1 = darkest
    t = t.clamp(0.0, 1.0);
    // 6-stop ramp interpolation
    if (t < 0.20) return lerpC(fGold0, fGold1, t / 0.20);
    if (t < 0.40) return lerpC(fGold1, fGold2, (t - 0.20) / 0.20);
    if (t < 0.60) return lerpC(fGold2, fGold3, (t - 0.40) / 0.20);
    if (t < 0.80) return lerpC(fGold3, fGold4, (t - 0.60) / 0.20);
    return lerpC(fGold4, fGold5, (t - 0.80) / 0.20);
  }

  final facets = <Facet>[];

  // Crown facets (8) — slightly darker overall; girdle is the diamond's "edge"
  for (var i = 0; i < 8; i++) {
    final j = (i + 1) % 8;
    final poly = <V>[outer[i], outer[j], inner[j], inner[i]];
    final cx = poly.map((v) => v.x).reduce((a, b) => a + b) / 4;
    final cy = poly.map((v) => v.y).reduce((a, b) => a + b) / 4;
    facets.add(Facet(poly, shade(cx, cy, bias: 0.12, range: 0.78)));
  }

  // Star facets (8) — brighter, closer to light source on average
  for (var i = 0; i < 8; i++) {
    final j = (i + 1) % 8;
    final poly = <V>[inner[i], inner[j], z];
    final cx = (inner[i].x + inner[j].x) / 3; // centroid (z=0)
    final cy = (inner[i].y + inner[j].y) / 3;
    facets.add(Facet(poly, shade(cx, cy, bias: 0.0, range: 0.65)));
  }

  return facets;
}

// ─── Renderers ───────────────────────────────────────────────────────────────

void _drawBackground(img.Image image, int N, {required bool rounded}) {
  final r = rounded ? N * 0.22 : 0.0; // ~22% corner radius (Material 3 squircle-ish)
  final dN = N.toDouble();

  // Light-source for radial glow (upper-left quadrant)
  final glowCx = N * 0.25;
  final glowCy = N * 0.22;
  final glowR = N * 0.95;

  for (var y = 0; y < N; y++) {
    for (var x = 0; x < N; x++) {
      final fx = x.toDouble(), fy = y.toDouble();
      final maskA = rounded ? roundedAlpha(fx, fy, dN, r) : 1.0;
      if (maskA <= 0) continue;

      // Diagonal navy gradient (upper-left → lower-right)
      final tDiag = ((fx + fy) / (2 * dN)).clamp(0.0, 1.0);
      C base;
      if (tDiag < 0.5) {
        base = lerpC(navyTop, navyMid, tDiag / 0.5);
      } else {
        base = lerpC(navyMid, navyDeep, (tDiag - 0.5) / 0.5);
      }

      // Warm radial glow at upper-left (very subtle)
      final dx = fx - glowCx, dy = fy - glowCy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final glowT = (1.0 - (dist / glowR)).clamp(0.0, 1.0);
      // Smooth falloff (cubic)
      final glowStrength = math.pow(glowT, 2.4) * 0.16;
      final blended = C(
        _lerpI(base.r, glowWarm.r, glowStrength.toDouble()),
        _lerpI(base.g, glowWarm.g, glowStrength.toDouble()),
        _lerpI(base.b, glowWarm.b, glowStrength.toDouble()),
      );

      final a = (255 * maskA).round();
      image.setPixelRgba(x, y, blended.r, blended.g, blended.b, a);
    }
  }
}

void _drawDiamond(img.Image image, int N, {required double scale}) {
  // Diamond is centred slightly above geometric centre so it visually balances
  // with optical-centre perception (about 4% above true centre).
  final cx = N / 2.0;
  final cy = N * 0.49;
  final S = N * scale * 0.5; // half the diamond's bounding extent

  // Render all facets on top of the existing background pixels
  final facets = _buildFacets();

  // Bounding box for iteration
  final minX = (cx - S - 2).floor().clamp(0, N - 1);
  final maxX = (cx + S + 2).ceil().clamp(0, N - 1);
  final minY = (cy - S - 2).floor().clamp(0, N - 1);
  final maxY = (cy + S + 2).ceil().clamp(0, N - 1);

  // Pre-scale facet vertices into pixel space
  final pxFacets = facets
      .map((f) => Facet(
            f.verts.map((v) => V(cx + v.x * S, cy + v.y * S)).toList(),
            f.color,
          ))
      .toList();

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final fx = x + 0.5, fy = y + 0.5;
      for (final f in pxFacets) {
        if (inConvex(fx, fy, f.verts)) {
          image.setPixelRgba(x, y, f.color.r, f.color.g, f.color.b, 255);
          break;
        }
      }
    }
  }

  // Hairline gold rims between every facet — draw each polygon edge as a 1-px AA
  // line. We draw both crown-outer rims and inner-star rims; this gives the
  // diamond its "cut" definition.
  void aaLine(V a, V b, C col) {
    // Wu-style anti-aliased line, simplified.
    final x0 = a.x, y0 = a.y, x1 = b.x, y1 = b.y;
    final dx = x1 - x0, dy = y1 - y0;
    final steps = math.max(dx.abs(), dy.abs()).ceil();
    if (steps == 0) return;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final px = x0 + dx * t;
      final py = y0 + dy * t;
      final ix = px.floor();
      final iy = py.floor();
      final fxw = px - ix;
      final fyw = py - iy;
      _blendPx(image, ix, iy, col, (1 - fxw) * (1 - fyw));
      _blendPx(image, ix + 1, iy, col, fxw * (1 - fyw));
      _blendPx(image, ix, iy + 1, col, (1 - fxw) * fyw);
      _blendPx(image, ix + 1, iy + 1, col, fxw * fyw);
    }
  }

  for (final f in pxFacets) {
    for (var i = 0; i < f.verts.length; i++) {
      final a = f.verts[i];
      final b = f.verts[(i + 1) % f.verts.length];
      aaLine(a, b, rimGold);
    }
  }

  // Outer girdle — thicker rim for the diamond's silhouette
  final outerPx = _octagon(1.0).map((v) => V(cx + v.x * S, cy + v.y * S)).toList();
  for (var i = 0; i < 8; i++) {
    final a = outerPx[i];
    final b = outerPx[(i + 1) % 8];
    aaLine(a, b, rimGold);
    // Second pass slightly inset for thickness
    final mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
    final ax = a.x + (cx - mx) * 0.004;
    final ay = a.y + (cy - my) * 0.004;
    final bx = b.x + (cx - mx) * 0.004;
    final by = b.y + (cy - my) * 0.004;
    aaLine(V(ax, ay), V(bx, by), rimGold);
  }

  // A single bright sparkle near the upper-left of the diamond, on the
  // brightest crown facet — tiny 4-point star.
  final sx = cx - S * 0.32;
  final sy = cy - S * 0.36;
  _drawSparkle(image, sx, sy, S * 0.12, fGold0);

  // A second, even smaller sparkle near the centre table edge
  _drawSparkle(image, cx + S * 0.04, cy - S * 0.18, S * 0.06, fGold0);
}

void _blendPx(img.Image im, int x, int y, C col, double alpha) {
  if (x < 0 || y < 0 || x >= im.width || y >= im.height) return;
  if (alpha <= 0) return;
  final p = im.getPixel(x, y);
  final dr = p.r.toInt(), dg = p.g.toInt(), db = p.b.toInt(), da = p.a.toInt();
  final a = alpha.clamp(0.0, 1.0);
  im.setPixelRgba(
    x,
    y,
    _lerpI(dr, col.r, a),
    _lerpI(dg, col.g, a),
    _lerpI(db, col.b, a),
    math.max(da, (a * 255).round()),
  );
}

void _drawSparkle(img.Image im, double cx, double cy, double size, C col) {
  // 4-point star: long horizontal + vertical streaks, with a bright core
  for (var dy = -size.ceil(); dy <= size.ceil(); dy++) {
    for (var dx = -size.ceil(); dx <= size.ceil(); dx++) {
      final d = math.sqrt(dx * dx + dy * dy.toDouble());
      if (d > size) continue;
      // Core glow
      final core = math.exp(-(d * d) / (2 * (size * 0.25) * (size * 0.25)));
      // Cross arms
      final armH = math.exp(-(dy * dy.toDouble()) / (2 * (size * 0.10) * (size * 0.10))) *
          math.exp(-(dx.abs()) / size);
      final armV = math.exp(-(dx * dx.toDouble()) / (2 * (size * 0.10) * (size * 0.10))) *
          math.exp(-(dy.abs()) / size);
      final a = (core * 0.95 + armH * 0.55 + armV * 0.55).clamp(0.0, 1.0);
      if (a < 0.02) continue;
      _blendPx(im, (cx + dx).round(), (cy + dy).round(), col, a);
    }
  }
}

// ─── Pipeline ────────────────────────────────────────────────────────────────

img.Image _renderAt(int N,
    {required bool withBackground,
    required bool roundedBg,
    required double diamondScale}) {
  // Supersample at 2× then downscale with cubic for crisp AA edges
  const ss = 2;
  final S = N * ss;
  final image = img.Image(width: S, height: S, numChannels: 4);
  // Start fully transparent
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  if (withBackground) {
    _drawBackground(image, S, rounded: roundedBg);
  }

  _drawDiamond(image, S, scale: diamondScale);

  if (ss == 1) return image;
  return img.copyResize(
    image,
    width: N,
    height: N,
    interpolation: img.Interpolation.cubic,
  );
}

Future<void> _save(img.Image image, String path) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(img.encodePng(image));
  print('  ✓ ${path}  (${image.width}×${image.height})');
}

Future<void> main() async {
  print('Generating CaratOne premium app icon…');

  // 1. Master / legacy launcher icon — rounded square + diamond, 0.62 of canvas.
  //    flutter_launcher_icons reads this as the universal source.
  final master = _renderAt(1024,
      withBackground: true, roundedBg: true, diamondScale: 0.62);
  await _save(master, 'assets/icon/app_icon.png');

  // 2. Adaptive foreground — diamond only, transparent, sized to fit the 66%
  //    safe zone (Android 8+ adaptive icons crop the outer 33%).
  final fg = _renderAt(1024,
      withBackground: false, roundedBg: false, diamondScale: 0.46);
  await _save(fg, 'assets/icon/app_icon_foreground.png');

  // 3. Play Store listing icon — full bleed, no rounded corners (Play applies
  //    its own mask and rejects 512×512 uploads with transparency).
  final play = _renderAt(512,
      withBackground: true, roundedBg: false, diamondScale: 0.62);
  await _save(play, 'assets/icon/play_store_icon.png');

  print('\nNext steps:');
  print('  1. flutter pub get');
  print('  2. flutter pub run flutter_launcher_icons');
  print('  3. Upload assets/icon/play_store_icon.png to Google Play Console.');
}
