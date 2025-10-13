import 'package:flutter/material.dart';
import 'package:flashcard_app/services/api_service.dart';

class AccountDetailsPage extends StatefulWidget {
  final ApiService api;

  const AccountDetailsPage({super.key, required this.api});

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await widget.api.me();
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _avatarUrl = userData['avatar'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông tin: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Giả định API /update-profile
        await widget.api.updateProfile({
          'name': _nameController.text,
          'email': _emailController.text,
          // 'avatar': _avatarUrl, // Xử lý upload ảnh riêng nếu cần
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật thông tin: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAvatar() async {
    // Placeholder cho upload ảnh (cần package như image_picker)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng upload ảnh chưa được triển khai')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin tài khoản'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      backgroundColor: Colors.black12,
                      child: _avatarUrl == null ? const Icon(Icons.person, size: 60) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: _updateAvatar,
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ tên',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Cập nhật'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}