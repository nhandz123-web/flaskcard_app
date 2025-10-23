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
  String get settings_hint =>
      'These settings are saved on device (SharedPreferences). You can sync to server later.';

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
  String get cards => 'cards';

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
  String get cardDeletedSuccessfully =>
      'The card has been deleted successfully';

  @override
  String errorDeletingCard(Object error) {
    return 'Error: $error';
  }

  @override
  String get cardUpdatedSuccessfully =>
      'The card has been updated successfully';

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

  @override
  String get errorNavigating => 'errorNavigating';

  @override
  String get noAudio => 'No audio';

  @override
  String get errorPlayingAudio => 'Error playing audio';

  @override
  String get errorLoadingDeck => 'Error loading deck';

  @override
  String get errorLoadingCards => 'Error loading cards';

  @override
  String get noDeckData => 'No deck data';

  @override
  String get cardCreatedSuccessfully => 'Card created successfully';

  @override
  String errorCreatingCard(Object error) {
    return 'Error creating card: $error';
  }

  @override
  String get debug => 'debug';

  @override
  String get errorLoadingDecks => 'Error loading Decks';

  @override
  String get addCards => 'addCards';

  @override
  String get deckDeletedSuccessfully => 'Deck deleted successfully';

  @override
  String get errorDeletingDeck => 'Error deleting deck';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeBack => 'back';

  @override
  String get loading => 'Loading...';

  @override
  String get dueCards => 'Cards due today';

  @override
  String get goal => 'goal';

  @override
  String get cardsPerDay => 'cards/day';

  @override
  String get learnNow => 'Learn Now';

  @override
  String get streak => 'Streak';

  @override
  String get days => 'days';

  @override
  String get markLearned => 'Mark as Learned';

  @override
  String get nextCard => 'Next Card';

  @override
  String get card => 'Card';

  @override
  String get noMoreCards => 'No more cards';

  @override
  String get markCardAsLearned => 'Mark card as learned';

  @override
  String get errorMarkingCard => 'errorMarkingCard';

  @override
  String get notDeckOwner => 'notDeckOwner';

  @override
  String get retry => 'retry';

  @override
  String get ok => 'ok';

  @override
  String get cardLearnedSuccessfully => 'Card learned successfully';

  @override
  String get errorMarkingCardLearned => 'Error marking Card Learned';

  @override
  String get completedDeck => 'Completed deck';

  @override
  String get pauseAudio => 'Pause audio';

  @override
  String get playAudio => 'Play audio';

  @override
  String get learned => 'Learned';

  @override
  String get next => 'Next';

  @override
  String learnDeckTitle(Object deckId) {
    return 'Learn Deck #$deckId';
  }

  @override
  String get noCardsToReview => 'No cards to review today.';

  @override
  String get again => 'Again';

  @override
  String get hard => 'Hard';

  @override
  String get normal => 'Normal';

  @override
  String get easy => 'Easy';

  @override
  String get progress => 'Progress';

  @override
  String get reviewAgain => 'The card will be reviewed again after 1 minute.';

  @override
  String get reviewHard => 'The card will be reviewed again after 5 minutes.';

  @override
  String get reviewNormal =>
      'The card will be reviewed again after 10 minutes.';

  @override
  String get reviewEasy => 'The card will be reviewed again after 1 day.';

  @override
  String get accountDetails => 'Cccount details';

  @override
  String get statistics => 'Statistics';

  @override
  String get help => 'Help';

  @override
  String get reviewAgain10Minutes => 'Thẻ sẽ được ôn lại sau 10 phút.';

  @override
  String get reviewAgain4Hours => 'Thẻ sẽ được ôn lại sau 4 giờ.';

  @override
  String get reviewAgain12Hours => 'Thẻ sẽ được ôn lại sau 12 giờ.';

  @override
  String get reviewAgain2Days => 'Thẻ sẽ được ôn lại sau 2 ngày.';

  @override
  String get reviewAgain3Days => 'Thẻ sẽ được ôn lại sau 3 ngày.';

  @override
  String get reviewAgain5Days => 'Thẻ sẽ được ôn lại sau 5 ngày.';

  @override
  String get reviewAgainDays => 'Thẻ sẽ được ôn lại sau %d ngày.';

  @override
  String get tapToRevealFirst => 'Hãy lật thẻ để xem đáp án trước';

  @override
  String get completedToday => 'Bạn đã hoàn thành hết thẻ hôm nay';

  @override
  String get newCardsAvailable => 'New cards available';

  @override
  String get aiInsights => 'AI Insights';
}
