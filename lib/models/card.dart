// lib/models/card.dart
class Card {
  final int id;
  final String front;
  final String back;
  final String? note;
  final String? imageUrl;  // Để lưu URL ảnh sau upload
  final int deckId;
  final int ownerId;  // Để check owner (nếu cần per-card)

  Card.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        front = json['front'],
        back = json['back'],
        note = json['note'],
        imageUrl = json['image_url'],
        deckId = json['deck_id'],
        ownerId = json['owner_id'];
}