import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class AddCardPage extends StatefulWidget {
  final ApiService api;
  final int deckId;

  const AddCardPage({super.key, required this.api, required this.deckId});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _frontController;
  late TextEditingController _backController;
  late TextEditingController _phoneticController;
  late TextEditingController _exampleController;
  late TextEditingController _imageUrlController;
  late TextEditingController _audioUrlController;
  File? _selectedImage;
  File? _selectedAudio;
  Map<String, dynamic>? _extra;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController();
    _backController = TextEditingController();
    _phoneticController = TextEditingController();
    _exampleController = TextEditingController();
    _imageUrlController = TextEditingController();
    _audioUrlController = TextEditingController();
    _extra = null;
    print('Khởi tạo AddCardPage với deckId: ${widget.deckId}');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _phoneticController.dispose();
    _exampleController.dispose();
    _imageUrlController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = File(result.files.first.path!);
          _imageUrlController.text = result.files.first.name;
          print('Đã chọn hình ảnh: ${result.files.first.name}');
        });
      }
    } catch (e) {
      print('Lỗi chọn hình ảnh: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn hình ảnh: $e')),
      );
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedAudio = File(result.files.first.path!);
          _audioUrlController.text = result.files.first.name;
          print('Đã chọn âm thanh: ${result.files.first.name}');
        });
      }
    } catch (e) {
      print('Lỗi chọn âm thanh: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn âm thanh: $e')),
      );
    }
  }

  Future<bool> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final createData = {
          'front': _frontController.text,
          'back': _backController.text,
          'phonetic': _phoneticController.text.isNotEmpty ? _phoneticController.text : null,
          'example': _exampleController.text.isNotEmpty ? _exampleController.text : null,
          'image_url': null,
          'audio_url': null,
          'extra': _extra,
        };

        print('Tạo card với dữ liệu: $createData');
        final createdCard = await widget.api.createCard(
          widget.deckId,
          createData['front'] as String,
          createData['back'] as String,
          createData['phonetic'] as String?,
          createData['example'] as String?,
          null,
          null,
          createData['extra'] as Map<String, dynamic>?,
        );

        String? imageUrl;
        if (_selectedImage != null) {
          print('Tải lên hình ảnh cho cardId: ${createdCard.id}');
          imageUrl = await widget.api.uploadCardImage(createdCard.id, _selectedImage!);
        }

        String? audioUrl;
        if (_selectedAudio != null) {
          print('Tải lên âm thanh cho cardId: ${createdCard.id}');
          audioUrl = await widget.api.uploadCardAudio(createdCard.id, _selectedAudio!);
        }

        if (imageUrl != null || audioUrl != null) {
          final updateData = {
            'front': createData['front'],
            'back': createData['back'],
            'phonetic': createData['phonetic'],
            'example': createData['example'],
            'image_url': imageUrl,
            'audio_url': audioUrl,
            'extra': createData['extra'],
          };
          print('Cập nhật card với dữ liệu: $updateData');
          await widget.api.updateCard(widget.deckId, createdCard.id, updateData);
        }

        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cardCreatedSuccessfully ?? 'Tạo card thành công')),
        );
        return true;
      } catch (e) {
        print('Lỗi tạo card: $e');
        if (!mounted) return false;
        String errorMessage = AppLocalizations.of(context)!.errorCreatingCard(e.toString()) ?? 'Lỗi: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return false;
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
    return false;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: 'Nhập $label...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  width: double.infinity,
                  color: Colors.red,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.lexiFlash ?? 'LexiFlash',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.red.shade400, Colors.red.shade600],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.add_card_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.addCard ?? 'Thêm thẻ mới',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _frontController,
                              label: AppLocalizations.of(context)!.front ?? 'Mặt trước',
                              validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.requiredField ?? 'Bắt buộc' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _backController,
                              label: AppLocalizations.of(context)!.back ?? 'Mặt sau',
                              validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.requiredField ?? 'Bắt buộc' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneticController,
                              label: AppLocalizations.of(context)!.phonetic ?? 'Phiên âm',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _exampleController,
                              label: AppLocalizations.of(context)!.example ?? 'Ví dụ',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.imageUrl ?? 'Hình ảnh',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _imageUrlController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'Chưa có hình ảnh',
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.upload_file, color: Colors.red),
                                  onPressed: _pickImage,
                                  tooltip: AppLocalizations.of(context)!.uploadImage ?? 'Tải lên',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                                if (_imageUrlController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _imageUrlController.clear();
                                        print('Đã xóa hình ảnh');
                                      });
                                    },
                                    tooltip: AppLocalizations.of(context)!.removeImage ?? 'Xóa',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.audioUrl ?? 'Âm thanh',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _audioUrlController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'Chưa có âm thanh',
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.upload_file, color: Colors.red),
                                  onPressed: _pickAudio,
                                  tooltip: AppLocalizations.of(context)!.uploadAudio ?? 'Tải lên',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                                if (_audioUrlController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _selectedAudio = null;
                                        _audioUrlController.clear();
                                        print('Đã xóa âm thanh');
                                      });
                                    },
                                    tooltip: AppLocalizations.of(context)!.removeAudio ?? 'Xóa',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.red,
                              ),
                            )
                                : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  final success = await _saveCard();
                                  if (success && mounted) {
                                    print('Tạo card thành công, quay lại CardsPage');
                                    context.pop(true);
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.save ?? 'Lưu',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}