import 'package:dio/dio.dart';
import 'token_store.dart';
import 'dart:io';
import 'package:flashcard_app/models/card.dart' as card_model;
import 'package:flashcard_app/models/deck.dart' as deck_model;

class ApiService {
  final TokenStore _tokenStore;
  final Dio _dio;

  ApiService(this._tokenStore)
      : _dio = Dio(BaseOptions(baseUrl: 'http://10.12.216.12:8080')) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStore.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('Request with token: $token');
          print('Request URL: ${options.uri}');
          print('Request data: ${options.data}');
        } else {
          print('No token available for request');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
        handler.next(response);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          print('401 error, attempting to refresh token');
          // Logic refresh token (nếu có)
        }
        print('Error: ${e.message}, Response: ${e.response?.data}');
        handler.next(e);
      },
    ));
  }

  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/login',
        data: {'email': email, 'password': password},
      );
      final token = response.data['access_token'] as String;
      await _tokenStore.save(token);
      print('Login successful, token saved: $token');
      return token;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      if (e is DioException) {
        throw Exception('Lỗi server: ${e.response?.statusCode} - ${e.message}');
      }
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<String> signup(String name, String email, String password) async {
    final response = await _dio.post(
      '/api/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    final token = response.data['access_token'] as String;
    await _tokenStore.save(token);
    return token;
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

  Future<List<deck_model.Deck>> getDecks({String? search, int page = 1}) async {
    try {
      final response = await _dio.get('/api/decks', queryParameters: {'search': search, 'page': page});
      return (response.data['data'] as List).map((e) => deck_model.Deck.fromJson(e)).toList();
    } catch (e) {
      print('Error in getDecks: $e');
      return <deck_model.Deck>[];
    }
  }

  Future<deck_model.Deck> getDeck(int deckId) async {
    final response = await _dio.get('/api/decks/$deckId');
    return deck_model.Deck.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getCardsResponse(int deckId, {int page = 1}) async {
    final response = await _dio.get('/api/decks/$deckId/cards', queryParameters: {'page': page});
    return response.data;
  }

  Future<List<card_model.Card>> getCards(int deckId, {int page = 1}) async {
    final response = await getCardsResponse(deckId, page: page);
    return (response['data'] as List).map((e) => card_model.Card.fromJson(e)).toList();
  }

  Future<deck_model.Deck> createDeck(int userId, String name, String description) async {
    try {
      print('Sending POST to create deck with userId: $userId, name: $name, description: $description');
      final response = await _dio.post(
        '/api/decks',
        data: {
          'user_id': userId,
          'name': name,
          'description': description,
        },
      );

      print('Raw response data: ${response.data}');
      if (response.statusCode == 201) {
        return deck_model.Deck.fromJson(response.data);
      } else {
        throw Exception('Failed to create deck: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in createDeck: $e');
      if (e is DioException) {
        throw Exception('API error: ${e.response?.statusCode} - ${e.response?.data}');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<card_model.Card> createCard(int deckId, String front, String back, String? note) async {
    final response = await _dio.post('/api/decks/$deckId/cards', data: {'front': front, 'back': back, 'note': note});
    return card_model.Card.fromJson(response.data);
  }

  Future<card_model.Card> updateCard(int cardId, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/cards/$cardId', data: data);
    return card_model.Card.fromJson(response.data);
  }

  Future<void> deleteCard(int cardId) async {
    await _dio.delete('/api/cards/$cardId');
  }

  Future<void> deleteDeck(int deckId) async {
    final response = await _dio.delete('/api/decks/$deckId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete deck: ${response.statusCode} - ${response.data}');
    }
  }

  Future<deck_model.Deck> updateDeck(int deckId, String name, String description) async {
    try {
      print('Sending PUT to update deck $deckId with name: $name, description: $description');
      final response = await _dio.put(
        '/api/decks/$deckId',
        data: {
          'name': name,
          'description': description,
        },
      );
      print('Update deck response: ${response.statusCode} - ${response.data}');
      if (response.statusCode == 200) {
        return deck_model.Deck.fromJson(response.data);
      } else {
        throw Exception('Failed to update deck: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in updateDeck: $e');
      if (e is DioException) {
        throw Exception('API error: ${e.response?.statusCode} - ${e.response?.data}');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get('/api/me');
    return Map<String, dynamic>.from(response.data);
  }

  Future<String> uploadCardImage(int cardId, File imageFile) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await _dio.post('/api/cards/$cardId/upload-image', data: formData);
    return response.data['image_url'] as String;
  }
}