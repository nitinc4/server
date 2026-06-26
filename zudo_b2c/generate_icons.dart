import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() async {
  print('Loading logo...');
  final logoBytes = File('../logo_transparent.png').readAsBytesSync();
  final srcLogo = img.decodePng(logoBytes);
  if (srcLogo == null) return;
  
  // Resize logo
  final logo = img.copyResize(srcLogo, width: 700, maintainAspect: true);
  
  final apps = [
    {'name': 'b2c', 'dir': 'zudo_b2c', 'c1': [0x1B, 0x5E, 0x20], 'c2': [0x66, 0xBB, 0x6A]},
    {'name': 'b2b', 'dir': 'zudo_b2b', 'c1': [0xE6, 0x51, 0x00], 'c2': [0xFF, 0xA7, 0x26]},
    {'name': 'delivery', 'dir': 'zudo_delivery', 'c1': [0x1A, 0x23, 0x7E], 'c2': [0x5C, 0x6B, 0xC0]},
  ];
  
  final int size = 1024;
  int offsetX = (size - logo.width) ~/ 2;
  int offsetY = (size - logo.height) ~/ 2;
  
  for (var app in apps) {
    print('Generating icon for ${app['name']}...');
    final bg = img.Image(width: size, height: size, numChannels: 4);
    final c1 = app['c1'] as List<int>;
    final c2 = app['c2'] as List<int>;
    
    // 1. Draw gradient background
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        double t = (x + y) / (size * 2);
        int r = (c1[0] + (c2[0] - c1[0]) * t).toInt();
        int g = (c1[1] + (c2[1] - c1[1]) * t).toInt();
        int b = (c1[2] + (c2[2] - c1[2]) * t).toInt();
        bg.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    // 2. Create foreground layer (transparent bg)
    final fg = img.Image(width: size, height: size, numChannels: 4);
    
    // Drop shadow
    print('Applying shadow...');
    final shadow = img.Image(width: size, height: size, numChannels: 4);
    img.compositeImage(shadow, logo, dstX: offsetX + 15, dstY: offsetY + 25);
    for (final p in shadow) {
      if (p.a > 0) {
        p.r = 0; p.g = 0; p.b = 0; p.a = (p.a * 0.4).toInt();
      }
    }
    final blurredShadow = img.gaussianBlur(shadow, radius: 15);
    
    // Tinted logo
    print('Tinting logo...');
    final tintedLogo = img.Image.from(logo);
    for (final p in tintedLogo) {
      if (p.a > 0) {
        p.r = 255; 
        p.g = 255; 
        p.b = 255;
        p.a = min(255, (p.a * 0.95).toInt());
      }
    }
    
    // Composite foreground
    img.compositeImage(fg, blurredShadow);
    img.compositeImage(fg, tintedLogo, dstX: offsetX, dstY: offsetY);
    
    // Composite FULL icon
    final fullIcon = img.Image.from(bg);
    img.compositeImage(fullIcon, fg);
    
    // Save all three
    final dir = app['dir'] as String;
    // from zudo_b2c, the target paths are:
    final basePath = dir == 'zudo_b2c' ? 'assets' : '../$dir/assets';
    
    File('$basePath/app_icon_generated.png').writeAsBytesSync(img.encodePng(fullIcon));
    File('$basePath/bg_generated.png').writeAsBytesSync(img.encodePng(bg));
    File('$basePath/fg_generated.png').writeAsBytesSync(img.encodePng(fg));
  }
  print('Done!');
}
