import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/deck.dart' as deck_model;
import '../core/settings/settings_provider.dart';
import '../l10n/app_localizations.dart';

class EditDeckPage extends StatefulWidget {
  final ApiService api;
  final int deckId;

  const EditDeckPage({super.key, required this.api, required this.deckId});

  @override
  _EditDeckPageState createState() => _EditDeckPageState();
}

class _EditDeckPageState extends State<EditDeckPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = true;
  deck_model.Deck? _deck;

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  Future<void> _loadDeck() async {
    try {
      final deck = await widget.api.getDeck(widget.deckId);
      _nameController.text = deck.name;
      _descriptionController.text = deck.description;
      if (mounted) {
        setState(() {
          _deck = deck;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error + ': $e')),
        );
      }
    }
  }

  Future<void> _updateDeck() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error + ': ' + AppLocalizations.of(context)!.deckNameRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Updating deck: name=${_nameController.text}, description=${_descriptionController.text}'); // Debug
      await widget.api.updateDeck(widget.deckId, _nameController.text, _descriptionController.text);
      if (!mounted) return;
      // Tải lại deck để đồng bộ dữ liệu
      final updatedDeck = await widget.api.getDeck(widget.deckId);
      if (mounted) {
        setState(() {
          _deck = updatedDeck;
          _nameController.text = updatedDeck.name; // Đồng bộ lại controller
          _descriptionController.text = updatedDeck.description;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckUpdated)),
      );
      context.go('/app/decks');
    } catch (e) {
      if (!mounted) return;
      print('Error updating deck: $e'); // Debug lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error + ': $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
                AppLocalizations.of(context)!.editDeck,
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/app/decks'),
              ),
            ),
            body: _isLoading || _deck == null
                ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
                : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.deckName,
                        labelStyle: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6)),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onBackground),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        labelStyle: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6)),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onBackground),
                      maxLines: 3,
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
                      onPressed: _updateDeck,
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
        );
      },
    );
  }
}