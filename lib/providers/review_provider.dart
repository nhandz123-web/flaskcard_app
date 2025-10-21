import 'package:flutter/foundation.dart';
import 'package:flashcard_app/services/api_service.dart';

class ReviewProvider extends ChangeNotifier {
  Map<int, int> _reviewCounts = {}; // Map từ deckId đến số thẻ cần ôn
  bool _isLoading = false;
  String? _error;

  Map<int, int> get reviewCounts => _reviewCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setReviewCount(int deckId, int count) {
    _reviewCounts[deckId] = count.clamp(0, 9999); // Giới hạn để tránh giá trị âm hoặc quá lớn
    print('ReviewProvider: Set review count for deck $deckId to $count');
    notifyListeners();
  }

  void updateReviewCount(int deckId, int change) {
    final current = _reviewCounts[deckId] ?? 0;
    final newCount = (current + change).clamp(0, 9999);
    _reviewCounts[deckId] = newCount;
    print('ReviewProvider: Updated review count for deck $deckId to $newCount');
    notifyListeners();
  }

  void removeDeck(int deckId) {
    _reviewCounts.remove(deckId);
    print('ReviewProvider: Removed deck $deckId');
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncReviewCounts(List<int> deckIds, ApiService api) async {
    setLoading(true);
    try {
      for (var deckId in deckIds) {
        final cards = await api.getCardsToReview(deckId);
        setReviewCount(deckId, cards.length);
      }
      _error = null;
    } catch (e) {
      setError('Lỗi khi đồng bộ số thẻ ôn tập: $e');
      print('ReviewProvider: Error syncing review counts: $e');
    } finally {
      setLoading(false);
    }
  }
}