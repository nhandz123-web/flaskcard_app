class Deck {
  final int id;
  final int userId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int cardsCount; // Tổng số thẻ
  final int reviewCardsCount; // Số thẻ cần ôn tập

  Deck({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.cardsCount,
    this.reviewCardsCount = 0, // Mặc định 0
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cardsCount: json['cards_count'] as int? ?? 0,
      reviewCardsCount: json['review_cards_count'] as int? ?? 0, // Thêm trường
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
    'cards_count': cardsCount,
    'review_cards_count': reviewCardsCount, // Thêm trường
  };

  Deck copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cardsCount,
    int? reviewCardsCount,
  }) {
    return Deck(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardsCount: cardsCount ?? this.cardsCount,
      reviewCardsCount: reviewCardsCount ?? this.reviewCardsCount, // Thêm trường
    );
  }
}