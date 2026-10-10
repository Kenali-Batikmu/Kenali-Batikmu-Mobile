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
  });
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
