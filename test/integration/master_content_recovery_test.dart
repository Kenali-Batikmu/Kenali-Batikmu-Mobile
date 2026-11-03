import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/database/database_helper.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('Master Content Self-Healing (regresi konten kosong di perangkat)', () {
    test('memulihkan konten pilar dan galeri yang hilang dari asset', () async {
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);

      // Simulasikan kondisi perangkat yang datanya terhapus saat upgrade gagal
      await db!.delete('module_contents');
      await db.delete('module_gallery_images');

      final emptyContents = await db.rawQuery('SELECT COUNT(*) AS c FROM module_contents');
      expect(emptyContents.first['c'], equals(0));

      await DatabaseHelper.instance.ensureMasterContent();

      final contents = await db.rawQuery('SELECT COUNT(*) AS c FROM module_contents');
      final gallery = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM module_gallery_images WHERE image_url IS NOT NULL AND TRIM(image_url) <> ''",
      );

      expect(contents.first['c'], greaterThanOrEqualTo(240));
      expect(gallery.first['c'], greaterThanOrEqualTo(100));
    });

    test('setiap modul memiliki konten lengkap, pakem, gambar, dan galeri', () async {
      await DatabaseHelper.instance.ensureMasterContent();
      final modules = await DatabaseHelper.instance.getAllModules();

      expect(modules.length, equals(20));

      for (final module in modules) {
        final content = module.content;
        expect(content, isNotNull, reason: 'konten modul ${module.title} kosong');
        expect(content!.sejarahDanFilosofi.deskripsiUtama, isNotEmpty,
            reason: 'hakikat kosong pada ${module.title}');
        expect(content.sejarahDanFilosofi.asalDaerah, isNotEmpty);
        expect(content.sejarahDanFilosofi.maknaFilosofis, isNotEmpty);
        expect(content.sejarahDanFilosofi.penggunaan, isNotEmpty);
        expect(content.sumberRujukan, isNotEmpty,
            reason: 'rujukan kosong pada ${module.title}');
        expect(content.karakteristik.pakemList, isNotEmpty,
            reason: 'pakem kosong pada ${module.title}');
        expect(content.karakteristik.strukturUtama.image, isNotEmpty,
            reason: 'gambar struktur kosong pada ${module.title}');
        expect(content.galeri.length, equals(5),
            reason: 'galeri ${module.title} bukan 5 foto');
        expect(content.galeri.every((g) => g.imageUrl.isNotEmpty), isTrue,
            reason: 'ada foto galeri tanpa berkas pada ${module.title}');
      }
    });

    test('setiap modul memiliki tautan video youtube yang valid', () async {
      final db = await DatabaseHelper.instance.database;
      final rows = await db!.rawQuery(
        "SELECT title, video_url FROM modules WHERE video_url IS NULL OR TRIM(video_url) = ''",
      );
      expect(rows, isEmpty, reason: 'masih ada modul tanpa video');

      final modules = await DatabaseHelper.instance.getAllModules();
      for (final module in modules) {
        expect(module.content?.sejarahDanFilosofi.youtubeUrl, isNotEmpty);
      }
    });
  });
}
