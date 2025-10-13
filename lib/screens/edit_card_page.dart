import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/card.dart' as card_model;
import '../l10n/app_localizations.dart';

class EditCardPage extends StatefulWidget {
  final ApiService api;
  final int deckId;
  final card_model.Card card;

  const EditCardPage({super.key, required this.api, required this.deckId, required this.card});

  @override
  State<EditCardPage> createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
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
    _frontController = TextEditingController(text: widget.card.front ?? '');
    _backController = TextEditingController(text: widget.card.back ?? '');
    _phoneticController = TextEditingController(text: widget.card.phonetic ?? '');
    _exampleController = TextEditingController(text: widget.card.example ?? '');
    _imageUrlController = TextEditingController(text: widget.card.imageUrl ?? '');
    _audioUrlController = TextEditingController(text: widget.card.audioUrl ?? '');
    _extra = widget.card.extra;
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImage = File(result.files.first.path!);
        _imageUrlController.text = result.files.first.name;
      });
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedAudio = File(result.files.first.path!);
        _audioUrlController.text = result.files.first.name;
      });
    }
  }

  Future<card_model.Card?> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String? imageUrl = _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null;
        String? audioUrl = _audioUrlController.text.isNotEmpty ? _audioUrlController.text : null;

        if (_selectedImage != null) {
          imageUrl = await widget.api.uploadCardImage(widget.card.id, _selectedImage!);
        } else if (_imageUrlController.text.isEmpty) {
          imageUrl = null;
        }

        if (_selectedAudio != null) {
          audioUrl = await widget.api.uploadCardAudio(widget.card.id, _selectedAudio!);
        } else if (_audioUrlController.text.isEmpty) {
          audioUrl = null;
        }

        final data = {
          'front': _frontController.text,
          'back': _backController.text,
          'phonetic': _phoneticController.text.isNotEmpty ? _phoneticController.text : null,
          'example': _exampleController.text.isNotEmpty ? _exampleController.text : null,
          'image_url': imageUrl,
          'audio_url': audioUrl,
          'extra': _extra,
        };

        print('Updating card with data: $data');
        final updatedCard = await widget.api.updateCard(widget.deckId, widget.card.id, data);
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cardUpdatedSuccessfully ?? 'Card updated successfully')),
        );
        return updatedCard;
      } catch (e) {
        print('Update card error: $e');
        if (!mounted) return null;
        String errorMessage = AppLocalizations.of(context)!.errorUpdatingCard(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return null;
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
    return null;
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
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.editCard ?? 'Chỉnh sửa thẻ',
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
                                  final updatedCard = await _saveCard();
                                  if (updatedCard != null && mounted) {
                                    context.pop(updatedCard);
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