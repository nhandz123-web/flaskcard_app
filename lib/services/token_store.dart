import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore extends ChangeNotifier {
  final _s = const FlutterSecureStorage();
  static const _key = 'access_token';
  String? _token; // Cache trong RAM

  TokenStore() {
    _init(); // Gọi init() ngay khi khởi tạo
  }

  Future<void> _init() async {
    _token = await _s.read(key: _key);
    print('Token initialized: $_token'); // Debug log
    notifyListeners(); // Cập nhật khi token được tải
  }

  // Getter bất đồng bộ, ưu tiên dùng trong ApiService
  Future<String?> getToken() async {
    if (_token == null) {
      await _init(); // Tải lại nếu cache rỗng
    }
    return _token ?? await _s.read(key: _key);
  }

  // Getter đồng bộ cho redirect (nếu cần, nhưng không khuyến khích)
  String? get token => _token;

  Future<void> save(String token) async {
    _token = token;
    await _s.write(key: _key, value: token);
    print('Token saved: $token'); // Debug log
    notifyListeners(); // Cập nhật cho GoRouter
  }

  Future<void> clear() async {
    _token = null;
    await _s.delete(key: _key);
    print('Token cleared'); // Debug log
    notifyListeners();
  }
}