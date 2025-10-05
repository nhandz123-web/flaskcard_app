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
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: (json['id'] as int?) ?? -1, // Gán -1 nếu null
      deckId: (json['deck_id'] as int?) ?? -1, // Gán -1 nếu null
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      phonetic: json['phonetic'] as String?,
      example: json['example'] as String?,
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      extra: json['extra'] != null ? Map<String, dynamic>.from(json['extra']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
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
    };
  }
}