import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mantra Manifest Completeness & Audio Specifications Tests', () {
    late Map<String, dynamic> manifest;

    setUpAll(() async {
      final file = File('assets/audio/mantra_manifest.json');
      expect(file.existsSync(), isTrue, reason: 'mantra_manifest.json must exist');
      final content = await file.readAsString();
      manifest = json.decode(content) as Map<String, dynamic>;
    });

    test('Manifest metadata contains exactly 455 recordings', () {
      expect(manifest['total_recordings'], equals(455));
      final List recordings = manifest['recordings'];
      expect(recordings.length, equals(455));
    });

    test('100% of recordings have verified text mappings with zero flagged', () {
      expect(manifest['verified_count'], equals(455));
      expect(manifest['flagged_count'], equals(0));
    });

    test('Collection breakdown matches physical audio library verification', () {
      final breakdown = manifest['collections_breakdown'] as Map<String, dynamic>;
      expect(breakdown['Surya'], equals(86));
      expect(breakdown['Shiva'], equals(80));
      expect(breakdown['Venkateswara'], equals(75));
      expect(breakdown['Lakshmi Devi'], equals(67));
      expect(breakdown['Bhairava'], equals(64));
      expect(breakdown['Maha Vidyas'], equals(5));
      expect(breakdown['Assorted deities'], equals(78));
    });

    test('Every recording adheres to 48 kHz, 16-bit stereo master specifications', () {
      final List recordings = manifest['recordings'];
      for (final rec in recordings) {
        expect(rec['sample_rate'], equals(48000), reason: '${rec['filename']} sample rate');
        expect(rec['bit_depth'], equals(16), reason: '${rec['filename']} bit depth');
        expect(rec['channels'], equals(2), reason: '${rec['filename']} channels');
        expect(rec['duration_seconds'], greaterThan(0.0), reason: '${rec['filename']} duration');
        expect(rec['file_size_bytes'], greaterThan(0), reason: '${rec['filename']} file size');
        expect((rec['sha256'] as String).length, equals(64), reason: '${rec['filename']} SHA256');
        expect((rec['mantra'] as String).isNotEmpty, isTrue, reason: '${rec['filename']} mantra text');
      }
    });

    test('Bundled offline audio assets exist on disk with valid file size', () {
      final List recordings = manifest['recordings'];
      final bundled = recordings.where((r) => r['is_bundled'] == true).toList();
      expect(bundled.length, equals(31));

      for (final b in bundled) {
        final path = b['bundled_asset_path'] as String;
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Bundled asset file must exist: $path');
        expect(file.lengthSync(), greaterThan(10000), reason: 'Bundled asset non-empty: $path');
      }
    });
  });
}
