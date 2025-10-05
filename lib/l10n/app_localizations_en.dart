// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get lexiFlash => '⚡ LexiFlash';

  @override
  String get settings_title => 'Settings';

  @override
  String get font_size => 'Font size';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get auto_play => 'Auto-play audio in Study';

  @override
  String get daily_reminder => 'Daily reminder';

  @override
  String get pick_time => 'Pick time';

  @override
  String get turn_off => 'Turn off';

  @override
  String get study_play => 'Play';

  @override
  String get settings_hint => 'These settings are saved on device (SharedPreferences). You can sync to server later.';

  @override
  String get home => 'Home';

  @override
  String get deck => 'Decks';

  @override
  String get learn => 'Learn';

  @override
  String get profile => 'Profile';

  @override
  String get createNewDeck => 'Create New Deck';

  @override
  String get deckName => 'Deck Name';

  @override
  String get description => 'Description';

  @override
  String get save => 'Save';

  @override
  String get deckCreatedSuccess => 'Deck created successfully!';

  @override
  String get error => 'Error';

  @override
  String get noDecks => 'No decks available';

  @override
  String get createdDate => 'Created Date';

  @override
  String get deckNameRequired => 'deckNameRequired';

  @override
  String get settings => 'settings';

  @override
  String get deckDeleted => 'Deck deleted successfully';

  @override
  String get deckUpdated => 'Deck updated successfully';

  @override
  String get cardAdded => 'Card added successfully';

  @override
  String get editDeck => 'Edit Deck';

  @override
  String get addCard => 'Add Card';

  @override
  String get name => 'Name';

  @override
  String get front => 'Front';

  @override
  String get back => 'Back';

  @override
  String get note => 'Note';

  @override
  String get appName => 'Flashcard';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get signupButton => 'Sign Up';

  @override
  String get logout => 'Logout';

  @override
  String get fontSize => 'Font Size';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get englishWord => 'English Word';

  @override
  String get meaning => 'Meaning';

  @override
  String get phonetic => 'Phonetic';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get uploadAudio => 'Upload Audio';

  @override
  String get cardCreated => 'Card created successfully';

  @override
  String get englishWordRequired => 'English word is required';

  @override
  String get meaningRequired => 'Meaning is required';

  @override
  String get noCards => 'Nocards';

  @override
  String get edit => 'Edit card';

  @override
  String get delete => 'Delete this card';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmDeleteCard => 'Are you sure you want to delete this card?';

  @override
  String get cancel => 'Cancel';

  @override
  String get cardDeletedSuccessfully => 'The card has been deleted successfully';

  @override
  String errorDeletingCard(Object error) {
    return 'Error: $error';
  }

  @override
  String get cardUpdatedSuccessfully => 'The card has been updated successfully';

  @override
  String errorUpdatingCard(Object error) {
    return 'Error updating card: $error';
  }

  @override
  String get editCard => 'Edit Card';

  @override
  String get requiredField => 'This field is required';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get audioUrl => 'Audio URL';

  @override
  String get example => 'example';

  @override
  String get removeImage => 'removeImage';

  @override
  String get removeAudio => 'removeAudio';
}
