import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore with ChangeNotifier {
  String? _token;
  String? _userId;

  TokenStore() {
    _loadToken();
  }

  String? get token => _token;

  String? get userId => _userId;

  Future<String?> getToken() async => _token;

  Future<String?> getUserId() async => _userId;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('user_id');
    print('TokenStore loaded: token=$_token, userId=$_userId');
    notifyListeners();
  }

  Future<void> save(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_id', userId);
    _token = token;
    _userId = userId;
    print('TokenStore saved: token=$token, userId=$userId');
    notifyListeners();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    _token = null;
    _userId = null;
    print('TokenStore cleared');
    notifyListeners();
  }
}