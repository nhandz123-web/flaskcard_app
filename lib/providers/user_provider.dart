import 'package:flutter/foundation.dart';
import 'package:flashcard_app/services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _api;
  int? _userId;
  String? _name;

  UserProvider(this._api);

  int? get userId => _userId;
  String? get name => _name;

  Future<void> loadUser() async {
    try {
      final userData = await _api.me();
      _userId = userData['id'] as int?;
      _name = userData['name'] as String? ?? 'User'; // Mặc định là 'User' nếu name null
      print('User loaded with userId: $_userId, name: $_name');
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
      _userId = null;
      _name = null;
    }
    notifyListeners();
  }
}