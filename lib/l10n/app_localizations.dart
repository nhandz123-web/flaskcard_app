import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @lexiFlash.
  ///
  /// In en, this message translates to:
  /// **'⚡ LexiFlash'**
  String get lexiFlash;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @font_size.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get font_size;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @auto_play.
  ///
  /// In en, this message translates to:
  /// **'Auto-play audio in Study'**
  String get auto_play;

  /// No description provided for @daily_reminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get daily_reminder;

  /// No description provided for @pick_time.
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get pick_time;

  /// No description provided for @turn_off.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turn_off;

  /// No description provided for @study_play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get study_play;

  /// No description provided for @settings_hint.
  ///
  /// In en, this message translates to:
  /// **'These settings are saved on device (SharedPreferences). You can sync to server later.'**
  String get settings_hint;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @deck.
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get deck;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @createNewDeck.
  ///
  /// In en, this message translates to:
  /// **'Create New Deck'**
  String get createNewDeck;

  /// No description provided for @deckName.
  ///
  /// In en, this message translates to:
  /// **'Deck Name'**
  String get deckName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deckCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deck created successfully!'**
  String get deckCreatedSuccess;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @noDecks.
  ///
  /// In en, this message translates to:
  /// **'No decks available'**
  String get noDecks;

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created Date'**
  String get createdDate;

  /// No description provided for @deckNameRequired.
  ///
  /// In en, this message translates to:
  /// **'deckNameRequired'**
  String get deckNameRequired;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get settings;

  /// No description provided for @deckDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deck deleted successfully'**
  String get deckDeleted;

  /// No description provided for @deckUpdated.
  ///
  /// In en, this message translates to:
  /// **'Deck updated successfully'**
  String get deckUpdated;

  /// No description provided for @cardAdded.
  ///
  /// In en, this message translates to:
  /// **'Card added successfully'**
  String get cardAdded;

  /// No description provided for @editDeck.
  ///
  /// In en, this message translates to:
  /// **'Edit Deck'**
  String get editDeck;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get cards;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get addCard;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @front.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get front;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Flashcard'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupButton;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @englishWord.
  ///
  /// In en, this message translates to:
  /// **'English Word'**
  String get englishWord;

  /// No description provided for @meaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get meaning;

  /// No description provided for @phonetic.
  ///
  /// In en, this message translates to:
  /// **'Phonetic'**
  String get phonetic;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @uploadAudio.
  ///
  /// In en, this message translates to:
  /// **'Upload Audio'**
  String get uploadAudio;

  /// No description provided for @cardCreated.
  ///
  /// In en, this message translates to:
  /// **'Card created successfully'**
  String get cardCreated;

  /// No description provided for @englishWordRequired.
  ///
  /// In en, this message translates to:
  /// **'English word is required'**
  String get englishWordRequired;

  /// No description provided for @meaningRequired.
  ///
  /// In en, this message translates to:
  /// **'Meaning is required'**
  String get meaningRequired;

  /// No description provided for @noCards.
  ///
  /// In en, this message translates to:
  /// **'Nocards'**
  String get noCards;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete this card'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDeleteCard.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this card?'**
  String get confirmDeleteCard;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cardDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'The card has been deleted successfully'**
  String get cardDeletedSuccessfully;

  /// No description provided for @errorDeletingCard.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorDeletingCard(Object error);

  /// No description provided for @cardUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'The card has been updated successfully'**
  String get cardUpdatedSuccessfully;

  /// No description provided for @errorUpdatingCard.
  ///
  /// In en, this message translates to:
  /// **'Error updating card: {error}'**
  String errorUpdatingCard(Object error);

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit Card'**
  String get editCard;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @audioUrl.
  ///
  /// In en, this message translates to:
  /// **'Audio URL'**
  String get audioUrl;

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'example'**
  String get example;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'removeImage'**
  String get removeImage;

  /// No description provided for @removeAudio.
  ///
  /// In en, this message translates to:
  /// **'removeAudio'**
  String get removeAudio;

  /// No description provided for @noAudio.
  ///
  /// In en, this message translates to:
  /// **'No audio'**
  String get noAudio;

  /// No description provided for @errorPlayingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error playing audio'**
  String get errorPlayingAudio;

  /// No description provided for @errorLoadingDeck.
  ///
  /// In en, this message translates to:
  /// **'Error loading deck'**
  String get errorLoadingDeck;

  /// No description provided for @errorLoadingCards.
  ///
  /// In en, this message translates to:
  /// **'Error loading cards'**
  String get errorLoadingCards;

  /// No description provided for @noDeckData.
  ///
  /// In en, this message translates to:
  /// **'No deck data'**
  String get noDeckData;

  /// No description provided for @cardCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Card created successfully'**
  String get cardCreatedSuccessfully;

  /// No description provided for @errorCreatingCard.
  ///
  /// In en, this message translates to:
  /// **'Error creating card: {error}'**
  String errorCreatingCard(Object error);

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'debug'**
  String get debug;

  /// No description provided for @errorLoadingDecks.
  ///
  /// In en, this message translates to:
  /// **'Error loading Decks'**
  String get errorLoadingDecks;

  /// No description provided for @addCards.
  ///
  /// In en, this message translates to:
  /// **'addCards'**
  String get addCards;

  /// No description provided for @deckDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deck deleted successfully'**
  String get deckDeletedSuccessfully;

  /// No description provided for @errorDeletingDeck.
  ///
  /// In en, this message translates to:
  /// **'Error deleting deck'**
  String get errorDeletingDeck;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
