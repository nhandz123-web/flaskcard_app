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
  void initState() {
    super.initState();
    print('Khởi tạo CreateDeckPage');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createDeck() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.error}: ${AppLocalizations.of(context)!.deckNameRequired}',
          ),
        ),
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
      final userIdInt = int.tryParse(userId);
      if (userIdInt == null) {
        throw Exception('Invalid user ID format: $userId');
      }
      print('Creating deck with userId: $userIdInt, name: ${_nameController.text}, description: ${_descriptionController.text}');

      await widget.api.createDeck(
        userIdInt,
        _nameController.text,
        _descriptionController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckCreatedSuccess)),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      print('Error creating deck: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Xây dựng CreateDeckPage');
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final theme = Theme.of(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: Scaffold(
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                          Icons.create_new_folder_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!.createNewDeck,
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
                                  Text(
                                    AppLocalizations.of(context)!.deckName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: 'Nhập tên bộ thẻ...',
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
                                  const SizedBox(height: 20),
                                  Text(
                                    AppLocalizations.of(context)!.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      hintText: 'Nhập mô tả...',
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
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                                    maxLines: 4,
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
                                      onPressed: _createDeck,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(context)!.save,
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
          ),
        );
      },
    );
  }
}