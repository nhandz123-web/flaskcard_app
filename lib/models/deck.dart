class Deck {
  final int id;
  final int userId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int cardsCount;

  Deck({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.cardsCount,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as int? ?? 0, // Sử dụng 0 nếu id là null
      userId: json['user_id'] as int? ?? 0, // Sử dụng 0 nếu user_id là null
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cardsCount: json['cards_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}