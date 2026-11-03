import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/database/database_helper.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('Master Content Self-Healing (regresi konten kosong di perangkat)', () {
    test('memulihkan data versi lama (253 konten tanpa rujukan & tanpa foto)', () async {
      final db = await DatabaseHelper.instance.database;
      await DatabaseHelper.instance.ensureMasterContent();

      // Tiru kondisi database lama: konten banyak tetapi tanpa penanda kurasi
      await db!.delete('module_contents', where: "title = 'Sumber & Rujukan'");
      await db.update('module_contents', {'image_url': null});
      await db.update('module_gallery_images', {'image_url': null});

      final oldSumber = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM module_contents WHERE title = 'Sumber & Rujukan'",
      );
      final oldGallery = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM module_gallery_images WHERE image_url IS NOT NULL AND TRIM(image_url) <> ''",
      );
      expect(oldSumber.first['c'], equals(0));
      expect(oldGallery.first['c'], equals(0));

      await DatabaseHelper.instance.ensureMasterContent();

      final sumber = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM module_contents WHERE title = 'Sumber & Rujukan'",
      );
      final gallery = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM module_gallery_images WHERE image_url IS NOT NULL AND TRIM(image_url) <> ''",
      );
      final karakterImages = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM module_contents WHERE pillar = 'karakteristik' AND image_url IS NOT NULL AND TRIM(image_url) <> ''",
      );

      expect(sumber.first['c'], equals(20));
      expect(gallery.first['c'], greaterThanOrEqualTo(100));
      expect(karakterImages.first['c'], greaterThanOrEqualTo(60));
    });

    test('DAO tetap menampilkan foto walau galeri belum tersegarkan', () async {
      final db = await DatabaseHelper.instance.database;
      await DatabaseHelper.instance.ensureMasterContent();

      // Kosongkan galeri satu modul untuk menguji jalur cadangan
      await db!.delete('module_gallery_images', where: 'module_id = ?', whereArgs: [4]);
      await db.update(
        'module_contents',
        {'image_url': null},
        where: 'module_id = ?',
        whereArgs: [4],
      );

      final modules = await DatabaseHelper.instance.getAllModules();
      final dayak = modules.firstWhere((m) => m.id == 4);
      final content = dayak.content;

      expect(content, isNotNull);
      expect(content!.galeri, isNotEmpty);
      expect(content.galeri.first.imageUrl, isNotEmpty,
          reason: 'galeri harus memakai cover modul sebagai cadangan');
      expect(content.karakteristik.strukturUtama.image, isNotEmpty,
          reason: 'kartu karakteristik harus tetap punya foto');
      expect(content.karakteristik.ornamen.image, isNotEmpty);
      expect(content.karakteristik.warna.image, isNotEmpty);
    });

    test('memulihkan konten pilar dan galeri yang hilang dari asset', () async {
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);

      // Simulasikan kondisi perangkat yang datanya terhapus saat upgrade gagal
      await db!.delete('module_contents');
      await db.delete('module_gallery_images');
      await db.update('modules', {'title': 'Mengenal Batik Lama', 'video_url': null});
      await db.insert('module_gallery_images', {
        'module_id': 1,
        'image_url': '',
        'caption': 'Lama',
        'order_no': 1,
      });

      final emptyContents = await db.rawQuery('SELECT COUNT(*) AS c FROM module_contents');
      expect(emptyContents.first['c'], equals(0));

      await DatabaseHelper.instance.ensureMasterContent();

      final contents = await db.rawQuery('SELECT COUNT(*) AS c FROM module_contents');
      final gallery = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM module_gallery_images WHERE image_url IS NOT NULL AND TRIM(image_url) <> ''",
      );
      final title = await db.rawQuery('SELECT title FROM modules WHERE id = 1');
      final video = await db.rawQuery('SELECT video_url FROM modules WHERE id = 1');

      expect(contents.first['c'], greaterThanOrEqualTo(240));
      expect(gallery.first['c'], greaterThanOrEqualTo(100));
      expect(title.first['title'], equals('Batik Betawi'));
      expect(video.first['video_url'], isNotEmpty);
    });

    test('sinkronisasi cloud tidak menimpa data kurasi lokal', () async {
      final db = await DatabaseHelper.instance.database;
      await DatabaseHelper.instance.ensureMasterContent();

      final before = await db!.rawQuery(
        'SELECT title, cover_image, video_url FROM modules WHERE id = 9',
      );

      // Payload cloud lama: judul generik, cover/video kosong
      await DatabaseHelper.instance.upsertModules([
        {
          'id': 9,
          'motif_id': 9,
          'title': 'Mengenal Batik Parang',
          'description': 'Deskripsi lama',
          'cover_image': '',
          'video_url': null,
          'passing_score': 70,
          'order_no': 19,
        },
      ]);

      final after = await db.rawQuery(
        'SELECT title, cover_image, video_url FROM modules WHERE id = 9',
      );

      expect(after.first['title'], equals(before.first['title']));
      expect(after.first['cover_image'], equals(before.first['cover_image']));
      expect(after.first['video_url'], equals(before.first['video_url']));
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
