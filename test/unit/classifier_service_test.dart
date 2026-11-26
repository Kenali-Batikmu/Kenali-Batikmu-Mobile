import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:batikmu/core/services/classifier_service.dart';
import 'package:batikmu/models/app_models.dart';
import '../test_helper.dart';

Uint8List _createSolidPngBytes({
  int width = 64,
  int height = 64,
  int r = 255,
  int g = 255,
  int b = 255,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  setupTestEnvironment();

  group('QC Unit Tests: BatikClassifierService (On-Device AI & BVA)', () {
    final service = BatikClassifierService.instance;

    test('formatMotifName mengubah slug model menjadi nama motif berformat Title Case', () {
      expect(service.formatMotifName('batik_mega_mendung'), equals('Mega Mendung'));
      expect(service.formatMotifName('batik_parang'), equals('Parang'));
      expect(service.formatMotifName('kawung'), equals('Kawung'));
      expect(service.formatMotifName(''), equals(''));
    });

    test('[BVA] getRatingLabel & getRatingDisplay konsisten dengan batas KKM 70% inklusif dan 50%', () {
      // Di bawah 50% -> perlu_dilatih
      expect(BatikClassifierService.getRatingLabel(0.0), equals('perlu_dilatih'));
      expect(BatikClassifierService.getRatingLabel(0.49), equals('perlu_dilatih'));
      expect(BatikClassifierService.getRatingDisplay(49.0), equals('Perlu Dilatih'));

      // Rentang 50%..69% -> cukup_mirip
      expect(BatikClassifierService.getRatingLabel(0.50), equals('cukup_mirip'));
      expect(BatikClassifierService.getRatingLabel(0.69), equals('cukup_mirip'));
      expect(BatikClassifierService.getRatingDisplay(65.0), equals('Cukup Mirip'));

      // Nilai di atas 70% -> sangat_mirip
      expect(BatikClassifierService.getRatingLabel(0.71), equals('sangat_mirip'));
      expect(BatikClassifierService.getRatingDisplay(90.0), equals('Sangat Mirip'));

      // Boundary Value Analysis tepat di KKM 70% (standar KKM pendidikan >= 70% = lulus / Sangat Mirip)
      expect(
        BatikClassifierService.getRatingLabel(0.70),
        equals('sangat_mirip'),
        reason: 'Standar BVA KKM 70%: nilai tepat 0.70 (70%) seharusnya memenuhi ambang kelulusan/Sangat Mirip',
      );
    });

    test('[Negative/Fault] menolak byte kosong, data korup, dan file tidak ada tanpa crash', () async {
      expect(await service.classifyBytes(Uint8List(0)), isEmpty);
      expect(await service.classifyBytes(Uint8List.fromList([0, 1, 2, 3, 4, 5])), isEmpty);
      expect(
        await service.classifyTopK(File('C:/path_tidak_mungkin_ada_999999.jpg')),
        isEmpty,
      );
      expect(await service.classifyTopK('tipe_tidak_didukung'), isEmpty);

      final moduleResult = await service.classifyForModule(
        Uint8List(0),
        targetMotifId: 1,
        targetMotifSlug: 'parang',
        targetModuleTitle: 'Batik Parang',
      );
      expect(moduleResult, isNull);
    });

    test('classifyBytes menghasilkan distribusi probabilitas valid, terurut menurun, dan sesuai batas k', () async {
      final samplePng = _createSolidPngBytes(r: 120, g: 80, b: 40);
      final results = await service.classifyBytes(samplePng, k: 5);

      expect(results.length, lessThanOrEqualTo(5));
      for (int i = 0; i < results.length; i++) {
        expect(results[i].confidence, inInclusiveRange(0.0, 1.0));
        if (i > 0) {
          expect(
            results[i - 1].confidence,
            greaterThanOrEqualTo(results[i].confidence),
            reason: 'Hasil Top-K wajib terurut dari confidence tertinggi ke terendah',
          );
        }
      }
    });

    test('[AI Integrity QC] tidak boleh memalsukan prediksi batik jika interpreter TFLite tidak tersedia atau gambar polos non-batik', () async {
      // Standar industri ML/QC:
      // 1. Jika native interpreter TFLite gagal dimuat (hasInterpreter == false),
      //    sistem tidak boleh menghasilkan prediksi tiruan/sintetis yang seolah-olah hasil AI asli.
      // 2. Gambar putih polos (non-batik) tidak boleh mendapat skor keyakinan tinggi sebagai motif batik.
      final blankWhitePng = _createSolidPngBytes(r: 255, g: 255, b: 255);
      final results = await service.classifyBytes(blankWhitePng, k: 5);

      if (!service.hasInterpreter) {
        expect(
          results,
          isEmpty,
          reason:
              'Tanpa interpreter TFLite aktif, service tidak boleh memproduksi skor fallback acak yang menipu pengguna seolah AI bekerja',
        );
      } else if (results.isNotEmpty) {
        expect(
          results.first.confidence,
          lessThan(0.50),
          reason: 'Gambar putih polos non-batik tidak boleh diklasifikasi dengan confidence tinggi',
        );
      }
    });

    test('classifyForModule memetakan motif target berdasarkan availableMotifs', () async {
      final samplePng = _createSolidPngBytes(r: 90, g: 50, b: 25);
      final motifs = [
        BatikMotifModel(
          id: 7,
          slug: 'mega_mendung',
          name: 'Batik Mega Mendung',
          originRegion: 'Cirebon',
          shortDescription: 'Motif awan khas Cirebon',
          mlClassIndex: 0,
        ),
      ];

      final res = await service.classifyForModule(
        samplePng,
        targetMotifId: 7,
        targetMotifSlug: 'mega_mendung',
        targetModuleTitle: 'Batik Mega Mendung',
        availableMotifs: motifs,
      );

      expect(res, isNotNull);
      expect(res!.motifId, equals(7));
      expect(res.motifName, equals('Batik Mega Mendung'));
      expect(res.confidence, inInclusiveRange(0.0, 1.0));
    });
  });
}
