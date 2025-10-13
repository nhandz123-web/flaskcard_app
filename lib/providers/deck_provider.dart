import 'package:flutter/foundation.dart';
import 'package:flashcard_app/models/deck.dart' as deck_model;

class DeckProvider extends ChangeNotifier {
  List<deck_model.Deck> _decks = [];
  bool _isLoading = false;
  String? _error;

  List<deck_model.Deck> get decks => _decks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setDecks(List<deck_model.Deck> decks) {
    _decks = decks;
    _isLoading = false;
    _error = null;
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
    notifyListeners();
  }

  void removeDeck(int deckId) {
    _decks.removeWhere((d) => d.id == deckId);
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void updateCardsCount(int deckId, int change) {
    final index = _decks.indexWhere((d) => d.id == deckId);
    if (index >= 0) {
      _decks[index] = _decks[index].copyWith(
        cardsCount: _decks[index].cardsCount + change,
      );
      notifyListeners();
    }
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
}