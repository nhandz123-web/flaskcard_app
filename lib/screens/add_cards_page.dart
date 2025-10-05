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

  Future<bool> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Bước 1: Tạo card trước
        final createData = {
          'front': _frontController.text,
          'back': _backController.text,
          'phonetic': _phoneticController.text.isNotEmpty ? _phoneticController.text : null,
          'example': _exampleController.text.isNotEmpty ? _exampleController.text : null,
          'image_url': null,
          'audio_url': null,
          'extra': _extra,
        };

        print('Creating card with data: $createData');
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

        // Bước 2: Upload image nếu có
        String? imageUrl;
        if (_selectedImage != null) {
          print('Uploading image for cardId: ${createdCard.id}');
          imageUrl = await widget.api.uploadCardImage(createdCard.id, _selectedImage!);
        }

        // Bước 3: Upload audio nếu có
        String? audioUrl;
        if (_selectedAudio != null) {
          print('Uploading audio for cardId: ${createdCard.id}');
          audioUrl = await widget.api.uploadCardAudio(createdCard.id, _selectedAudio!);
        }

        // Bước 4: Cập nhật card nếu có upload
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
          print('Updating card with data: $updateData');
          await widget.api.updateCard(widget.deckId, createdCard.id, updateData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cardCreatedSuccessfully ?? 'Card created successfully')),
        );
        return true;
      } catch (e) {
        print('Create card error: $e');
        String errorMessage = AppLocalizations.of(context)!.errorCreatingCard(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addCard ?? 'Add Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _frontController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.front ?? 'Front'),
                validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.requiredField ?? 'Required' : null,
              ),
              TextFormField(
                controller: _backController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.back ?? 'Back'),
                validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.requiredField ?? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneticController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.phonetic ?? 'Phonetic'),
              ),
              TextFormField(
                controller: _exampleController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.example ?? 'Example'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.imageUrl ?? 'Image'),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: _pickImage,
                    tooltip: AppLocalizations.of(context)!.uploadImage ?? 'Upload Image',
                  ),
                  if (_imageUrlController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _imageUrlController.clear();
                        });
                      },
                      tooltip: AppLocalizations.of(context)!.removeImage ?? 'Remove Image',
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _audioUrlController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.audioUrl ?? 'Audio'),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: _pickAudio,
                    tooltip: AppLocalizations.of(context)!.uploadAudio ?? 'Upload Audio',
                  ),
                  if (_audioUrlController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedAudio = null;
                          _audioUrlController.clear();
                        });
                      },
                      tooltip: AppLocalizations.of(context)!.removeAudio ?? 'Remove Audio',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final success = await _saveCard();
                  if (success && mounted) {
                    context.pop(true);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save ?? 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}