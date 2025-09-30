import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../core/settings/settings_provider.dart';
import '../l10n/app_localizations.dart';

class CreateDeckPage extends StatefulWidget {
  final ApiService api;

  const CreateDeckPage({super.key, required this.api});

  @override
  _CreateDeckPageState createState() => _CreateDeckPageState();
}

class _CreateDeckPageState extends State<CreateDeckPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createDeck() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error + ': ' + AppLocalizations.of(context)!.deckNameRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId == null) {
        throw Exception('User not logged in - userId is null');
      }
      print('Creating deck with userId: $userId, name: ${_nameController.text}, description: ${_descriptionController.text}');

      final newDeck = await widget.api.createDeck(
        userId,
        _nameController.text,
        _descriptionController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckCreatedSuccess)),
      );
      context.go('/app/decks');
    } catch (e) {
      if (!mounted) return;
      print('Error creating deck: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error + ': $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
                AppLocalizations.of(context)!.createNewDeck,
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/app/decks'),
              ),
            ),
            body: SafeArea(
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
                      onPressed: _createDeck,
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