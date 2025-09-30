import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/card.dart' as card_model;
import '../models/deck.dart' as deck_model;
import '../providers/user_provider.dart';

class CardsPage extends StatefulWidget {
  final ApiService api;
  final int deckId;
  final deck_model.Deck? deck;

  const CardsPage({super.key, required this.api, required this.deckId, this.deck});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  late Future<Map<String, dynamic>> _cardsResponse;
  int _currentPage = 1;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    if (widget.deck == null) {
      _cardsResponse = widget.api.getDeck(widget.deckId).then((deck) {
        return widget.api.getCardsResponse(widget.deckId, page: _currentPage).then((cardsResponse) {
          return {'deck': deck, ...cardsResponse};
        });
      }) as Future<Map<String, dynamic>>;
    } else {
      _loadCards();
      _updateOwnerStatus(widget.deck!);
    }
    Provider.of<UserProvider>(context, listen: false).loadUser();
  }

  void _loadCards() {
    _cardsResponse = widget.api.getCardsResponse(widget.deckId, page: _currentPage).catchError((e) {
      print('Lỗi khi tải cards: $e'); // Debug log
      return {'data': [], 'last_page': 1}; // Trả về dữ liệu mặc định nếu lỗi
    });
  }

  void _nextPage() {
    final responseData = _cardsResponse;
    responseData.then((data) {
      if (_currentPage < (data['last_page'] as int)) {
        setState(() {
          _currentPage++;
          _loadCards();
        });
      }
    });
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _loadCards();
      });
    }
  }

  void _updateOwnerStatus(deck_model.Deck deck) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _isOwner = userProvider.userId != null && userProvider.userId == deck.userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building CardsPage for deckId: ${widget.deckId}, currentPage: $_currentPage'); // Debug log
    return Scaffold(
      appBar: AppBar(title: Text('Cards - Deck ${widget.deckId}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _cardsResponse,
        builder: (context, snapshot) {
          print('CardsPage FutureBuilder snapshot: ${snapshot.data}, hasError: ${snapshot.hasError}, error: ${snapshot.error}'); // Debug log
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final response = snapshot.data!;
          final cards = (response['data'] as List).map((e) => card_model.Card.fromJson(e)).toList();
          final deck = (snapshot.data?['deck'] as deck_model.Deck?) ?? widget.deck;
          if (deck != null) {
            _updateOwnerStatus(deck);
          }
          print('Number of cards: ${cards.length}'); // Debug log

          if (cards.isEmpty) {
            return Center(child: Text('Không có card nào. Thêm mới nhé!'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(card.front ?? 'No front', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(card.back ?? 'No back'),
                        trailing: _isOwner
                            ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _editCard(card);
                            if (value == 'delete') _deleteCard(card);
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Sửa'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Xóa'),
                            ),
                          ],
                        )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: _previousPage,
                      disabledColor: Colors.grey,
                      color: Colors.blue,
                    ),
                    Text('Trang $_currentPage / ${response['last_page']}'),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: _nextPage,
                      disabledColor: Colors.grey,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isOwner
          ? FloatingActionButton(
        onPressed: () => _createCard(context),
        child: Icon(Icons.add),
      )
          : null,
    );
  }

  void _editCard(card_model.Card card) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chức năng sửa card đang phát triển')));
  }

  void _deleteCard(card_model.Card card) async {
    try {
      await widget.api.deleteCard(card.id);
      setState(() {
        _loadCards();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _createCard(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chức năng tạo card đang phát triển')));
  }
}