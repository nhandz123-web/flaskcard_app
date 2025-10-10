import 'dart:convert';

class Card {
  final int id;
  final int deckId;
  final String front;
  final String back;
  final String? phonetic;
  final String? example;
  final String? imageUrl;
  final String? audioUrl;
  final Map<String, dynamic>? extra;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 🔹 Thêm các trường dùng cho thuật toán SM2
  double easiness; // Độ dễ (mặc định 2.5)
  int repetition; // Số lần lặp lại
  int interval; // Khoảng cách (ngày)
  DateTime? nextReviewDate; // Ngày ôn tiếp theo

  Card({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.phonetic,
    this.example,
    this.imageUrl,
    this.audioUrl,
    this.extra,
    required this.createdAt,
    required this.updatedAt,
    this.easiness = 2.5,
    this.repetition = 0,
    this.interval = 1,
    this.nextReviewDate,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: (json['id'] as int?) ?? -1,
      deckId: (json['deck_id'] as int?) ?? -1,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      phonetic: json['phonetic'] as String?,
      example: json['example'] as String?,
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      extra: json['extra'] != null ? Map<String, dynamic>.from(json['extra']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      easiness: (json['easiness'] ?? 2.5).toDouble(),
      repetition: json['repetition'] ?? 0,
      interval: json['interval'] ?? 1,
      nextReviewDate: json['next_review_date'] != null
          ? DateTime.parse(json['next_review_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deck_id': deckId,
      'front': front,
      'back': back,
      'phonetic': phonetic,
      'example': example,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'extra': extra,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'easiness': easiness,
      'repetition': repetition,
      'interval': interval,
      'next_review_date': nextReviewDate?.toIso8601String(),
    };
  }

  // 🔹 Cập nhật logic SM2 – khi người học đánh giá chất lượng ghi nhớ (0–5)
  void updateReview(int quality) {
    if (quality < 0 || quality > 5) {
      throw ArgumentError('Quality phải nằm trong khoảng 0–5');
    }

    if (quality < 3) {
      repetition = 0;
      interval = 1;
    } else {
      repetition += 1;
      if (repetition == 1) {
        interval = 1;
      } else if (repetition == 2) {
        interval = 6;
      } else {
        interval = (interval * easiness).round();
      }

      // Cập nhật độ dễ
      easiness += 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
      if (easiness < 1.3) easiness = 1.3;
    }

    // Ngày ôn lại kế tiếp
    nextReviewDate = DateTime.now().add(Duration(days: interval));
  }

  // 🔹 Kiểm tra thẻ có đến hạn ôn chưa
  bool get isDueToday =>
      nextReviewDate != null &&
          nextReviewDate!.isBefore(DateTime.now().add(const Duration(days: 1)));
}
