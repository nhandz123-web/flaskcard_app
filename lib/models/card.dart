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
  double easiness;
  int repetition;
  int interval;
  DateTime? nextReviewDate;

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
          : DateTime.now().toUtc(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now().toUtc(),
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
}
