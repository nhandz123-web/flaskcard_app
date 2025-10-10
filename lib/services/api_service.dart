import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flashcard_app/models/card.dart' as card_model;
import 'package:flashcard_app/models/deck.dart' as deck_model;
import 'dart:io';
import 'token_store.dart';

class ApiService {
  final TokenStore _tokenStore;
  final Dio _dio;

  ApiService(this._tokenStore)
      : _dio = Dio(BaseOptions(baseUrl: 'http://10.12.216.12:8080')) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
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

  Future<String?> _getToken() async => await _tokenStore.getToken();

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
    try {
      final response = await _dio.get('/api/decks/$deckId');
      if (response.statusCode == 200) {
        return deck_model.Deck.fromJson(response.data);
      } else {
        throw Exception('Failed to load deck: ${response.statusCode}');
      }
    } catch (e) {
      print('Get deck error: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getCardsResponse(int deckId, {int page = 1}) async {
    try {
      final response = await _dio.get('/api/decks/$deckId/cards', queryParameters: {'page': page});
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Failed to load cards: ${e.response?.statusCode} - ${e.message}');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<card_model.Card>> getCards(int deckId, {int page = 1}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final response = await _dio.get(
      '/api/decks/$deckId/cards',
      queryParameters: {'page': page, '_t': timestamp},
    );
    if (response.statusCode == 200) {
      return (response.data['data'] as List).map((e) => card_model.Card.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load cards: ${response.statusCode}');
    }
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

  Future<card_model.Card> createCard(
      int deckId,
      String front,
      String back,
      String? phonetic,
      String? example,
      String? imageUrl,
      String? audioUrl,
      Map<String, dynamic>? extra,
      ) async {
    try {
      final data = {
        'front': front,
        'back': back,
        'phonetic': phonetic,
        'example': example,
        'image_url': imageUrl,
        'audio_url': audioUrl,
        'extra': extra,
      };
      final response = await _dio.post(
        '/api/decks/$deckId/cards',
        data: data,
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to create card: ${response.statusCode}');
      }
      final cardData = response.data['card'] as Map<String, dynamic>;
      if (cardData == null) {
        throw Exception('No card data in response: ${response.data}');
      }
      return card_model.Card.fromJson(cardData);
    } catch (e) {
      print('Create card error: $e');
      throw e;
    }
  }

  Future<card_model.Card> updateCard(int deckId, int cardId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/decks/$deckId/cards/$cardId', data: data);
      if (response.statusCode == 200) {
        final cardData = response.data['card'] as Map<String, dynamic>;
        if (cardData == null) {
          throw Exception('No card data in response: ${response.data}');
        }
        return card_model.Card.fromJson(cardData);
      } else {
        throw Exception('Failed to update card: ${response.statusCode}');
      }
    } catch (e) {
      print('Update card error: $e');
      throw e;
    }
  }

  Future<void> deleteCard(int deckId, int cardId) async {
    try {
      final response = await _dio.delete(
        '/api/decks/$deckId/cards/$cardId',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete card: ${response.statusCode}');
      }
    } catch (e) {
      print('Delete card error: $e');
      throw Exception('Lỗi xóa card: $e');
    }
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
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });
      final response = await _dio.post('/api/cards/$cardId/upload-image', data: formData);
      if (response.statusCode == 200) {
        return response.data['image_url'] as String;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload image error: $e');
      throw e;
    }
  }

  Future<String> uploadCardAudio(int cardId, File audioFile) async {
    try {
      print('Sending audio upload request to: /api/cards/$cardId/audio');
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioFile.path),
      });
      final response = await _dio.post(
        '/api/cards/$cardId/audio',
        data: formData,
      );
      print('Audio upload response status: ${response.statusCode}');
      print('Audio upload response data: ${response.data}');
      if (response.statusCode != 200) {
        throw Exception('Failed to upload audio: ${response.statusCode}');
      }
      return response.data['audio_url'] as String;
    } catch (e) {
      print('Upload audio error: $e');
      throw e;
    }
  }

  Future<List<card_model.Card>> getCardsToReview(int deckId) async {
    try {
      final response = await _dio.get('/api/decks/$deckId/learn');
      if (response.statusCode == 200) {
        return (response.data['cards'] as List).map((e) => card_model.Card.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load cards to review: ${response.statusCode}');
      }
    } catch (e) {
      print('Get cards to review error: $e');
      throw e;
    }
  }

  Future<void> updateCardProgress(int deckId, int cardId, int quality) async {
    try {
      final response = await _dio.post(
        '/api/decks/$deckId/cards/$cardId/progress',
        data: {'quality': quality},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update card progress: ${response.statusCode}');
      }
    } catch (e) {
      print('Update card progress error: $e');
      throw e;
    }
  }

  Future<void> markCardAsLearned(int cardId) async {
    try {
      final response = await _dio.post(
        '/api/cards/$cardId/learned',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to mark card as learned: ${response.statusCode}');
      }
    } catch (e) {
      print('Mark card as learned error: $e');
      throw Exception('Failed to mark card as learned: $e');
    }
  }

  Future<void> markCardReview(int cardId, int quality, double easiness, int repetition, int interval, DateTime nextReviewDate) async {
    try {
      final response = await _dio.post(
        '/api/cards/$cardId/review',
        data: {
          'quality': quality,
          'easiness': easiness,
          'repetition': repetition,
          'interval': interval,
          'next_review_date': nextReviewDate.toIso8601String(),
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to mark card review: ${response.statusCode}');
      }
    } catch (e) {
      print('Mark card review error: $e');
      throw Exception('Failed to mark card review: $e');
    }
  }
}