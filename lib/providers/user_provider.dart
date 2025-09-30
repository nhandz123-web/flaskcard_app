import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _api;
  int? _userId;

  UserProvider(this._api);

  int? get userId => _userId;

  Future<void> loadUser() async {
    try {
      final userData = await _api.me();
      _userId = userData['id'] as int?;
      print('User loaded with userId: $_userId'); // Debug log
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
      _userId = null; // Đặt null nếu lỗi để tránh crash
    }
    notifyListeners();
  }
}