import 'package:dio/dio.dart';
import 'token_store.dart';
import 'package:flashcard_app/models/deck.dart';
import 'package:flashcard_app/models/card.dart';
import 'dart:io';
import 'package:flashcard_app/models/card.dart' as card_model;

class ApiService {
  final TokenStore _tokenStore;
  final Dio _dio;

  ApiService(this._tokenStore)
      : _dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000')) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_tokenStore.token != null) {
          options.headers['Authorization'] = 'Bearer ${_tokenStore.token}';
        }
        options.headers['Accept'] = 'application/json';
        handler.next(options);
      },
      onError: (DioError e, handler) async {
        if (e.response?.statusCode == 401) {
          try {
            final newToken = await _refreshToken();
            await _tokenStore.save(newToken);
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final cloneReq = await _dio.fetch(e.requestOptions);
            return handler.resolve(cloneReq);
          } catch (_) {
            await _tokenStore.clear();
            return handler.next(e);
          }
        }
        handler.next(e);
      },
    ));

  }

  Future<String> login(String email, String password) async {
    final response = await _dio.post(
      '/api/login',
      data: {'email': email, 'password': password},
    );
    final token = response.data['access_token'] as String;
    await _tokenStore.save(token); // ✅ Lưu ngay
    return token;
  }

  Future<String> signup(String name, String email, String password) async {
    final response = await _dio.post(
      '/api/register', // ✅ Laravel hay dùng /register
      data: {'name': name, 'email': email, 'password': password},
    );
    final token = response.data['access_token'] as String;
    await _tokenStore.save(token);
    return token;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get('/api/me');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/logout');
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<String> _refreshToken() async {
    final response = await _dio.post('/api/refresh');
    return response.data['access_token'] as String;
  }

  // Deck APIs
  Future<List<Deck>> getDecks({String? search, int page = 1}) async {
    final response = await _dio.get('/api/decks', queryParameters: {'search': search, 'page': page});
    return (response.data['data'] as List).map((e) => Deck.fromJson(e)).toList();
  }

  Future<Deck> createDeck(String title, String desc, bool isPublic) async {
    final response = await _dio.post('/api/decks', data: {'title': title, 'description': desc, 'is_public': isPublic});
    return Deck.fromJson(response.data);
  }

// Tương tự cho edit/delete deck, getDeckDetail (trả về deck + list cards)

// Card APIs
  Future<Card> createCard(int deckId, String front, String back, String? note) async {
    final response = await _dio.post('/api/decks/$deckId/cards', data: {'front': front, 'back': back, 'note': note});
    return Card.fromJson(response.data);
  }

  Future<card_model.Card> updateCard(int cardId, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/cards/$cardId', data: data);
    return card_model.Card.fromJson(response.data); // Giả sử Card có fromJson
  }

// Tương tự cho edit/delete card

// Upload image (S2-05)
  Future<String> uploadCardImage(int cardId, File imageFile) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await _dio.post('/api/cards/$cardId/upload-image', data: formData);
    return response.data['image_url'] as String;
  }


}
