import 'package:dio/dio.dart';
import 'token_store.dart';

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
}
