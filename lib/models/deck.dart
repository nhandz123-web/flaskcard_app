// lib/models/deck.dart
class Deck {
  final int id;
  final String title;
  final String description;
  final bool isPublic;
  final int cardsCount;
  final int ownerId;  // Để check owner

  Deck.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'] ?? '',
        isPublic = json['is_public'] ?? false,
        cardsCount = json['cards_count'] ?? 0,
        ownerId = json['owner_id'];
}
