class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImagePath;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImagePath,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      profileImagePath: map['profile_image_path'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? profileImagePath,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BatikMotifModel {
  final int id;
  final String name;
  final String slug;
  final String originRegion;
  final String shortDescription;
  final String? thumbnailUrl;
  final int mlClassIndex;

  BatikMotifModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.originRegion,
    required this.shortDescription,
    this.thumbnailUrl,
    required this.mlClassIndex,
  });

  factory BatikMotifModel.fromMap(Map<String, dynamic> map) {
    return BatikMotifModel(
      id: map['id'] as int,
      name: map['name'] as String,
      slug: map['slug'] as String,
      originRegion: map['origin_region'] as String,
      shortDescription: map['short_description'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      mlClassIndex: map['ml_class_index'] as int,
    );
  }
}

class SejarahFilosofiModel {
  final String youtubeUrl;
  final String deskripsiUtama;
  final String asalDaerah;
  final String maknaFilosofis;
  final String penggunaan;

  SejarahFilosofiModel({
    required this.youtubeUrl,
    required this.deskripsiUtama,
    required this.asalDaerah,
    required this.maknaFilosofis,
    required this.penggunaan,
  });

  factory SejarahFilosofiModel.fromMap(Map<String, dynamic> map) {
    return SejarahFilosofiModel(
      youtubeUrl: map['youtubeUrl'] ?? '',
      deskripsiUtama: map['deskripsiUtama'] ?? '',
      asalDaerah: map['asalDaerah'] ?? '',
      maknaFilosofis: map['maknaFilosofis'] ?? '',
      penggunaan: map['penggunaan'] ?? '',
    );
  }
}

class KarakteristikDetailModel {
  final String title;
  final String desc;
  final String badge;
  final String image;

  KarakteristikDetailModel({
    required this.title,
    required this.desc,
    required this.badge,
    required this.image,
  });

  factory KarakteristikDetailModel.fromMap(Map<String, dynamic> map) {
    return KarakteristikDetailModel(
      title: map['title'] ?? '',
      desc: map['desc'] ?? '',
      badge: map['badge'] ?? '',
      image: map['image'] ?? '',
    );
  }
}

class PakemModel {
  final String title;
  final String desc;

  PakemModel({required this.title, required this.desc});

  factory PakemModel.fromMap(Map<String, dynamic> map) {
    return PakemModel(
      title: map['title'] ?? '',
      desc: map['desc'] ?? '',
    );
  }
}

class KarakteristikModel {
  final String deskripsi;
  final KarakteristikDetailModel strukturUtama;
  final KarakteristikDetailModel ornamen;
  final KarakteristikDetailModel warna;
  final List<PakemModel> pakemList;

  KarakteristikModel({
    required this.deskripsi,
    required this.strukturUtama,
    required this.ornamen,
    required this.warna,
    required this.pakemList,
  });

  factory KarakteristikModel.fromMap(Map<String, dynamic> map) {
    var pakemData = map['pakemList'] as List? ?? [];
    return KarakteristikModel(
      deskripsi: map['deskripsi'] ?? '',
      strukturUtama: KarakteristikDetailModel.fromMap(map['strukturUtama'] ?? {}),
      ornamen: KarakteristikDetailModel.fromMap(map['ornamen'] ?? {}),
      warna: KarakteristikDetailModel.fromMap(map['warna'] ?? {}),
      pakemList: pakemData.map((e) => PakemModel.fromMap(e)).toList(),
    );
  }
}

class GaleriModel {
  final String imageUrl;
  final String caption;

  GaleriModel({required this.imageUrl, required this.caption});

  factory GaleriModel.fromMap(Map<String, dynamic> map) {
    return GaleriModel(
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
    );
  }
}

class ModuleContentModel {
  final String origin;
  final String estimatedTime;
  final SejarahFilosofiModel sejarahDanFilosofi;
  final KarakteristikModel karakteristik;
  final List<GaleriModel> galeri;

  ModuleContentModel({
    required this.origin,
    required this.estimatedTime,
    required this.sejarahDanFilosofi,
    required this.karakteristik,
    required this.galeri,
  });

  factory ModuleContentModel.fromMap(Map<String, dynamic> map) {
    var galeriData = map['galeri'] as List? ?? [];
    return ModuleContentModel(
      origin: map['origin'] ?? '',
      estimatedTime: map['estimatedTime'] ?? '',
      sejarahDanFilosofi: SejarahFilosofiModel.fromMap(map['sejarahDanFilosofi'] ?? {}),
      karakteristik: KarakteristikModel.fromMap(map['karakteristik'] ?? {}),
      galeri: galeriData.map((e) => GaleriModel.fromMap(e)).toList(),
    );
  }
}

class ModuleModel {
  final int id;
  final int motifId;
  final String title;
  final String description;
  final String? coverImage;
  final int passingScore;
  final int orderNo;
  final int progressPercent;
  final bool historyDone;
  final bool characterDone;
  final bool galleryDone;
  final bool quizDone;
  final bool practiceDone;
  final int? quizScore;
  final int? practiceScore;
  
  // Menambahkan content model dinamis
  final ModuleContentModel? content;

  ModuleModel({
    required this.id,
    required this.motifId,
    required this.title,
    required this.description,
    this.coverImage,
    this.passingScore = 70,
    required this.orderNo,
    this.progressPercent = 0,
    this.historyDone = false,
    this.characterDone = false,
    this.galleryDone = false,
    this.quizDone = false,
    this.practiceDone = false,
    this.quizScore,
    this.practiceScore,
    this.content,
  });

  // Helper method untuk copyWith
  ModuleModel copyWith({
    int? progressPercent,
    bool? historyDone,
    bool? characterDone,
    bool? galleryDone,
    bool? quizDone,
    bool? practiceDone,
    int? quizScore,
    int? practiceScore,
  }) {
    return ModuleModel(
      id: id,
      motifId: motifId,
      title: title,
      description: description,
      coverImage: coverImage,
      passingScore: passingScore,
      orderNo: orderNo,
      progressPercent: progressPercent ?? this.progressPercent,
      historyDone: historyDone ?? this.historyDone,
      characterDone: characterDone ?? this.characterDone,
      galleryDone: galleryDone ?? this.galleryDone,
      quizDone: quizDone ?? this.quizDone,
      practiceDone: practiceDone ?? this.practiceDone,
      quizScore: quizScore ?? this.quizScore,
      practiceScore: practiceScore ?? this.practiceScore,
      content: content,
    );
  }
}

class QuizQuestionModel {
  final int id;
  final int moduleId;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String? explanation;

  QuizQuestionModel({
    required this.id,
    required this.moduleId,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanation,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      id: map['id'] as int,
      moduleId: map['module_id'] as int,
      question: map['question'] as String,
      optionA: map['option_a'] as String,
      optionB: map['option_b'] as String,
      optionC: map['option_c'] as String,
      optionD: map['option_d'] as String,
      correctOption: map['correct_option'] as String,
      explanation: map['explanation'] as String?,
    );
  }
}

class ScanHistoryModel {
  final int id;
  final String scanType;
  final String? motifName;
  final double score;
  final bool passed;
  final String createdAt;

  ScanHistoryModel({
    required this.id,
    required this.scanType,
    this.motifName,
    required this.score,
    required this.passed,
    required this.createdAt,
  });
}
