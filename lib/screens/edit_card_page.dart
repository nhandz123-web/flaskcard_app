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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cardUpdatedSuccessfully ?? 'Card updated successfully')),
        );
        return updatedCard;
      } catch (e) {
        print('Update card error: $e');
        String errorMessage = AppLocalizations.of(context)!.errorUpdatingCard(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editCard ?? 'Edit Card'),
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
                  final updatedCard = await _saveCard();
                  if (updatedCard != null && mounted) {
                    context.pop(updatedCard);
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