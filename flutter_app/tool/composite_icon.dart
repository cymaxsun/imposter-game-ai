import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final bgPath = 'assets/images/submarine_bg.png';
  final sharkPath =
      'assets/images/sharksplash.png'; // Original rectangular image
  final outPath = 'assets/images/sharksplash_submarine.png';

  print('Loading $bgPath...');
  final bgFile = File(bgPath);
  if (!bgFile.existsSync()) {
    print('Background file NOT found: $bgPath');
    exit(1);
  }
  final bgImage = decodeImage(bgFile.readAsBytesSync());
  if (bgImage == null) {
    print('Failed to decode background image.');
    exit(1);
  }

  print('Loading $sharkPath...');
  final sharkFile = File(sharkPath);
  if (!sharkFile.existsSync()) {
    print('Shark file not found!');
    exit(1);
  }
  final sharkImage = decodeImage(sharkFile.readAsBytesSync());
  if (sharkImage == null) {
    print('Failed to decode shark image.');
    exit(1);
  }

  // Ensure background is square (resize if needed, or crop center)
  Image finalBg;
  if (bgImage.width != bgImage.height) {
    final size = bgImage.width < bgImage.height
        ? bgImage.width
        : bgImage.height;
    final x = (bgImage.width - size) ~/ 2;
    final y = (bgImage.height - size) ~/ 2;
    finalBg = copyCrop(bgImage, x: x, y: y, width: size, height: size);
  } else {
    finalBg = bgImage;
  }

  // ------ EXTRACT SHARK CONTENT ------
  int minX = sharkImage.width;
  int minY = sharkImage.height;
  int maxX = 0;
  int maxY = 0;
  bool foundContent = false;

  for (int y = 0; y < sharkImage.height; y++) {
    for (int x = 0; x < sharkImage.width; x++) {
      if (sharkImage.getPixel(x, y).a > 0) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        foundContent = true;
      }
    }
  }

  if (!foundContent) {
    print('Shark image is empty!');
    exit(1);
  }

  final contentWidth = maxX - minX + 1;
  final contentHeight = maxY - minY + 1;
  final sharkContent = copyCrop(
    sharkImage,
    x: minX,
    y: minY,
    width: contentWidth,
    height: contentHeight,
  );

  // ------ RESIZE SHARK ------
  // Increased scale from 0.85 to 0.95
  final targetSize = (finalBg.width * 0.95).toInt();

  // Scale shark to fit within targetDimensions
  // Maintain aspect ratio
  final aspect = contentWidth / contentHeight;
  int newSharkWidth, newSharkHeight;

  if (contentWidth > contentHeight) {
    newSharkWidth = targetSize;
    newSharkHeight = (targetSize / aspect).toInt();
  } else {
    newSharkHeight = targetSize;
    newSharkWidth = (targetSize * aspect).toInt();
  }

  print(
    'Resizing shark content to ${newSharkWidth}x${newSharkHeight} (Scale: 95%)...',
  );
  final resizedShark = copyResize(
    sharkContent,
    width: newSharkWidth,
    height: newSharkHeight,
    interpolation: Interpolation.linear,
  );

  // ------ COMPOSITE ------
  final centerX = (finalBg.width - newSharkWidth) ~/ 2;
  final centerY = (finalBg.height - newSharkHeight) ~/ 2;

  print('Compositing at $centerX, $centerY...');
  compositeImage(finalBg, resizedShark, dstX: centerX, dstY: centerY);

  print('Saving to $outPath...');
  File(outPath).writeAsBytesSync(encodePng(finalBg));
  print('Done.');
}
