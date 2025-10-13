import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flashcard_app/models/card.dart' as card_model;
import 'package:flashcard_app/models/deck.dart' as deck_model;
import 'package:flashcard_app/services/token_store.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flashcard_app/providers/deck_provider.dart';

class ApiService {
  final TokenStore _tokenStore;
  final Dio _dio;
  final DeckProvider deckProvider;
  WebSocketChannel? _webSocketChannel;
  Map<String, dynamic>? _cachedUserData;
  DateTime? _lastUserFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);
  List<deck_model.Deck>? _cachedDecks;
  String? _decksEtag;
  DateTime? _lastDecksFetch;

  ApiService(this._tokenStore, this.deckProvider)
      : _dio = Dio(BaseOptions(
    baseUrl: 'http://172.31.219.12:8080/api',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStore.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('Yêu cầu với token: $token');
          print('URL yêu cầu: ${options.uri}');
          print('Dữ liệu yêu cầu: ${options.data}');
        } else {
          print('Không có token cho yêu cầu');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('Trạng thái phản hồi: ${response.statusCode}');
        handler.next(response);
      },
      onError: (e, handler) async {
        print('Lỗi: ${e.message}, Phản hồi: ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          print('Lỗi 401, thử làm mới token');
          try {
            final newToken = await _refreshToken();
            await _tokenStore.save(newToken, await _tokenStore.getUserId() ?? '');
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            return handler.resolve(await _dio.fetch(e.requestOptions));
          } catch (refreshError) {
            print('Làm mới token thất bại: $refreshError');
            await _tokenStore.clear();
            handler.next(e);
          }
        } else if (e.response?.statusCode == 429) {
          print('Lỗi 429 - Quá nhiều yêu cầu, thử lại sau 2 giây...');
          await Future.delayed(Duration(seconds: 2));
          try {
            return handler.resolve(await _dio.fetch(e.requestOptions));
          } catch (retryError) {
            print('Thử lại thất bại: $retryError');
            handler.next(e);
          }
        } else {
          handler.next(e);
        }
      },
    ));

    _initCacheAndWebSocket();
  }

  Future<void> _initCacheAndWebSocket({String? search, int page = 1}) async {
    deckProvider.setLoading(true);
    _cachedDecks = await _loadDecksFromStorage();
    if (_cachedDecks != null) {
      print('Phát dữ liệu decks từ storage: ${_cachedDecks!.length} decks');
      deckProvider.setDecks(_cachedDecks!);
    }
    await refreshDecks(search: search, page: page);

    try {
      final token = await _tokenStore.getToken();
      _webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://172.31.219.12:6001/app/myappkey?protocol=7&client=js&version=7.0.3&flash=false'),
      );

      _webSocketChannel!.stream.listen(
            (data) {
          print('WebSocket nhận dữ liệu: $data');
          try {
            final message = jsonDecode(data);
            final event = message['event'];
            final eventData = message['data'];

            if (event == 'deck.updated') {
              final updatedDeck = deck_model.Deck.fromJson(eventData);
              deckProvider.updateDeck(updatedDeck);
              _updateCachedDecks(updatedDeck);
              _saveDecksToStorage(deckProvider.decks);
              print('WebSocket: Deck updated, phát: ${deckProvider.decks.length} decks');
            } else if (event == 'deck.deleted') {
              final deckId = eventData['id'];
              deckProvider.removeDeck(deckId);
              _removeCachedDeck(deckId);
              _saveDecksToStorage(deckProvider.decks);
              print('WebSocket: Deck deleted, phát: ${deckProvider.decks.length} decks');
            } else if (event == 'card.created') {
              final deckId = eventData['deck_id'];
              deckProvider.updateCardsCount(deckId, 1);
              _saveDecksToStorage(deckProvider.decks);
              print('WebSocket: Card created for deck ID $deckId');
            } else if (event == 'card.updated') {
              final deckId = eventData['deck_id'];
              print('WebSocket: Card updated for deck ID $deckId');
            } else if (event == 'card.deleted') {
              final deckId = eventData['deck_id'];
              deckProvider.updateCardsCount(deckId, -1);
              _saveDecksToStorage(deckProvider.decks);
              print('WebSocket: Card deleted for deck ID $deckId');
            }
          } catch (e) {
            print('Lỗi xử lý dữ liệu WebSocket: $e');
            deckProvider.setError('Lỗi xử lý WebSocket: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          deckProvider.setError('WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: () {
          print('WebSocket đóng');
          _reconnectWebSocket();
        },
      );
    } catch (e) {
      print('Lỗi khởi tạo WebSocket: $e');
      deckProvider.setError('Khởi tạo WebSocket thất bại: $e');
      _reconnectWebSocket();
    }
  }

  Future<void> _reconnectWebSocket() async {
    print('Thử kết nối lại WebSocket sau 5 giây...');
    await Future.delayed(Duration(seconds: 5));
    if (_webSocketChannel != null) {
      _webSocketChannel!.sink.close();
    }
    _initCacheAndWebSocket();
  }

  Future<void> _saveDecksToStorage(List<deck_model.Deck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_decks', jsonEncode(decks.map((d) => d.toJson()).toList()));
    print('Đã lưu ${decks.length} decks vào storage');
  }

  Future<List<deck_model.Deck>> _loadDecksFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cached_decks');
    if (data != null) {
      try {
        return (jsonDecode(data) as List).map((e) => deck_model.Deck.fromJson(e)).toList();
      } catch (e) {
        print('Lỗi giải mã decks từ storage: $e');
      }
    }
    return [];
  }

  void _updateCachedDecks(deck_model.Deck updatedDeck) {
    _cachedDecks ??= [];
    final index = _cachedDecks!.indexWhere((d) => d.id == updatedDeck.id);
    if (index >= 0) {
      _cachedDecks![index] = updatedDeck;
    } else {
      _cachedDecks!.add(updatedDeck);
    }
    print('Cập nhật cache decks: ${_cachedDecks!.length} decks');
  }

  void _removeCachedDeck(int deckId) {
    _cachedDecks?.removeWhere((d) => d.id == deckId);
    print('Xóa deck ID $deckId khỏi cache: ${_cachedDecks?.length ?? 0} decks còn lại');
  }

  Future<List<deck_model.Deck>> getDecks({String? search, int page = 1}) async {
    deckProvider.setLoading(true);
    try {
      final response = await _dio.get(
        '/decks',
        queryParameters: {'search': search, 'page': page},
        options: Options(
          headers: {
            if (_decksEtag != null) 'If-None-Match': _decksEtag,
            if (_lastDecksFetch != null) 'If-Modified-Since': _lastDecksFetch!.toUtc().toIso8601String(),
          },
        ),
      );
      if (response.statusCode == 304) {
        print('Dữ liệu decks không thay đổi, sử dụng cache');
        deckProvider.setDecks(_cachedDecks ?? await _loadDecksFromStorage());
        return _cachedDecks ?? await _loadDecksFromStorage();
      }
      final decks = (response.data['data'] as List).map((e) => deck_model.Deck.fromJson(e)).toList();
      _cachedDecks = decks;
      _decksEtag = response.headers.value('etag');
      _lastDecksFetch = DateTime.now();
      await _saveDecksToStorage(decks);
      deckProvider.setDecks(decks);
      print('Lấy decks thành công: ${decks.length} decks');
      return decks;
    } catch (e) {
      print('Lỗi lấy decks: $e');
      deckProvider.setError('Tải decks thất bại: $e');
      if (_cachedDecks != null) {
        print('Sử dụng cache decks do lỗi: ${_cachedDecks!.length} decks');
        deckProvider.setDecks(_cachedDecks!);
        return _cachedDecks!;
      }
      final storedDecks = await _loadDecksFromStorage();
      if (storedDecks.isNotEmpty) {
        print('Sử dụng decks từ storage do lỗi: ${storedDecks.length} decks');
        deckProvider.setDecks(storedDecks);
        return storedDecks;
      }
      throw Exception('Tải decks thất bại: $e');
    }
  }

  Future<void> refreshDecks({String? search, int page = 1}) async {
    try {
      await getDecks(search: search, page: page);
    } catch (e) {
      print('Lỗi refresh decks: $e');
    }
  }

  void dispose() {
    _webSocketChannel?.sink.close();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      String? userId;

      userId = data['user_id']?.toString() ?? data['id']?.toString();

      if (userId == null) {
        try {
          final jwtPayload = JwtDecoder.decode(token);
          userId = jwtPayload['sub']?.toString();
          print('Lấy userId từ JWT: $userId');
        } catch (jwtError) {
          print('Giải mã JWT thất bại: $jwtError');
          await _tokenStore.save(token, '');
          final userData = await me();
          userId = userData['id']?.toString();
          print('Lấy userId từ /me: $userId');
        }
      }

      if (userId == null) {
        throw Exception('Không tìm thấy user ID trong phản hồi đăng nhập hoặc /me');
      }

      await _tokenStore.save(token, userId);
      print('Đăng nhập thành công, token: $token, userId: $userId');
      _initCacheAndWebSocket();
      return {'token': token, 'user_id': userId};
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      if (e is DioException) {
        throw Exception('Lỗi server: ${e.response?.statusCode} - ${e.message}');
      }
      throw Exception('Lỗi bất ngờ: $e');
    }
  }

  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      String? userId = data['user_id']?.toString() ?? data['id']?.toString();

      if (userId == null) {
        try {
          final jwtPayload = JwtDecoder.decode(token);
          userId = jwtPayload['sub']?.toString();
          print('Lấy userId từ JWT: $userId');
        } catch (jwtError) {
          print('Giải mã JWT thất bại: $jwtError');
          await _tokenStore.save(token, '');
          final userData = await me();
          userId = userData['id']?.toString();
          print('Lấy userId từ /me: $userId');
        }
      }

      if (userId == null) {
        throw Exception('Không tìm thấy user ID trong phản hồi đăng ký hoặc /me');
      }

      await _tokenStore.save(token, userId);
      print('Đăng ký thành công, token: $token, userId: $userId');
      _initCacheAndWebSocket();
      return {'token': token, 'user_id': userId};
    } catch (e) {
      print('Lỗi đăng ký: $e');
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (e) {
      print('Lỗi đăng xuất: $e');
    } finally {
      await _tokenStore.clear();
      print('Token và userId đã được xóa');
      deckProvider.setDecks([]);
      _cachedDecks = null;
      _decksEtag = null;
      _lastDecksFetch = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_decks');
      _webSocketChannel?.sink.close();
    }
  }

  Future<String> _refreshToken() async {
    try {
      final response = await _dio.post('/refresh');
      return response.data['access_token'] as String;
    } catch (e) {
      print('Lỗi làm mới token: $e');
      throw Exception('Làm mới token thất bại: $e');
    }
  }

  Future<Map<String, dynamic>> me() async {
    if (_cachedUserData != null &&
        _lastUserFetch != null &&
        DateTime.now().difference(_lastUserFetch!).inMinutes < _cacheDuration.inMinutes) {
      print('Sử dụng dữ liệu người dùng từ cache: $_cachedUserData');
      return _cachedUserData!;
    }

    try {
      final response = await _dio.get('/me');
      final data = response.data as Map<String, dynamic>;
      final userId = data['id']?.toString();
      if (userId != null) {
        await _tokenStore.save(await _tokenStore.getToken() ?? '', userId);
      }
      _cachedUserData = data;
      _lastUserFetch = DateTime.now();
      print('Lấy dữ liệu người dùng thành công: $data');
      return data;
    } catch (e) {
      print('Lỗi lấy dữ liệu người dùng: $e');
      throw Exception('Lấy dữ liệu người dùng thất bại: $e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.put('/me', data: data);
      _cachedUserData = null;
    } catch (e) {
      print('Lỗi cập nhật hồ sơ: $e');
      throw Exception('Cập nhật hồ sơ thất bại: $e');
    }
  }

  Future<deck_model.Deck> getDeck(int deckId) async {
    try {
      final response = await _dio.get('/decks/$deckId');
      return deck_model.Deck.fromJson(response.data);
    } catch (e) {
      print('Lỗi lấy deck: $e');
      throw Exception('Tải deck thất bại: $e');
    }
  }

  Future<List<card_model.Card>> getCards(int deckId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/decks/$deckId/cards',
        queryParameters: {'page': page, '_t': DateTime.now().millisecondsSinceEpoch},
      );
      return (response.data['data'] as List).map((e) => card_model.Card.fromJson(e)).toList();
    } catch (e) {
      print('Lỗi lấy cards: $e');
      throw Exception('Tải cards thất bại: $e');
    }
  }

  Future<deck_model.Deck> createDeck(int userId, String name, String description) async {
    deckProvider.setLoading(true);
    try {
      final response = await _dio.post(
        '/decks',
        data: {'user_id': userId, 'name': name, 'description': description},
      );
      final newDeck = deck_model.Deck.fromJson(response.data['deck']);
      deckProvider.updateDeck(newDeck);
      await _saveDecksToStorage(deckProvider.decks);
      return newDeck;
    } catch (e) {
      print('Lỗi tạo deck: $e');
      deckProvider.setError('Tạo deck thất bại: $e');
      throw Exception('Tạo deck thất bại: $e');
    } finally {
      deckProvider.setLoading(false);
    }
  }

  Future<deck_model.Deck> updateDeck(int deckId, String name, String description) async {
    deckProvider.setLoading(true);
    try {
      final response = await _dio.put(
        '/decks/$deckId',
        data: {'name': name, 'description': description},
      );
      final updatedDeck = deck_model.Deck.fromJson(response.data['deck']);
      deckProvider.updateDeck(updatedDeck);
      await _saveDecksToStorage(deckProvider.decks);
      return updatedDeck;
    } catch (e) {
      print('Lỗi cập nhật deck: $e');
      deckProvider.setError('Cập nhật deck thất bại: $e');
      throw Exception('Cập nhật deck thất bại: $e');
    } finally {
      deckProvider.setLoading(false);
    }
  }

  Future<void> deleteDeck(int deckId) async {
    deckProvider.setLoading(true);
    try {
      await _dio.delete('/decks/$deckId');
    } on DioException catch (e) {
      // Nếu server báo 404 (deck không tồn tại) -> vẫn coi như đã xóa xong
      if (e.response?.statusCode == 404) {
        print('⚠️ Deck $deckId không tồn tại (coi như đã bị xóa).');
      } else if (e.response?.statusCode == 403) {
        deckProvider.setError('Bạn không có quyền xóa deck này.');
      } else {
        deckProvider.setError('Lỗi mạng hoặc server: ${e.message}');
      }
    } catch (e) {
      print('❌ Lỗi không xác định: $e');
      deckProvider.setError('Đã xảy ra lỗi khi xóa deck.');
    } finally {
      // Dù server trả gì đi nữa, vẫn cập nhật lại local
      deckProvider.removeDeck(deckId);
      await _saveDecksToStorage(deckProvider.decks);
      deckProvider.setLoading(false);
    }
  }




  Future<card_model.Card> createCard(
      int deckId, String front, String back, String? phonetic, String? example, String? imageUrl, String? audioUrl, Map<String, dynamic>? extra) async {
    deckProvider.setLoading(true);
    try {
      final response = await _dio.post(
        '/decks/$deckId/cards',
        data: {
          'front': front,
          'back': back,
          'phonetic': phonetic,
          'example': example,
          'image_url': imageUrl,
          'audio_url': audioUrl,
          'extra': extra,
        },
      );
      final newCard = card_model.Card.fromJson(response.data['card']);
      if (_webSocketChannel == null || _webSocketChannel!.closeCode != null) {
        await refreshDecks();
      } else {
        deckProvider.updateCardsCount(deckId, 1);
      }
      await _saveDecksToStorage(deckProvider.decks);
      print('Tạo card thành công, cập nhật cardsCount');
      return newCard;
    } catch (e) {
      print('Lỗi tạo card: $e');
      deckProvider.setError('Tạo card thất bại: $e');
      throw Exception('Tạo card thất bại: $e');
    } finally {
      deckProvider.setLoading(false);
    }
  }

  Future<card_model.Card> updateCard(int deckId, int cardId, Map<String, dynamic> data) async {
    deckProvider.setLoading(true);
    try {
      final response = await _dio.put('/decks/$deckId/cards/$cardId', data: data);
      final updatedCard = card_model.Card.fromJson(response.data['card']);
      print('Cập nhật card thành công');
      return updatedCard;
    } catch (e) {
      print('Lỗi cập nhật card: $e');
      deckProvider.setError('Cập nhật card thất bại: $e');
      throw Exception('Cập nhật card thất bại: $e');
    } finally {
      deckProvider.setLoading(false);
    }
  }

  Future<void> deleteCard(int deckId, int cardId) async {
    deckProvider.setLoading(true);
    try {
      await _dio.delete('/decks/$deckId/cards/$cardId');
      if (_webSocketChannel == null || _webSocketChannel!.closeCode != null) {
        await refreshDecks();
      } else {
        deckProvider.updateCardsCount(deckId, -1);
      }
      await _saveDecksToStorage(deckProvider.decks);
      print('Xóa card thành công, cập nhật cardsCount');
    } catch (e) {
      print('Lỗi xóa card: $e');
      deckProvider.setError('Xóa card thất bại: $e');
      throw Exception('Xóa card thất bại: $e');
    } finally {
      deckProvider.setLoading(false);
    }
  }

  Future<String> uploadCardImage(int cardId, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });
      final response = await _dio.post('/cards/$cardId/upload-image', data: formData);
      return response.data['image_url'] as String;
    } catch (e) {
      print('Lỗi tải lên hình ảnh: $e');
      throw Exception('Tải lên hình ảnh thất bại: $e');
    }
  }

  Future<String> uploadCardAudio(int cardId, File audioFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioFile.path),
      });
      final response = await _dio.post('/cards/$cardId/audio', data: formData);
      return response.data['audio_url'] as String;
    } catch (e) {
      print('Lỗi tải lên âm thanh: $e');
      throw Exception('Tải lên âm thanh thất bại: $e');
    }
  }

  Future<List<card_model.Card>> getCardsToReview(int deckId) async {
    try {
      final response = await _dio.get('/decks/$deckId/learn');
      return (response.data['cards'] as List).map((e) => card_model.Card.fromJson(e)).toList();
    } catch (e) {
      print('Lỗi lấy cards để ôn tập: $e');
      throw Exception('Tải cards để ôn tập thất bại: $e');
    }
  }

  Future<void> updateCardProgress(int deckId, int cardId, int quality) async {
    try {
      await _dio.post(
        '/decks/$deckId/cards/$cardId/progress',
        data: {'quality': quality},
      );
    } catch (e) {
      print('Lỗi cập nhật tiến độ card: $e');
      throw Exception('Cập nhật tiến độ card thất bại: $e');
    }
  }

  Future<void> markCardAsLearned(int cardId) async {
    try {
      await _dio.post('/cards/$cardId/learned');
    } catch (e) {
      print('Lỗi đánh dấu card đã học: $e');
      throw Exception('Đánh dấu card đã học thất bại: $e');
    }
  }

  Future<void> markCardReview(
      int cardId, int quality, double easiness, int repetition, int interval, DateTime nextReviewDate) async {
    try {
      await _dio.post(
        '/cards/$cardId/review',
        data: {
          'quality': quality,
          'easiness': easiness,
          'repetition': repetition,
          'interval': interval,
          'next_review_date': nextReviewDate.toIso8601String(),
        },
      );
    } catch (e) {
      print('Lỗi đánh dấu ôn tập card: $e');
      throw Exception('Đánh dấu ôn tập card thất bại: $e');
    }
  }
}