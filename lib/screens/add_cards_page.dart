import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/card.dart' as card_model;
import '../core/settings/settings_provider.dart';
import '../l10n/app_localizations.dart';

class AddCardsPage extends StatefulWidget {
  final ApiService api;
  final int deckId;

  const AddCardsPage({super.key, required this.api, required this.deckId});

  @override
  _AddCardsPageState createState() => _AddCardsPageState();
}

class _AddCardsPageState extends State<AddCardsPage> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _phoneticController = TextEditingController();
  final _exampleController = TextEditingController();
  File? _imageFile;
  File? _audioFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _createCard() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        print('Creating card with front: ${_frontController.text}, back: ${_backController.text}');
        final card = await widget.api.createCard(
          widget.deckId,
          _frontController.text,
          _backController.text,
          _phoneticController.text.isEmpty ? null : _phoneticController.text,
          _exampleController.text.isEmpty ? null : _exampleController.text,
        );
        print('Card created with ID: ${card.id}');
        if (_imageFile != null) {
          print('Uploading image: ${_imageFile!.path}');
          await widget.api.uploadCardImage(card.id, _imageFile!);
          print('Image upload completed');
        } else {
          print('No image file to upload');
        }
        if (_audioFile != null) {
          print('Uploading audio: ${_audioFile!.path}');
          await widget.api.uploadCardAudio(card.id, _audioFile!);
          print('Audio upload completed');
        } else {
          print('No audio file to upload');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cardCreated)),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        print('Error in createCard: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error + ': $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _phoneticController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final theme = Theme.of(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: Scaffold(
            backgroundColor: theme.colorScheme.background,
            appBar: AppBar(
              backgroundColor: Colors.red,
              title: Text(
                AppLocalizations.of(context)!.addCard,
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/app/deck/${widget.deckId}/cards'),
              ),
            ),
            body: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
                : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _frontController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.englishWord,
                          labelStyle: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6)),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        style: TextStyle(color: theme.colorScheme.onBackground),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.englishWordRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _backController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.meaning,
                          labelStyle: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6)),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        style: TextStyle(color: theme.colorScheme.onBackground),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.meaningRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneticController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.phonetic,
                          labelStyle: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6)),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        style: TextStyle(color: theme.colorScheme.onBackground),
                        validator: (value) => null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _exampleController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.example,
                          labelStyle: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6)),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        style: TextStyle(color: theme.colorScheme.onBackground),
                        validator: (value) => null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text(AppLocalizations.of(context)!.uploadImage),
                      ),
                      if (_imageFile != null) const SizedBox(height: 8),
                      if (_imageFile != null)
                        Text(
                          _imageFile!.path.split('/').last,
                          style: TextStyle(color: theme.colorScheme.onBackground),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _pickAudio,
                        child: Text(AppLocalizations.of(context)!.uploadAudio),
                      ),
                      if (_audioFile != null) const SizedBox(height: 8),
                      if (_audioFile != null)
                        Text(
                          _audioFile!.path.split('/').last,
                          style: TextStyle(color: theme.colorScheme.onBackground),
                        ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}) ?? theme.colorScheme.primary,
                          foregroundColor: theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _createCard,
                        child: Text(
                          AppLocalizations.of(context)!.save,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}