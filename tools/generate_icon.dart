import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  // Create a 1024x1024 image
  final image = img.Image(width: 1024, height: 1024);
  
  // Fill with dark blue to black gradient background
  for (int y = 0; y < 1024; y++) {
    for (int x = 0; x < 1024; x++) {
      // Create gradient from dark blue (#1a1a2e) to black (#0f0f1e)
      final ratio = (x + y) / (1024 * 2);
      final r = (26 + (15 - 26) * ratio).round().clamp(0, 255);
      final g = (26 + (15 - 26) * ratio).round().clamp(0, 255);
      final b = (46 + (30 - 46) * ratio).round().clamp(0, 255);
      image.setPixel(x, y, img.ColorRgb8(r, g, b));
    }
  }
  
  // Draw diamond shape
  const centerX = 512.0;
  const centerY = 440.0;
  const diamondWidth = 360.0;
  const diamondHeight = 320.0;
  
  // Fill diamond with blue gradient
  for (int y = 0; y < 1024; y++) {
    for (int x = 0; x < 1024; x++) {
      final dx = (x - centerX).abs();
      final dy = (y - centerY).abs();
      
      // Check if inside diamond (diamond shape)
      final inDiamond = (dx / (diamondWidth / 2) + dy / (diamondHeight / 2)) <= 1;
      
      if (inDiamond) {
        // Blue gradient for diamond - lighter at top, darker at bottom
        final ratio = (y - (centerY - diamondHeight / 2)) / diamondHeight;
        final r = (30 + (74 - 30) * ratio).round().clamp(0, 255);
        final g = (92 + (144 - 92) * ratio).round().clamp(0, 255);
        final b = (138 + (226 - 138) * ratio).round().clamp(0, 255);
        
        // Add some highlight on left side
        if (x < centerX) {
          final highlight = ((centerX - x) / (diamondWidth / 2) * 50).round();
          final newR = (r + highlight).clamp(0, 255);
          final newG = (g + highlight).clamp(0, 255);
          final newB = (b + highlight).clamp(0, 255);
          image.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
        } else {
          image.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
    }
  }
  
  // Draw white "C" letter - simplified thick C
  const cSize = 280.0;
  final cX = centerX;
  final cY = centerY;
  const cThickness = 50.0;
  final cRadius = cSize / 2;
  
  for (int y = (cY - cRadius).round(); y < (cY + cRadius).round(); y++) {
    for (int x = (cX - cRadius).round(); x < (cX + cRadius).round(); x++) {
      final dx = x - cX;
      final dy = y - cY;
      final dist = math.sqrt(dx * dx + dy * dy);
      
      // Draw C shape (open on the right side, between -30 and 30 degrees)
      if (dist >= (cRadius - cThickness) && dist <= cRadius) {
        final angle = math.atan2(dy, dx);
        // C is open on right side (between -30 and 30 degrees)
        if (dx < 0 || (dx >= 0 && (angle < -math.pi / 6 || angle > math.pi / 6))) {
          image.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        }
      }
    }
  }
  
  // Draw "CaratOne" text below (simplified - just draw text area)
  const textY = 750;
  const textHeight = 80;
  // Simple text representation - draw white pixels for text area
  for (int y = textY - textHeight ~/ 2; y < textY + textHeight ~/ 2; y++) {
    for (int x = 200; x < 824; x++) {
      // Simple text area - you could enhance this with actual text rendering
      if ((x - 512).abs() < 300 && (y - textY).abs() < textHeight / 2) {
        // Draw a simple representation
        final pattern = (x ~/ 20) % 2;
        if (pattern == 0 && (y - textY).abs() < 30) {
          image.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        }
      }
    }
  }
  
  // Save as PNG
  final pngBytes = img.encodePng(image);
  final file = File('assets/icon/app_icon.png');
  file.createSync(recursive: true);
  file.writeAsBytesSync(pngBytes);
  
  print('Icon generated successfully at assets/icon/app_icon.png');
}
