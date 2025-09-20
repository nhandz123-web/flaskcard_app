import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore extends ChangeNotifier {
  final _s = const FlutterSecureStorage();
  static const _key = 'access_token';
  String? _token; // cache trong RAM

  Future<void> init() async {
    _token = await _s.read(key: _key);
  }

  String? get token => _token;           // getter ĐỒNG BỘ (dùng cho redirect)
  Future<String?> getAsync() async => _token ?? await _s.read(key: _key);
  Future<String?> get() => getAsync();   // alias để code cũ không lỗi

  Future<void> save(String token) async {
    _token = token;
    await _s.write(key: _key, value: token);
    notifyListeners(); // cho GoRouter refresh an toàn
  }

  Future<void> clear() async {
    _token = null;
    await _s.delete(key: _key);
    notifyListeners();
  }
}
