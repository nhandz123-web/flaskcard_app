import 'package:flutter/foundation.dart';
import 'package:flashcard_app/services/api_service.dart';
import 'dart:io';

class UserProvider with ChangeNotifier {
  final ApiService _api;
  String? _userId;
  String? _name;
  String? _email;
  String? _avatarUrl;

  UserProvider(this._api);

  String? get userId => _userId;
  String? get name => _name;
  String? get email => _email;
  String? get avatarUrl => _avatarUrl;

  Future<void> loadUser() async {
    try {
      final userData = await _api.me();
      _userId = userData['id']?.toString();
      _name = userData['name'];
      _email = userData['email'];
      _avatarUrl = userData['avatar'];
      print('User loaded: userId=$_userId, name=$_name, email=$_email, avatarUrl=$_avatarUrl');
      notifyListeners();
    } catch (e) {
      print('Error loading user: $e');
      _userId = null;
      _name = null;
      _email = null;
      _avatarUrl = null;
      notifyListeners();
      throw Exception('Failed to load user: $e');
    }
  }

  Future<void> updateProfile(String name, String email) async {
    try {
      await _api.updateProfile({'name': name, 'email': email});
      // Cập nhật cục bộ trước khi gọi API để giảm thời gian chờ
      _name = name;
      _email = email;
      notifyListeners();
      // Làm mới dữ liệu từ server để đảm bảo đồng bộ
      await loadUser();
    } catch (e) {
      print('Error updating profile: $e');
      // Khôi phục trạng thái cũ nếu cập nhật thất bại
      await loadUser();
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updateAvatar(File image) async {
    try {
      final avatarUrl = await _api.updateAvatar(image);
      // Cập nhật cục bộ trước để giao diện phản ánh ngay
      _avatarUrl = avatarUrl;
      notifyListeners();
      // Làm mới dữ liệu từ server để đảm bảo đồng bộ
      await loadUser();
    } catch (e) {
      print('Error updating avatar: $e');
      // Khôi phục trạng thái cũ nếu cập nhật thất bại
      await loadUser();
      throw Exception('Failed to update avatar: $e');
    }
  }

  // Thêm phương thức để cập nhật dữ liệu từ WebSocket
  void updateUserData({String? name, String? email, String? avatarUrl}) {
    _name = name ?? _name;
    _email = email ?? _email;
    _avatarUrl = avatarUrl ?? _avatarUrl;
    print('User updated via WebSocket: name=$_name, email=$_email, avatarUrl=$_avatarUrl');
    notifyListeners();
  }
}