import 'package:flutter/foundation.dart';
import 'package:flashcard_app/services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _api;
  String? _userId;
  String? _name;
  String? _email;

  UserProvider(this._api);

  String? get userId => _userId;
  String? get name => _name;
  String? get email => _email;

  Future<void> loadUser() async {
    try {
      final userData = await _api.me();
      _userId = userData['id']?.toString();
      _name = userData['name'];
      _email = userData['email'];
      print('User loaded: userId=$_userId, name=$_name, email=$_email');
      notifyListeners();
    } catch (e) {
      print('Error loading user: $e');
      _userId = null;
      _name = null;
      _email = null;
      notifyListeners();
      throw Exception('Failed to load user: $e');
    }
  }
}