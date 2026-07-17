import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:Kelivo/utils/image_compressor.dart';

/// Project-root test fixture: a 512×512 RGBA PNG with transparent areas.
final _kelivoPng = File(p.join('assets', 'icons', 'kelivo.png'));

/// Create a test JPEG with photographic-style content.
File _createTestJpeg(Directory dir, String name, int w, int h) {
  final image = img.Image(width: w, height: h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      image.setPixelRgba(
        x,
        y,
        (x * 7) % 256,
        (y * 13) % 256,
        (x + y) % 256,
        255,
      );
    }
  }
  final f = File('${dir.path}/$name')
    ..writeAsBytesSync(img.encodeJpg(image, quality: 100));
  return f;
}

/// Create a fake GIF file (just header bytes).
File _createFakeGif(Directory dir) {
  return File('${dir.path}/test.gif')
    ..writeAsBytesSync(<int>[0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('img_compressor_test_');
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('ImageCompressor.compressIfNeeded', () {
    test('skips GIF files', () async {
      final f = _createFakeGif(tmpDir);
      final result = await ImageCompressor.compressIfNeeded(
        f.path,
        quality: 50,
      );
      expect(result, f.path);
    });

    test(
      'compresses a large JPEG with quality 30 and returns smaller file',
      () async {
        final f = _createTestJpeg(tmpDir, 'large.jpg', 800, 600);
        final origLen = f.lengthSync();
        final result = await ImageCompressor.compressIfNeeded(
          f.path,
          quality: 30,
        );
        expect(p.basename(result), 'large.jpg');
        expect(File(result).lengthSync(), lessThan(origLen));
      },
    );

    test('maxDimension resizes the image', () async {
      final f = _createTestJpeg(tmpDir, 'big.jpg', 400, 300);
      await ImageCompressor.compressIfNeeded(
        f.path,
        quality: 80,
        maxDimension: 100,
      );
      final decoded = img.decodeImage(await File(f.path).readAsBytes());
      expect(decoded, isNotNull);
      // longest edge (400) resized to 100; aspect ratio kept: 300→75
      expect(decoded!.width, 100);
      expect(decoded.height, 75);
    });

    test(
      'keepPng keeps PNG format for a real RGBA image with transparency',
      () async {
        expect(
          await _kelivoPng.exists(),
          isTrue,
          reason: 'test fixture missing',
        );
        final f = File('${tmpDir.path}/kelivo.png')
          ..writeAsBytesSync(await _kelivoPng.readAsBytes());
        final origLen = f.lengthSync();
        final result = await ImageCompressor.compressIfNeeded(
          f.path,
          quality: 80,
          keepPng: true,
        );
        expect(p.extension(result).toLowerCase(), '.png');
        expect(
          File(result).lengthSync(),
          lessThan(origLen * 2),
        ); // PNG re-compression at level 6
      },
    );

    test('returns original path for non-existent file', () async {
      final path = '${tmpDir.path}/nonexistent.png';
      final result = await ImageCompressor.compressIfNeeded(path, quality: 50);
      expect(result, path);
    });

    test(
      'compresses real kelivo.png (has transparency), keeps PNG, output valid',
      () async {
        expect(
          await _kelivoPng.exists(),
          isTrue,
          reason: 'test fixture missing',
        );
        final f = File('${tmpDir.path}/kelivo.png')
          ..writeAsBytesSync(await _kelivoPng.readAsBytes());
        // kelivo.png has real transparency → keep PNG via explicit option.
        final result = await ImageCompressor.compressIfNeeded(
          f.path,
          quality: 50,
          keepPng: true,
        );
        expect(p.extension(result).toLowerCase(), '.png');
        final decoded = img.decodeImage(await File(result).readAsBytes());
        expect(decoded, isNotNull);
      },
    );

    test('compresses opaque PNG (varied content), output valid', () async {
      final image = img.Image(width: 800, height: 600);
      for (int y = 0; y < 600; y++) {
        for (int x = 0; x < 800; x++) {
          image.setPixelRgba(
            x,
            y,
            (x * 7) % 256,
            (y * 13) % 256,
            (x + y) % 256,
            255,
          );
        }
      }
      final bytes = img.encodePng(image);
      final f = File('${tmpDir.path}/opaque.png')..writeAsBytesSync(bytes);

      final result = await ImageCompressor.compressIfNeeded(
        f.path,
        quality: 50,
      );
      expect(File(result).existsSync(), isTrue);
      final decoded = img.decodeImage(await File(result).readAsBytes());
      expect(decoded, isNotNull);
    });
  });

  group('ImageCompressor.probe', () {
    test('reports dimensions and no alpha for an opaque JPEG', () async {
      final f = _createTestJpeg(tmpDir, 'probe.jpg', 120, 80);
      final probe = await ImageCompressor.probe(f.path);
      expect(probe, isNotNull);
      expect(probe!.width, 120);
      expect(probe.height, 80);
      expect(probe.hasRealAlpha, isFalse);
    });

    test('detects real transparency in kelivo.png', () async {
      expect(await _kelivoPng.exists(), isTrue, reason: 'test fixture missing');
      final probe = await ImageCompressor.probe(_kelivoPng.path);
      expect(probe, isNotNull);
      expect(probe!.hasRealAlpha, isTrue);
    });

    test('reports dimensions and no real alpha for an opaque PNG', () async {
      final image = img.Image(width: 64, height: 48, numChannels: 4);
      img.fill(image, color: img.ColorRgba8(10, 20, 30, 255));
      final f = File('${tmpDir.path}/opaque_alpha.png')
        ..writeAsBytesSync(img.encodePng(image));
      final probe = await ImageCompressor.probe(f.path);
      expect(probe, isNotNull);
      expect(probe!.width, 64);
      expect(probe.height, 48);
      expect(probe.hasRealAlpha, isFalse);
    });

    test('returns null for a non-existent file', () async {
      expect(await ImageCompressor.probe('${tmpDir.path}/missing.png'), isNull);
    });
  });
}
