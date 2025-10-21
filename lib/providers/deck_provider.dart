import 'package:flutter/foundation.dart';
import 'package:flashcard_app/models/deck.dart' as deck_model;
import 'package:flashcard_app/services/api_service.dart';

class DeckProvider extends ChangeNotifier {
  List<deck_model.Deck> _decks = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastSynced;

  List<deck_model.Deck> get decks => _decks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setDecks(List<deck_model.Deck> decks) {
    _decks = decks;
    _isLoading = false;
    _error = null;
    print('DeckProvider: Set decks with cardsCount: ${_decks.map((d) => d.cardsCount).toList()}');
    notifyListeners();
  }

  void updateDeck(deck_model.Deck updatedDeck) {
    final index = _decks.indexWhere((d) => d.id == updatedDeck.id);
    if (index >= 0) {
      _decks[index] = updatedDeck;
    } else {
      _decks.add(updatedDeck);
    }
    _isLoading = false;
    _error = null;
    print('DeckProvider: Updated deck ${updatedDeck.id} with cardsCount: ${updatedDeck.cardsCount}');
    notifyListeners();
  }

  void removeDeck(int deckId) {
    _decks.removeWhere((d) => d.id == deckId);
    _isLoading = false;
    _error = null;
    print('DeckProvider: Removed deck $deckId');
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

  Future<void> syncCardsCount(int deckId, ApiService api) async {
    if (_lastSynced != null && DateTime.now().difference(_lastSynced!).inSeconds < 60) {
      print('DeckProvider: Skipping sync for deck $deckId, using cached data');
      return;
    }
    try {
      setLoading(true);
      final cards = await api.getCards(deckId); // Lấy tổng số thẻ từ API getCards
      final index = _decks.indexWhere((d) => d.id == deckId);
      if (index >= 0) {
        _decks[index] = _decks[index].copyWith(cardsCount: cards.length);
      } else {
        final deck = await api.getDeck(deckId);
        _decks.add(deck.copyWith(cardsCount: cards.length));
      }
      _lastSynced = DateTime.now();
      print('DeckProvider: Synced total cards for deck $deckId to ${cards.length}');
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      setError('Lỗi khi đồng bộ số thẻ: $e');
      print('DeckProvider: Error syncing cardsCount for deck $deckId: $e');
    }
  }
}