import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @nSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song} other{{count} songs}}'**
  String nSongs(int count);

  /// No description provided for @nAlbums.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} album} other{{count} albums}}'**
  String nAlbums(int count);

  /// No description provided for @nPlaylists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} playlist} other{{count} playlists}}'**
  String nPlaylists(int count);

  /// No description provided for @nFolders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} folder} other{{count} folders}}'**
  String nFolders(int count);

  /// No description provided for @nDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String nDays(int count);

  /// No description provided for @nTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} time} other{{count} times}}'**
  String nTimes(int count);

  /// No description provided for @nPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} play} other{{count} plays}}'**
  String nPlays(int count);

  /// No description provided for @nDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} duplicate} other{{count} duplicates}}'**
  String nDuplicates(int count);

  /// No description provided for @nGroups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} group} other{{count} groups}}'**
  String nGroups(int count);

  /// No description provided for @nCopies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} copy} other{{count} copies}}'**
  String nCopies(int count);

  /// No description provided for @nNewArtists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} new artist} other{{count} new artists}}'**
  String nNewArtists(int count);

  /// No description provided for @nListening.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} listening}}'**
  String nListening(int count);

  /// No description provided for @undoFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Put {count} song back as it was} other{Put {count} songs back as they were}}'**
  String undoFound(int count);

  /// No description provided for @foundInfoFor.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Found info for {count} song} other{Found info for {count} songs}}'**
  String foundInfoFor(int count);

  /// No description provided for @skipDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Skip {count} duplicate} other{Skip {count} duplicates}}'**
  String skipDuplicates(int count);

  /// No description provided for @matchNSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Match {count} song} other{Match {count} songs}}'**
  String matchNSongs(int count);

  /// No description provided for @createPlaylistN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Create playlist ({count} song)} other{Create playlist ({count} songs)}}'**
  String createPlaylistN(int count);

  /// No description provided for @notMeasuredYet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song not measured yet} other{{count} songs not measured yet}}'**
  String notMeasuredYet(int count);

  /// No description provided for @songsNotInLibrary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song not in this library} other{{count} songs not in this library}}'**
  String songsNotInLibrary(int count);

  /// No description provided for @readingNAlbums.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Reading {count} album…} other{Reading {count} albums…}}'**
  String readingNAlbums(int count);

  /// No description provided for @readingNPlaylists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Reading {count} playlist…} other{Reading {count} playlists…}}'**
  String readingNPlaylists(int count);

  /// No description provided for @previewNPlaylists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Preview · {count} playlist} other{Preview · {count} playlists}}'**
  String previewNPlaylists(int count);

  /// No description provided for @songsFromOrigin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song from {origin}} other{{count} songs from {origin}}}'**
  String songsFromOrigin(int count, Object origin);

  /// No description provided for @musicFoldersIntro.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song. Prism reads mp3, flac, m4a, ogg and wav files in these folders.} other{{count} songs. Prism reads mp3, flac, m4a, ogg and wav files in these folders.}}'**
  String musicFoldersIntro(int count);

  /// No description provided for @versionAndSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Version {version} · {count} song in your library} other{Version {version} · {count} songs in your library}}'**
  String versionAndSongs(int count, Object version);

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String minutesValue(Object m);

  /// No description provided for @hoursMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String hoursMinutesValue(Object h, Object m);

  /// No description provided for @secondsValue.
  ///
  /// In en, this message translates to:
  /// **'{s} s'**
  String secondsValue(Object s);

  /// No description provided for @dbValue.
  ///
  /// In en, this message translates to:
  /// **'{sign}{value} dB'**
  String dbValue(Object sign, Object value);

  /// No description provided for @stValue.
  ///
  /// In en, this message translates to:
  /// **'{sign}{value} st'**
  String stValue(Object sign, Object value);

  /// No description provided for @notAValidJsonFile.
  ///
  /// In en, this message translates to:
  /// **'Not a valid JSON file'**
  String get notAValidJsonFile;

  /// No description provided for @themeFileMustContainAJson.
  ///
  /// In en, this message translates to:
  /// **'Theme file must contain a JSON object'**
  String get themeFileMustContainAJson;

  /// No description provided for @unknownFileFormat.
  ///
  /// In en, this message translates to:
  /// **'Unknown file format \"{format}\"'**
  String unknownFileFormat(Object format);

  /// No description provided for @themeWasMadeWithANewer.
  ///
  /// In en, this message translates to:
  /// **'Theme was made with a newer Prism (v{v})'**
  String themeWasMadeWithANewer(Object v);

  /// No description provided for @missingThemeObject.
  ///
  /// In en, this message translates to:
  /// **'Missing \"theme\" object'**
  String get missingThemeObject;

  /// No description provided for @invalidThemeValues.
  ///
  /// In en, this message translates to:
  /// **'Invalid theme values: {e}'**
  String invalidThemeValues(Object e);

  /// No description provided for @audioEffectsAreNotAvailableOn.
  ///
  /// In en, this message translates to:
  /// **'Audio effects are not available on this platform.'**
  String get audioEffectsAreNotAvailableOn;

  /// No description provided for @equalizer.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get equalizer;

  /// No description provided for @resetToFlat.
  ///
  /// In en, this message translates to:
  /// **'Reset to flat'**
  String get resetToFlat;

  /// No description provided for @saveAsPreset.
  ///
  /// In en, this message translates to:
  /// **'Save as preset'**
  String get saveAsPreset;

  /// No description provided for @saveEqPreset.
  ///
  /// In en, this message translates to:
  /// **'Save EQ preset'**
  String get saveEqPreset;

  /// No description provided for @myPreset.
  ///
  /// In en, this message translates to:
  /// **'My preset'**
  String get myPreset;

  /// No description provided for @boostOfDbMayClipLower.
  ///
  /// In en, this message translates to:
  /// **'Boost of {db} dB may clip – lower the preamp. '**
  String boostOfDbMayClipLower(Object db);

  /// No description provided for @aLimiterCatchesPeaksOnWindows.
  ///
  /// In en, this message translates to:
  /// **'(A limiter catches peaks on Windows.)'**
  String get aLimiterCatchesPeaksOnWindows;

  /// No description provided for @preset.
  ///
  /// In en, this message translates to:
  /// **'preset \"{name}\"'**
  String preset(Object name);

  /// No description provided for @preamp.
  ///
  /// In en, this message translates to:
  /// **'Preamp'**
  String get preamp;

  /// No description provided for @bassBoost.
  ///
  /// In en, this message translates to:
  /// **'Bass boost'**
  String get bassBoost;

  /// No description provided for @xOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get xOff;

  /// No description provided for @xOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get xOn;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @theCurrentCoverBlurredAndGrey.
  ///
  /// In en, this message translates to:
  /// **'The current cover, blurred and grey. Uses no power at all.'**
  String get theCurrentCoverBlurredAndGrey;

  /// No description provided for @matrix.
  ///
  /// In en, this message translates to:
  /// **'Matrix'**
  String get matrix;

  /// No description provided for @fallingSymbolsTheyLightUpAnd.
  ///
  /// In en, this message translates to:
  /// **'Falling symbols. They light up and bend around the mouse, a click sends a shockwave.'**
  String get fallingSymbolsTheyLightUpAnd;

  /// No description provided for @constellation.
  ///
  /// In en, this message translates to:
  /// **'Constellation'**
  String get constellation;

  /// No description provided for @driftingStarsJoinedByLinesThe.
  ///
  /// In en, this message translates to:
  /// **'Drifting stars joined by lines. The mouse pulls them in, a click scatters them.'**
  String get driftingStarsJoinedByLinesThe;

  /// No description provided for @ripple.
  ///
  /// In en, this message translates to:
  /// **'Ripple'**
  String get ripple;

  /// No description provided for @aGridOfDotsLikeA.
  ///
  /// In en, this message translates to:
  /// **'A grid of dots like a water surface. The mouse leaves waves, the bass makes drops.'**
  String get aGridOfDotsLikeA;

  /// No description provided for @katakana.
  ///
  /// In en, this message translates to:
  /// **'Katakana'**
  String get katakana;

  /// No description provided for @x0And1.
  ///
  /// In en, this message translates to:
  /// **'0 and 1'**
  String get x0And1;

  /// No description provided for @hex.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get hex;

  /// No description provided for @letters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get letters;

  /// No description provided for @musicNotes.
  ///
  /// In en, this message translates to:
  /// **'Music notes'**
  String get musicNotes;

  /// No description provided for @myOwnText.
  ///
  /// In en, this message translates to:
  /// **'My own text'**
  String get myOwnText;

  /// No description provided for @dots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get dots;

  /// No description provided for @dashes.
  ///
  /// In en, this message translates to:
  /// **'Dashes'**
  String get dashes;

  /// No description provided for @plusSigns.
  ///
  /// In en, this message translates to:
  /// **'Plus signs'**
  String get plusSigns;

  /// No description provided for @trailLength.
  ///
  /// In en, this message translates to:
  /// **'Trail length'**
  String get trailLength;

  /// No description provided for @lineLength.
  ///
  /// In en, this message translates to:
  /// **'Line length'**
  String get lineLength;

  /// No description provided for @waveWidth.
  ///
  /// In en, this message translates to:
  /// **'Wave width'**
  String get waveWidth;

  /// No description provided for @amountOfRain.
  ///
  /// In en, this message translates to:
  /// **'Amount of rain'**
  String get amountOfRain;

  /// No description provided for @numberOfStars.
  ///
  /// In en, this message translates to:
  /// **'Number of stars'**
  String get numberOfStars;

  /// No description provided for @dotsPerArea.
  ///
  /// In en, this message translates to:
  /// **'Dots per area'**
  String get dotsPerArea;

  /// No description provided for @symbolSize.
  ///
  /// In en, this message translates to:
  /// **'Symbol size'**
  String get symbolSize;

  /// No description provided for @starSize.
  ///
  /// In en, this message translates to:
  /// **'Star size'**
  String get starSize;

  /// No description provided for @dotSize.
  ///
  /// In en, this message translates to:
  /// **'Dot size'**
  String get dotSize;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @tryIt.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get tryIt;

  /// No description provided for @symbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get symbols;

  /// No description provided for @yourSymbols.
  ///
  /// In en, this message translates to:
  /// **'Your symbols'**
  String get yourSymbols;

  /// No description provided for @anyLettersOrSymbolsEG.
  ///
  /// In en, this message translates to:
  /// **'Any letters or symbols, e.g. your name'**
  String get anyLettersOrSymbolsEG;

  /// No description provided for @shape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get shape;

  /// No description provided for @colors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colors;

  /// No description provided for @useTheThemeColors.
  ///
  /// In en, this message translates to:
  /// **'Use the theme colors'**
  String get useTheThemeColors;

  /// No description provided for @mainColor.
  ///
  /// In en, this message translates to:
  /// **'Main color'**
  String get mainColor;

  /// No description provided for @highlightColor.
  ///
  /// In en, this message translates to:
  /// **'Highlight color'**
  String get highlightColor;

  /// No description provided for @look.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get look;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @reactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactions;

  /// No description provided for @clicksAlsoSendAWaveMusic.
  ///
  /// In en, this message translates to:
  /// **'Clicks also send a wave. Music reaction analyses each song once, the first time it plays.'**
  String get clicksAlsoSendAWaveMusic;

  /// No description provided for @mouse.
  ///
  /// In en, this message translates to:
  /// **'Mouse'**
  String get mouse;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @forEveryAnimatedBackground.
  ///
  /// In en, this message translates to:
  /// **'For every animated background'**
  String get forEveryAnimatedBackground;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// No description provided for @outOfFocus.
  ///
  /// In en, this message translates to:
  /// **'Out of focus'**
  String get outOfFocus;

  /// No description provided for @frostedPanels.
  ///
  /// In en, this message translates to:
  /// **'Frosted panels'**
  String get frostedPanels;

  /// No description provided for @panelsBlurWhatIsBehindThem.
  ///
  /// In en, this message translates to:
  /// **'Panels blur what is behind them'**
  String get panelsBlurWhatIsBehindThem;

  /// No description provided for @solidPanels.
  ///
  /// In en, this message translates to:
  /// **'Solid panels'**
  String get solidPanels;

  /// No description provided for @keepTheCoverUnderneath.
  ///
  /// In en, this message translates to:
  /// **'Keep the cover underneath'**
  String get keepTheCoverUnderneath;

  /// No description provided for @stopWhileTheMusicIsPaused.
  ///
  /// In en, this message translates to:
  /// **'Stop while the music is paused'**
  String get stopWhileTheMusicIsPaused;

  /// No description provided for @savesPower.
  ///
  /// In en, this message translates to:
  /// **'Saves power'**
  String get savesPower;

  /// No description provided for @framesPerSecond.
  ///
  /// In en, this message translates to:
  /// **'Frames per second'**
  String get framesPerSecond;

  /// No description provided for @lowerSavesPower.
  ///
  /// In en, this message translates to:
  /// **'Lower saves power'**
  String get lowerSavesPower;

  /// No description provided for @screen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get screen;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset {style}'**
  String reset(Object style);

  /// No description provided for @closeEsc.
  ///
  /// In en, this message translates to:
  /// **'Close (Esc)'**
  String get closeEsc;

  /// No description provided for @moveTheMouseAndClick.
  ///
  /// In en, this message translates to:
  /// **'Move the mouse and click'**
  String get moveTheMouseAndClick;

  /// No description provided for @watchOnYoutube.
  ///
  /// In en, this message translates to:
  /// **'Watch on YouTube'**
  String get watchOnYoutube;

  /// No description provided for @openOnSoundcloud.
  ///
  /// In en, this message translates to:
  /// **'Open on SoundCloud'**
  String get openOnSoundcloud;

  /// No description provided for @findOnYoutube.
  ///
  /// In en, this message translates to:
  /// **'Find on YouTube'**
  String get findOnYoutube;

  /// No description provided for @connectedToDiscord.
  ///
  /// In en, this message translates to:
  /// **'Connected to Discord'**
  String get connectedToDiscord;

  /// No description provided for @connectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {user}'**
  String connectedAs(Object user);

  /// No description provided for @discordIsnTRunningItConnects.
  ///
  /// In en, this message translates to:
  /// **'Discord isn\'t running. It connects by itself when you open it.'**
  String get discordIsnTRunningItConnects;

  /// No description provided for @discordDidnTAcceptThisApplication.
  ///
  /// In en, this message translates to:
  /// **'Discord didn\'t accept this application ID.'**
  String get discordDidnTAcceptThisApplication;

  /// No description provided for @oneSetupStepLeft.
  ///
  /// In en, this message translates to:
  /// **'One setup step left'**
  String get oneSetupStepLeft;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @discordStatus.
  ///
  /// In en, this message translates to:
  /// **'Discord status'**
  String get discordStatus;

  /// No description provided for @songAlbumArtProgressLinksAnd.
  ///
  /// In en, this message translates to:
  /// **'Song, album art, progress, links and who you listen with'**
  String get songAlbumArtProgressLinksAnd;

  /// No description provided for @findAlbumArt.
  ///
  /// In en, this message translates to:
  /// **'Find album art'**
  String get findAlbumArt;

  /// No description provided for @sendsTitleAndArtistToApple.
  ///
  /// In en, this message translates to:
  /// **'Sends title and artist to Apple\'s and Deezer\'s public search. Discord can\'t show covers from your PC.'**
  String get sendsTitleAndArtistToApple;

  /// No description provided for @discordNeedsAnApplicationToShow.
  ///
  /// In en, this message translates to:
  /// **'Discord needs an application to show a status, and only a logged-in person can create one. Once, 30 seconds: New Application → name it Prism → Create → copy Application ID. Prism picks it up from the clipboard by itself.'**
  String get discordNeedsAnApplicationToShow;

  /// No description provided for @openTheDiscordPage.
  ///
  /// In en, this message translates to:
  /// **'Open the Discord page'**
  String get openTheDiscordPage;

  /// No description provided for @applicationId.
  ///
  /// In en, this message translates to:
  /// **'Application ID'**
  String get applicationId;

  /// No description provided for @useMyOwnApplication.
  ///
  /// In en, this message translates to:
  /// **'Use my own application'**
  String get useMyOwnApplication;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get nothingPlaying;

  /// No description provided for @backToFullWindow.
  ///
  /// In en, this message translates to:
  /// **'Back to full window'**
  String get backToFullWindow;

  /// No description provided for @miniPlayerAlwaysOnTop.
  ///
  /// In en, this message translates to:
  /// **'Mini player (always on top)'**
  String get miniPlayerAlwaysOnTop;

  /// No description provided for @trackNotFound.
  ///
  /// In en, this message translates to:
  /// **'Track not found'**
  String get trackNotFound;

  /// No description provided for @ffmpegIsNotAvailableWaveformAnd.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg is not available – waveform and export are disabled.'**
  String get ffmpegIsNotAvailableWaveformAnd;

  /// No description provided for @savingNewTrack.
  ///
  /// In en, this message translates to:
  /// **'Saving new track…'**
  String get savingNewTrack;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// No description provided for @ffmpegIsNotAvailableOnThis.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg is not available on this device'**
  String get ffmpegIsNotAvailableOnThis;

  /// No description provided for @ffmpegFailed.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg failed ({code}):\n{tail}'**
  String ffmpegFailed(Object code, Object tail);

  /// No description provided for @xEdit.
  ///
  /// In en, this message translates to:
  /// **'{title} (edit)'**
  String xEdit(Object title);

  /// No description provided for @couldNotDecodeAudio.
  ///
  /// In en, this message translates to:
  /// **'Could not decode audio:\n{tail}'**
  String couldNotDecodeAudio(Object tail);

  /// No description provided for @pausedTheSearchServicesAreNot.
  ///
  /// In en, this message translates to:
  /// **'Paused: the search services are not answering'**
  String get pausedTheSearchServicesAreNot;

  /// No description provided for @prismNeedsPermissionToReadYour.
  ///
  /// In en, this message translates to:
  /// **'Prism needs permission to read your music'**
  String get prismNeedsPermissionToReadYour;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @chooseAMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a music folder'**
  String get chooseAMusicFolder;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown album'**
  String get unknownAlbum;

  /// No description provided for @xLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get xLibrary;

  /// No description provided for @sortSongs.
  ///
  /// In en, this message translates to:
  /// **'Sort songs'**
  String get sortSongs;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get recentlyAdded;

  /// No description provided for @longestFirst.
  ///
  /// In en, this message translates to:
  /// **'Longest first'**
  String get longestFirst;

  /// No description provided for @songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @songsArtistsAlbums.
  ///
  /// In en, this message translates to:
  /// **'Songs, artists, albums'**
  String get songsArtistsAlbums;

  /// No description provided for @songsArtistsAlbumsHereAndOnline.
  ///
  /// In en, this message translates to:
  /// **'Songs, artists, albums – here and online'**
  String get songsArtistsAlbumsHereAndOnline;

  /// No description provided for @typeToSearchYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Type to search your library'**
  String get typeToSearchYourLibrary;

  /// No description provided for @typeToSearchYourLibraryAnd.
  ///
  /// In en, this message translates to:
  /// **'Type to search your library and online'**
  String get typeToSearchYourLibraryAnd;

  /// No description provided for @yourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get yourLibrary;

  /// No description provided for @nothingFoundInYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Nothing found in your library'**
  String get nothingFoundInYourLibrary;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @yourLibraryIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get yourLibraryIsEmpty;

  /// No description provided for @addAFolderWithMusicMp3.
  ///
  /// In en, this message translates to:
  /// **'Add a folder with music (mp3, flac, m4a, ogg, wav).'**
  String get addAFolderWithMusicMp3;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String add(Object name);

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder…'**
  String get chooseFolder;

  /// No description provided for @lookingForMusicFiles.
  ///
  /// In en, this message translates to:
  /// **'Looking for music… {found} files'**
  String lookingForMusicFiles(Object found);

  /// No description provided for @readingTags.
  ///
  /// In en, this message translates to:
  /// **'Reading tags {done} / {total}'**
  String readingTags(Object done, Object total);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {e}'**
  String error(Object e);

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @playingNext.
  ///
  /// In en, this message translates to:
  /// **'Playing next'**
  String get playingNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get addedToQueue;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist…'**
  String get addToPlaylist;

  /// No description provided for @removeOfflineCopy.
  ///
  /// In en, this message translates to:
  /// **'Remove offline copy'**
  String get removeOfflineCopy;

  /// No description provided for @saveForOffline.
  ///
  /// In en, this message translates to:
  /// **'Save for offline'**
  String get saveForOffline;

  /// No description provided for @personalUseOnlySeeSettingsOnline.
  ///
  /// In en, this message translates to:
  /// **'Personal use only – see Settings → Online services'**
  String get personalUseOnlySeeSettingsOnline;

  /// No description provided for @offlineCopyRemoved.
  ///
  /// In en, this message translates to:
  /// **'Offline copy removed'**
  String get offlineCopyRemoved;

  /// No description provided for @savingForOffline.
  ///
  /// In en, this message translates to:
  /// **'Saving for offline…'**
  String get savingForOffline;

  /// No description provided for @openOn.
  ///
  /// In en, this message translates to:
  /// **'Open on {service}'**
  String openOn(Object service);

  /// No description provided for @theWeb.
  ///
  /// In en, this message translates to:
  /// **'the web'**
  String get theWeb;

  /// No description provided for @xEdit2.
  ///
  /// In en, this message translates to:
  /// **'Edit…'**
  String get xEdit2;

  /// No description provided for @trimCutSpeedPitchFadesOriginal.
  ///
  /// In en, this message translates to:
  /// **'Trim, cut, speed, pitch, fades – original stays untouched'**
  String get trimCutSpeedPitchFadesOriginal;

  /// No description provided for @editTags.
  ///
  /// In en, this message translates to:
  /// **'Edit tags…'**
  String get editTags;

  /// No description provided for @removeFromThisPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from this playlist'**
  String get removeFromThisPlaylist;

  /// No description provided for @goToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Go to album'**
  String get goToAlbum;

  /// No description provided for @goToArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get goToArtist;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @notSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced · {source}'**
  String notSynced(Object source);

  /// No description provided for @sameFile.
  ///
  /// In en, this message translates to:
  /// **'same file'**
  String get sameFile;

  /// No description provided for @linkedVideo.
  ///
  /// In en, this message translates to:
  /// **'linked video'**
  String get linkedVideo;

  /// No description provided for @notInYourLibraryTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Not in your library. Turn on YouTube playback or SoundCloud to look online.'**
  String get notInYourLibraryTurnOn;

  /// No description provided for @isMissingIn.
  ///
  /// In en, this message translates to:
  /// **'{what} is missing in {path}.{error}'**
  String isMissingIn(Object what, Object path, Object error);

  /// No description provided for @youtubeApikeyOrTurnOnThe.
  ///
  /// In en, this message translates to:
  /// **'youtube.apiKey (or turn on the YouTube extractor)'**
  String get youtubeApikeyOrTurnOnThe;

  /// No description provided for @pausedSongsLeft.
  ///
  /// In en, this message translates to:
  /// **'Paused – {left} songs left.'**
  String pausedSongsLeft(Object left);

  /// No description provided for @importedPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Imported playlist'**
  String get importedPlaylist;

  /// No description provided for @portIsBusyCloseTheOther.
  ///
  /// In en, this message translates to:
  /// **'Port {port} is busy. Close the other app using it or change redirectPort in the config file.'**
  String portIsBusyCloseTheOther(Object port);

  /// No description provided for @couldNotOpenTheBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open the browser.'**
  String get couldNotOpenTheBrowser;

  /// No description provided for @loginTimedOut.
  ///
  /// In en, this message translates to:
  /// **'{service} login timed out.'**
  String loginTimedOut(Object service);

  /// No description provided for @loginWasCancelled.
  ///
  /// In en, this message translates to:
  /// **'Login was cancelled.'**
  String get loginWasCancelled;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'{service} login failed: {error}'**
  String loginFailed(Object service, Object error);

  /// No description provided for @connectFirstSettingsOnlineServices.
  ///
  /// In en, this message translates to:
  /// **'Connect {service} first (Settings → Online services).'**
  String connectFirstSettingsOnlineServices(Object service);

  /// No description provided for @didNotAnswerInTimeCheck.
  ///
  /// In en, this message translates to:
  /// **'{service} did not answer in time. Check your connection.'**
  String didNotAnswerInTimeCheck(Object service);

  /// No description provided for @secureConnectionToFailedCheckThe.
  ///
  /// In en, this message translates to:
  /// **'Secure connection to {service} failed (check the PC clock or a proxy).'**
  String secureConnectionToFailedCheckThe(Object service);

  /// No description provided for @xFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get xFile;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @lowCheckIt.
  ///
  /// In en, this message translates to:
  /// **'Low – check it'**
  String get lowCheckIt;

  /// No description provided for @noMatch.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get noMatch;

  /// No description provided for @notThe.
  ///
  /// In en, this message translates to:
  /// **'not the {v}'**
  String notThe(Object v);

  /// No description provided for @theService.
  ///
  /// In en, this message translates to:
  /// **'The service'**
  String get theService;

  /// No description provided for @youSeemToBeOfflineLocal.
  ///
  /// In en, this message translates to:
  /// **'You seem to be offline. Local songs still play; online parts resume when you are back.'**
  String get youSeemToBeOfflineLocal;

  /// No description provided for @isLimitingRequestsRightNowTry.
  ///
  /// In en, this message translates to:
  /// **'{name} is limiting requests right now. Try again in a few minutes.'**
  String isLimitingRequestsRightNowTry(Object name);

  /// No description provided for @yourLoginExpiredConnectTheAccount.
  ///
  /// In en, this message translates to:
  /// **'Your {name} login expired. Connect the account again in Settings → Online services.'**
  String yourLoginExpiredConnectTheAccount(Object name);

  /// No description provided for @refusedTheRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} refused the request.'**
  String refusedTheRequest(Object name);

  /// No description provided for @notFoundOnDeletedPrivateOr.
  ///
  /// In en, this message translates to:
  /// **'Not found on {name} (deleted, private or a wrong link).'**
  String notFoundOnDeletedPrivateOr(Object name);

  /// No description provided for @hasServerProblemsTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'{name} has server problems. Try again later.'**
  String hasServerProblemsTryAgainLater(Object name);

  /// No description provided for @needsAnApiKeyInThe.
  ///
  /// In en, this message translates to:
  /// **'{name} needs an API key in the online config file (Settings → Online services).'**
  String needsAnApiKeyInThe(Object name);

  /// No description provided for @isTurnedOffInSettingsOnline.
  ///
  /// In en, this message translates to:
  /// **'{name} is turned off in Settings → Online services.'**
  String isTurnedOffInSettingsOnline(Object name);

  /// No description provided for @canNotDoThis.
  ///
  /// In en, this message translates to:
  /// **'{name} can not do this.'**
  String canNotDoThis(Object name);

  /// No description provided for @sentSomethingUnexpectedItMayHave.
  ///
  /// In en, this message translates to:
  /// **'{name} sent something unexpected (it may have changed). Try again later.'**
  String sentSomethingUnexpectedItMayHave(Object name);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {e}'**
  String somethingWentWrong(Object e);

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @playlistCreated.
  ///
  /// In en, this message translates to:
  /// **'Playlist created'**
  String get playlistCreated;

  /// No description provided for @playlistUpdated.
  ///
  /// In en, this message translates to:
  /// **'Playlist updated'**
  String get playlistUpdated;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @thisImportWasDeleted.
  ///
  /// In en, this message translates to:
  /// **'This import was deleted'**
  String get thisImportWasDeleted;

  /// No description provided for @openPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Open playlist'**
  String get openPlaylist;

  /// No description provided for @matchedOf.
  ///
  /// In en, this message translates to:
  /// **'{matched} of {total} matched'**
  String matchedOf(Object matched, Object total);

  /// No description provided for @nToCheck.
  ///
  /// In en, this message translates to:
  /// **'{n} to check'**
  String nToCheck(Object n);

  /// No description provided for @nNotFound.
  ///
  /// In en, this message translates to:
  /// **'{n} not found'**
  String nNotFound(Object n);

  /// No description provided for @matchingLocalFilesFirstThenOnline.
  ///
  /// In en, this message translates to:
  /// **'Matching {done} / {total}… (local files first, then online)'**
  String matchingLocalFilesFirstThenOnline(Object done, Object total);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resumeMatchingLeft.
  ///
  /// In en, this message translates to:
  /// **'Resume matching ({left} left)'**
  String resumeMatchingLeft(Object left);

  /// No description provided for @updatePlaylistWithFixes.
  ///
  /// In en, this message translates to:
  /// **'Update playlist with fixes'**
  String get updatePlaylistWithFixes;

  /// No description provided for @xAll.
  ///
  /// In en, this message translates to:
  /// **'All {n}'**
  String xAll(Object n);

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check {n}'**
  String check(Object n);

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found {n}'**
  String notFound(Object n);

  /// No description provided for @matched.
  ///
  /// In en, this message translates to:
  /// **'Matched {n}'**
  String matched(Object n);

  /// No description provided for @duplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates {n}'**
  String duplicates(Object n);

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting…'**
  String get waiting;

  /// No description provided for @duplicateOfSkipped.
  ///
  /// In en, this message translates to:
  /// **'Duplicate of #{n} – skipped'**
  String duplicateOfSkipped(Object n);

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @noGoodMatchFound.
  ///
  /// In en, this message translates to:
  /// **'No good match found'**
  String get noGoodMatchFound;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @fixMatch.
  ///
  /// In en, this message translates to:
  /// **'Fix match'**
  String get fixMatch;

  /// No description provided for @markedAsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Marked as no match'**
  String get markedAsNoMatch;

  /// No description provided for @nothingFoundTryOtherWords.
  ///
  /// In en, this message translates to:
  /// **'Nothing found – try other words'**
  String get nothingFoundTryOtherWords;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @pasteAPlaylistAlbumOrLikes.
  ///
  /// In en, this message translates to:
  /// **'Paste a playlist, album or likes link from Spotify, YouTube, SoundCloud, Apple Music or Deezer'**
  String get pasteAPlaylistAlbumOrLikes;

  /// No description provided for @isTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'{service} is turned off'**
  String isTurnedOff(Object service);

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'not available'**
  String get notAvailable;

  /// No description provided for @setUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setUp;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading {service}…'**
  String reading(Object service);

  /// No description provided for @importAPlaylistFile.
  ///
  /// In en, this message translates to:
  /// **'Import a playlist file'**
  String get importAPlaylistFile;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'playlist'**
  String get playlist;

  /// No description provided for @album2.
  ///
  /// In en, this message translates to:
  /// **'album'**
  String get album2;

  /// No description provided for @song.
  ///
  /// In en, this message translates to:
  /// **'song'**
  String get song;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'likes'**
  String get likes;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'link'**
  String get link;

  /// No description provided for @playlistAlbumAndLikesLinksWork.
  ///
  /// In en, this message translates to:
  /// **'Playlist, album and likes links work'**
  String get playlistAlbumAndLikesLinksWork;

  /// No description provided for @notALinkPrismCanRead.
  ///
  /// In en, this message translates to:
  /// **'Not a link Prism can read'**
  String get notALinkPrismCanRead;

  /// No description provided for @needsToBeSetUpFirst.
  ///
  /// In en, this message translates to:
  /// **'{what} · {service} needs to be set up first'**
  String needsToBeSetUpFirst(Object what, Object service);

  /// No description provided for @fromYourClipboard.
  ///
  /// In en, this message translates to:
  /// **' · from your clipboard'**
  String get fromYourClipboard;

  /// No description provided for @importPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Import playlists'**
  String get importPlaylists;

  /// No description provided for @bringYourPlaylistsFromSpotifyYoutube.
  ///
  /// In en, this message translates to:
  /// **'Bring your playlists from Spotify, YouTube and other apps. Prism finds each song in your library first, then online, and shows how sure each match is.'**
  String get bringYourPlaylistsFromSpotifyYoutube;

  /// No description provided for @pasteALink.
  ///
  /// In en, this message translates to:
  /// **'Paste a link'**
  String get pasteALink;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @xImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get xImport;

  /// No description provided for @orAFileCsvFromExportify.
  ///
  /// In en, this message translates to:
  /// **'Or a file: CSV from Exportify or TuneMyMusic, JSON, M3U'**
  String get orAFileCsvFromExportify;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @setUpServices.
  ///
  /// In en, this message translates to:
  /// **'Set up services'**
  String get setUpServices;

  /// No description provided for @fromYourAccounts.
  ///
  /// In en, this message translates to:
  /// **'From your accounts'**
  String get fromYourAccounts;

  /// No description provided for @yourImports.
  ///
  /// In en, this message translates to:
  /// **'Your imports'**
  String get yourImports;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading {service}…'**
  String loading(Object service);

  /// No description provided for @notConnectedSettingsOnlineServices.
  ///
  /// In en, this message translates to:
  /// **'Not connected – Settings → Online services'**
  String get notConnectedSettingsOnlineServices;

  /// No description provided for @likedVideos.
  ///
  /// In en, this message translates to:
  /// **'Liked videos'**
  String get likedVideos;

  /// No description provided for @likedSongs.
  ///
  /// In en, this message translates to:
  /// **'Liked songs'**
  String get likedSongs;

  /// No description provided for @readingLikes.
  ///
  /// In en, this message translates to:
  /// **'Reading likes…'**
  String get readingLikes;

  /// No description provided for @savedAlbums.
  ///
  /// In en, this message translates to:
  /// **'Saved albums…'**
  String get savedAlbums;

  /// No description provided for @savedAlbums2.
  ///
  /// In en, this message translates to:
  /// **'Saved albums'**
  String get savedAlbums2;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists…'**
  String get playlists;

  /// No description provided for @playlists2.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists2;

  /// No description provided for @xImport2.
  ///
  /// In en, this message translates to:
  /// **'Import {n}'**
  String xImport2(Object n);

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get nothingHere;

  /// No description provided for @matching.
  ///
  /// In en, this message translates to:
  /// **'Matching {done} / {total}…'**
  String matching(Object done, Object total);

  /// No description provided for @pausedLeft.
  ///
  /// In en, this message translates to:
  /// **'Paused · {n} left'**
  String pausedLeft(Object n);

  /// No description provided for @stoppedLeftTapToResume.
  ///
  /// In en, this message translates to:
  /// **'Stopped · {n} left – tap to resume'**
  String stoppedLeftTapToResume(Object n);

  /// No description provided for @ofMatchedReadyToSave.
  ///
  /// In en, this message translates to:
  /// **'{matched} of {total} matched · ready to save'**
  String ofMatchedReadyToSave(Object matched, Object total);

  /// No description provided for @ofMatchedSaved.
  ///
  /// In en, this message translates to:
  /// **'{matched} of {total} matched · saved'**
  String ofMatchedSaved(Object matched, Object total);

  /// No description provided for @thisImportThePlaylistStays.
  ///
  /// In en, this message translates to:
  /// **'this import (the playlist stays)'**
  String get thisImportThePlaylistStays;

  /// No description provided for @deleteImport.
  ///
  /// In en, this message translates to:
  /// **'Delete import'**
  String get deleteImport;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @onlyYourLibraryWillBeSearched.
  ///
  /// In en, this message translates to:
  /// **'Only your library will be searched'**
  String get onlyYourLibraryWillBeSearched;

  /// No description provided for @turnOnYoutubePlaybackOrSoundcloud.
  ///
  /// In en, this message translates to:
  /// **'Turn on YouTube playback or SoundCloud in Settings → Online services to also match songs you don\'t have.'**
  String get turnOnYoutubePlaybackOrSoundcloud;

  /// No description provided for @sameSongTwiceInOneList.
  ///
  /// In en, this message translates to:
  /// **'Same song twice in one list (also different \"remaster\" tags)'**
  String get sameSongTwiceInOneList;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @importedBefore.
  ///
  /// In en, this message translates to:
  /// **'Imported before'**
  String get importedBefore;

  /// No description provided for @ofMatchedImportingAgainMakesA.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" – {matched} of {total} matched. Importing again makes a new playlist.'**
  String ofMatchedImportingAgainMakesA(
    Object name,
    Object matched,
    Object total,
  );

  /// No description provided for @duplicateOf.
  ///
  /// In en, this message translates to:
  /// **'duplicate of #{n}'**
  String duplicateOf(Object n);

  /// No description provided for @onlineServices.
  ///
  /// In en, this message translates to:
  /// **'Online services'**
  String get onlineServices;

  /// No description provided for @apiKeysFile.
  ///
  /// In en, this message translates to:
  /// **'API keys file'**
  String get apiKeysFile;

  /// No description provided for @keysAreReadOnlyFromThis.
  ///
  /// In en, this message translates to:
  /// **'Keys are read only from this local file (never stored in the app or the repo). See README → Online services.'**
  String get keysAreReadOnlyFromThis;

  /// No description provided for @createFile.
  ///
  /// In en, this message translates to:
  /// **'Create file'**
  String get createFile;

  /// No description provided for @templateAtFillInYourKeys.
  ///
  /// In en, this message translates to:
  /// **'Template at {path} – fill in your keys, then tap Reload.'**
  String templateAtFillInYourKeys(Object path);

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @configReloaded.
  ///
  /// In en, this message translates to:
  /// **'Config reloaded'**
  String get configReloaded;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @importPlaylistsLikedSongsAndSaved.
  ///
  /// In en, this message translates to:
  /// **'Import playlists, liked songs and saved albums (no audio)'**
  String get importPlaylistsLikedSongsAndSaved;

  /// No description provided for @searchPlaylistsPlaybackYoutubeYoutubeMusic.
  ///
  /// In en, this message translates to:
  /// **'Search, playlists, playback (YouTube + YouTube Music links)'**
  String get searchPlaylistsPlaybackYoutubeYoutubeMusic;

  /// No description provided for @searchLikesAndPlaylistsPlaybackWhere.
  ///
  /// In en, this message translates to:
  /// **'Search, likes and playlists, playback where allowed'**
  String get searchLikesAndPlaylistsPlaybackWhere;

  /// No description provided for @importPublicPlaylistAlbumLinksNo.
  ///
  /// In en, this message translates to:
  /// **'Import public playlist / album links (no login)'**
  String get importPublicPlaylistAlbumLinksNo;

  /// No description provided for @importPublicPlaylistAlbumLinksReads.
  ///
  /// In en, this message translates to:
  /// **'Import public playlist / album links (reads the web page)'**
  String get importPublicPlaylistAlbumLinksReads;

  /// No description provided for @finishTheLoginInYourBrowser.
  ///
  /// In en, this message translates to:
  /// **'Finish the {service} login in your browser…'**
  String finishTheLoginInYourBrowser(Object service);

  /// No description provided for @turnOnTheYoutubeExtractor.
  ///
  /// In en, this message translates to:
  /// **'Turn on the YouTube extractor?'**
  String get turnOnTheYoutubeExtractor;

  /// No description provided for @thisPlaysYoutubeAudioInsidePrism.
  ///
  /// In en, this message translates to:
  /// **'This plays YouTube audio inside Prism, searches without an API key and can save offline copies. It uses an unofficial extractor, which YouTube\'s Terms of Service do not allow.\n\nUse it only for yourself, don\'t share saved files, and expect it to break sometimes.'**
  String get thisPlaysYoutubeAudioInsidePrism;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @iUnderstandTurnOn.
  ///
  /// In en, this message translates to:
  /// **'I understand, turn on'**
  String get iUnderstandTurnOn;

  /// No description provided for @needsSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs setup: {msg}'**
  String needsSetup(Object msg);

  /// No description provided for @notWorking.
  ///
  /// In en, this message translates to:
  /// **'Not working: {msg}'**
  String notWorking(Object msg);

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @redirectUriToRegister.
  ///
  /// In en, this message translates to:
  /// **'Redirect URI to register: {uri}'**
  String redirectUriToRegister(Object uri);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @youtubeExtractor.
  ///
  /// In en, this message translates to:
  /// **'YouTube extractor'**
  String get youtubeExtractor;

  /// No description provided for @playbackOfflineCopiesSearchWithoutAn.
  ///
  /// In en, this message translates to:
  /// **'Playback, offline copies, search without an API key'**
  String get playbackOfflineCopiesSearchWithoutAn;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @keepPlayedSongsOffline.
  ///
  /// In en, this message translates to:
  /// **'Keep played songs offline'**
  String get keepPlayedSongsOffline;

  /// No description provided for @savesACopyOfYoutubeSongs.
  ///
  /// In en, this message translates to:
  /// **'Saves a copy of YouTube songs you play, so they work without internet'**
  String get savesACopyOfYoutubeSongs;

  /// No description provided for @needsTheYoutubeExtractor.
  ///
  /// In en, this message translates to:
  /// **'Needs the YouTube extractor'**
  String get needsTheYoutubeExtractor;

  /// No description provided for @offlineCopiesMbOfGb.
  ///
  /// In en, this message translates to:
  /// **'Offline copies: {mb} MB of {gb} GB'**
  String offlineCopiesMbOfGb(Object mb, Object gb);

  /// No description provided for @gb.
  ///
  /// In en, this message translates to:
  /// **'{gb} GB'**
  String gb(Object gb);

  /// No description provided for @spotifyImportOnlyNeverAudio.
  ///
  /// In en, this message translates to:
  /// **'Spotify – import only, never audio'**
  String get spotifyImportOnlyNeverAudio;

  /// No description provided for @usesTheOfficialWebApiTo.
  ///
  /// In en, this message translates to:
  /// **'Uses the official Web API to read your playlists, liked songs and saved albums as text (title, artist, length). Prism never downloads, records or plays Spotify audio; songs are matched to your files or other services. Spotify\'s Developer Terms allow non-commercial apps; a Development Mode app works for at most 5 people you add in the Spotify dashboard, and only reads playlists you own or collaborate on.'**
  String get usesTheOfficialWebApiTo;

  /// No description provided for @youtubeDataApiOfficial.
  ///
  /// In en, this message translates to:
  /// **'YouTube Data API – official'**
  String get youtubeDataApiOfficial;

  /// No description provided for @searchPlaylistsAndWithGoogleLogin.
  ///
  /// In en, this message translates to:
  /// **'Search, playlists and (with Google login) your own playlists and liked videos through the official API with your own key. Limited by its daily quota (about 100 searches/day). The official API has no audio.'**
  String get searchPlaylistsAndWithGoogleLogin;

  /// No description provided for @youtubeExtractorPlaybackAndOfflineCopies.
  ///
  /// In en, this message translates to:
  /// **'YouTube extractor – playback and offline copies'**
  String get youtubeExtractorPlaybackAndOfflineCopies;

  /// No description provided for @playsYoutubeAudioInsidePrismSearches.
  ///
  /// In en, this message translates to:
  /// **'Plays YouTube audio inside Prism, searches without a key and saves offline copies using an unofficial extractor (youtube_explode_dart). YouTube\'s Terms of Service do not allow this (no access except through their player, no downloads without a download button). Off by default; turn it on only for yourself, don\'t share saved files, and expect it to break when YouTube changes.'**
  String get playsYoutubeAudioInsidePrismSearches;

  /// No description provided for @soundcloudOfficialApi.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud – official API'**
  String get soundcloudOfficialApi;

  /// No description provided for @searchYourLikesAndPlaylistsThrough.
  ///
  /// In en, this message translates to:
  /// **'Search, your likes and playlists through the official API with your own registered app. Only tracks the uploader made streamable are played, always credited to SoundCloud with a link. No offline copies (the API terms don\'t allow storing audio).'**
  String get searchYourLikesAndPlaylistsThrough;

  /// No description provided for @deezerPublicPlaylistLinks.
  ///
  /// In en, this message translates to:
  /// **'Deezer – public playlist links'**
  String get deezerPublicPlaylistLinks;

  /// No description provided for @readsPublicPlaylistsAlbumsAndSongs.
  ///
  /// In en, this message translates to:
  /// **'Reads public playlists, albums and songs from Deezer\'s open API (text only, no login, no audio). Deezer\'s API terms are for non-commercial use.'**
  String get readsPublicPlaylistsAlbumsAndSongs;

  /// No description provided for @appleMusicPublicPageReading.
  ///
  /// In en, this message translates to:
  /// **'Apple Music – public page reading'**
  String get appleMusicPublicPageReading;

  /// No description provided for @appleHasNoFreeApiSo.
  ///
  /// In en, this message translates to:
  /// **'Apple has no free API, so Prism reads the song list from the public web page of a playlist or album when you import a link. Best effort: it can stop working whenever Apple changes the page. For personal use.'**
  String get appleHasNoFreeApiSo;

  /// No description provided for @personalUseOnly.
  ///
  /// In en, this message translates to:
  /// **'Personal use only'**
  String get personalUseOnly;

  /// No description provided for @whatEachServiceAllows.
  ///
  /// In en, this message translates to:
  /// **'What each service allows'**
  String get whatEachServiceAllows;

  /// No description provided for @termsOfServiceLimitsInPlain.
  ///
  /// In en, this message translates to:
  /// **'Terms of service limits, in plain words'**
  String get termsOfServiceLimitsInPlain;

  /// No description provided for @prismIsAPersonalPlayerFor.
  ///
  /// In en, this message translates to:
  /// **'Prism is a personal player for you and friends. It is not affiliated with any of these services. API keys and logins are yours: keys stay in a local config file, logins in the system keychain.'**
  String get prismIsAPersonalPlayerFor;

  /// No description provided for @deezer.
  ///
  /// In en, this message translates to:
  /// **'Deezer: {msg}'**
  String deezer(Object msg);

  /// No description provided for @couldNotOpenThisDeezerShort.
  ///
  /// In en, this message translates to:
  /// **'Could not open this Deezer short link.'**
  String get couldNotOpenThisDeezerShort;

  /// No description provided for @deezerPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Deezer playlist'**
  String get deezerPlaylist;

  /// No description provided for @openThisLink.
  ///
  /// In en, this message translates to:
  /// **'open this link'**
  String get openThisLink;

  /// No description provided for @couldNotReadSongsFromThis.
  ///
  /// In en, this message translates to:
  /// **'Could not read songs from this Apple Music page (private playlist, or Apple changed the page). Use a TuneMyMusic CSV export instead.'**
  String get couldNotReadSongsFromThis;

  /// No description provided for @appleMusicPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Apple Music playlist'**
  String get appleMusicPlaylist;

  /// No description provided for @canNot.
  ///
  /// In en, this message translates to:
  /// **'{service} can not {what}.'**
  String canNot(Object service, Object what);

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'log in'**
  String get logIn;

  /// No description provided for @listYourPlaylists.
  ///
  /// In en, this message translates to:
  /// **'list your playlists'**
  String get listYourPlaylists;

  /// No description provided for @listSavedAlbums.
  ///
  /// In en, this message translates to:
  /// **'list saved albums'**
  String get listSavedAlbums;

  /// No description provided for @readLikedSongs.
  ///
  /// In en, this message translates to:
  /// **'read liked songs'**
  String get readLikedSongs;

  /// No description provided for @openPlaylists.
  ///
  /// In en, this message translates to:
  /// **'open playlists'**
  String get openPlaylists;

  /// No description provided for @openLinks.
  ///
  /// In en, this message translates to:
  /// **'open links'**
  String get openLinks;

  /// No description provided for @playAudio.
  ///
  /// In en, this message translates to:
  /// **'play audio'**
  String get playAudio;

  /// No description provided for @saveSongsOffline.
  ///
  /// In en, this message translates to:
  /// **'save songs offline'**
  String get saveSongsOffline;

  /// No description provided for @soundcloudLogInOrAddThe.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud: log in, or add the app\'s client secret to the config file for search without login.'**
  String get soundcloudLogInOrAddThe;

  /// No description provided for @soundcloudUser.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud user'**
  String get soundcloudUser;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @playlist2.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist2;

  /// No description provided for @likesSoundcloud.
  ///
  /// In en, this message translates to:
  /// **'Likes (SoundCloud)'**
  String get likesSoundcloud;

  /// No description provided for @soundcloudPlaylist.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud playlist'**
  String get soundcloudPlaylist;

  /// No description provided for @likesOf.
  ///
  /// In en, this message translates to:
  /// **'Likes of {user}'**
  String likesOf(Object user);

  /// No description provided for @theUploaderDoesNotAllowStreaming.
  ///
  /// In en, this message translates to:
  /// **'The uploader does not allow streaming this SoundCloud track outside SoundCloud.'**
  String get theUploaderDoesNotAllowStreaming;

  /// No description provided for @spotifyUser.
  ///
  /// In en, this message translates to:
  /// **'Spotify user'**
  String get spotifyUser;

  /// No description provided for @likedSongsSpotify.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs (Spotify)'**
  String get likedSongsSpotify;

  /// No description provided for @openTheSpotifyLinkInA.
  ///
  /// In en, this message translates to:
  /// **'Open the spotify.link in a browser and paste the full open.spotify.com link.'**
  String get openTheSpotifyLinkInA;

  /// No description provided for @spotifyPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Spotify playlist'**
  String get spotifyPlaylist;

  /// No description provided for @spotifyOnlyLetsSmallDevelopmentMode.
  ///
  /// In en, this message translates to:
  /// **'Spotify only lets small (Development Mode) apps read playlists you own or collaborate on. For other playlists: export them with Exportify or TuneMyMusic and import the CSV file.'**
  String get spotifyOnlyLetsSmallDevelopmentMode;

  /// No description provided for @youtubeDataApiOfficial2.
  ///
  /// In en, this message translates to:
  /// **'YouTube Data API (official)'**
  String get youtubeDataApiOfficial2;

  /// No description provided for @youtubePlaylist.
  ///
  /// In en, this message translates to:
  /// **'YouTube playlist'**
  String get youtubePlaylist;

  /// No description provided for @youtubeExplodeUnofficial.
  ///
  /// In en, this message translates to:
  /// **'youtube_explode (unofficial)'**
  String get youtubeExplodeUnofficial;

  /// No description provided for @youtubeAsksToSlowDownToo.
  ///
  /// In en, this message translates to:
  /// **'YouTube asks to slow down (too many searches from this connection). Wait a while, then resume.'**
  String get youtubeAsksToSlowDownToo;

  /// No description provided for @youtubeDidNotAnswerInTime.
  ///
  /// In en, this message translates to:
  /// **'YouTube did not answer in time.'**
  String get youtubeDidNotAnswerInTime;

  /// No description provided for @thisYoutubeVideoIsUnavailableRemoved.
  ///
  /// In en, this message translates to:
  /// **'This YouTube video is unavailable (removed, private or region-locked). {e}'**
  String thisYoutubeVideoIsUnavailableRemoved(Object e);

  /// No description provided for @youtubeExtractorFailedYoutubeMayHave.
  ///
  /// In en, this message translates to:
  /// **'YouTube extractor failed – YouTube may have changed. {e}'**
  String youtubeExtractorFailedYoutubeMayHave(Object e);

  /// No description provided for @notAValidYoutubeId.
  ///
  /// In en, this message translates to:
  /// **'Not a valid YouTube id: {e}'**
  String notAValidYoutubeId(Object e);

  /// No description provided for @noAudioStreamForThisVideo.
  ///
  /// In en, this message translates to:
  /// **'No audio stream for this video.'**
  String get noAudioStreamForThisVideo;

  /// No description provided for @canNotStreamAudio.
  ///
  /// In en, this message translates to:
  /// **'{name} can not stream audio'**
  String canNotStreamAudio(Object name);

  /// No description provided for @canNotDownloadAudio.
  ///
  /// In en, this message translates to:
  /// **'{name} can not download audio'**
  String canNotDownloadAudio(Object name);

  /// No description provided for @addAYoutubeDataApiKey.
  ///
  /// In en, this message translates to:
  /// **'Add a YouTube Data API key to the config file, or turn on the YouTube extractor.'**
  String get addAYoutubeDataApiKey;

  /// No description provided for @searchAndImportWorkPlaybackNeeds.
  ///
  /// In en, this message translates to:
  /// **'Search and import work. Playback needs the YouTube extractor (personal use only).'**
  String get searchAndImportWorkPlaybackNeeds;

  /// No description provided for @googleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google account'**
  String get googleAccount;

  /// No description provided for @logInNoGoogleOauthClient.
  ///
  /// In en, this message translates to:
  /// **'log in (no Google OAuth client id in the config file)'**
  String get logInNoGoogleOauthClient;

  /// No description provided for @listYourPlaylistsWithoutAGoogle.
  ///
  /// In en, this message translates to:
  /// **'list your playlists without a Google login'**
  String get listYourPlaylistsWithoutAGoogle;

  /// No description provided for @readLikedVideosWithoutAGoogle.
  ///
  /// In en, this message translates to:
  /// **'read liked videos without a Google login'**
  String get readLikedVideosWithoutAGoogle;

  /// No description provided for @likedVideosYoutube.
  ///
  /// In en, this message translates to:
  /// **'Liked videos (YouTube)'**
  String get likedVideosYoutube;

  /// No description provided for @openThisKindOfLink.
  ///
  /// In en, this message translates to:
  /// **'open this kind of link'**
  String get openThisKindOfLink;

  /// No description provided for @youtubePlaybackIsOffTurnOn.
  ///
  /// In en, this message translates to:
  /// **'YouTube playback is off. Turn on \"YouTube extractor\" in Settings → Online services (personal use only).'**
  String get youtubePlaybackIsOffTurnOn;

  /// No description provided for @saveSongsOfflineWithoutTheExtractor.
  ///
  /// In en, this message translates to:
  /// **'save songs offline without the extractor'**
  String get saveSongsOfflineWithoutTheExtractor;

  /// No description provided for @waveform.
  ///
  /// In en, this message translates to:
  /// **'Waveform'**
  String get waveform;

  /// No description provided for @barsWithABrightTrailBehind.
  ///
  /// In en, this message translates to:
  /// **'Bars with a bright trail behind the playhead'**
  String get barsWithABrightTrailBehind;

  /// No description provided for @ribbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get ribbon;

  /// No description provided for @aLineThatWavesWhileThe.
  ///
  /// In en, this message translates to:
  /// **'A line that waves while the song plays and flattens on pause'**
  String get aLineThatWavesWhileThe;

  /// No description provided for @ledBlocks.
  ///
  /// In en, this message translates to:
  /// **'LED blocks'**
  String get ledBlocks;

  /// No description provided for @aHiFiMeterMadeOf.
  ///
  /// In en, this message translates to:
  /// **'A hi-fi meter made of small blocks, with a lit column at the playhead'**
  String get aHiFiMeterMadeOf;

  /// No description provided for @tuner.
  ///
  /// In en, this message translates to:
  /// **'Tuner'**
  String get tuner;

  /// No description provided for @aRadioDialWithANeedle.
  ///
  /// In en, this message translates to:
  /// **'A radio dial with a needle, the scale swells around it'**
  String get aRadioDialWithANeedle;

  /// No description provided for @liveSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Live spectrum'**
  String get liveSpectrum;

  /// No description provided for @theWholeBarIsASpectrum.
  ///
  /// In en, this message translates to:
  /// **'The whole bar is a spectrum analyser, it always moves'**
  String get theWholeBarIsASpectrum;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// No description provided for @endOfSong.
  ///
  /// In en, this message translates to:
  /// **'End of song'**
  String get endOfSong;

  /// No description provided for @x1Min.
  ///
  /// In en, this message translates to:
  /// **'< 1 min'**
  String get x1Min;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @speedPitch.
  ///
  /// In en, this message translates to:
  /// **'Speed & pitch'**
  String get speedPitch;

  /// No description provided for @aBLoop.
  ///
  /// In en, this message translates to:
  /// **'A-B loop'**
  String get aBLoop;

  /// No description provided for @setB.
  ///
  /// In en, this message translates to:
  /// **'Set B'**
  String get setB;

  /// No description provided for @listenTogether.
  ///
  /// In en, this message translates to:
  /// **'Listen together'**
  String get listenTogether;

  /// No description provided for @miniPlayer.
  ///
  /// In en, this message translates to:
  /// **'Mini player'**
  String get miniPlayer;

  /// No description provided for @leaveFullScreenF11.
  ///
  /// In en, this message translates to:
  /// **'Leave full screen (F11)'**
  String get leaveFullScreenF11;

  /// No description provided for @fullScreenF11.
  ///
  /// In en, this message translates to:
  /// **'Full screen (F11)'**
  String get fullScreenF11;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @editThisSong.
  ///
  /// In en, this message translates to:
  /// **'Edit this song'**
  String get editThisSong;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @visualizer.
  ///
  /// In en, this message translates to:
  /// **'Visualizer'**
  String get visualizer;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute ({v} %)'**
  String mute(Object v);

  /// No description provided for @queueIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get queueIsEmpty;

  /// No description provided for @stopsAfterThisSong.
  ///
  /// In en, this message translates to:
  /// **'Stops after this song'**
  String get stopsAfterThisSong;

  /// No description provided for @stopsIn.
  ///
  /// In en, this message translates to:
  /// **'Stops in {t}'**
  String stopsIn(Object t);

  /// No description provided for @musicFadesOutAndPauses.
  ///
  /// In en, this message translates to:
  /// **'Music fades out and pauses'**
  String get musicFadesOutAndPauses;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOff;

  /// No description provided for @loopingTapToClear.
  ///
  /// In en, this message translates to:
  /// **'Looping {a}–{b} (tap to clear)'**
  String loopingTapToClear(Object a, Object b);

  /// No description provided for @tapAgainToSetB.
  ///
  /// In en, this message translates to:
  /// **'Tap again to set B'**
  String get tapAgainToSetB;

  /// No description provided for @aBLoopTapToSet.
  ///
  /// In en, this message translates to:
  /// **'A-B loop: tap to set A'**
  String get aBLoopTapToSet;

  /// No description provided for @xPitchKept.
  ///
  /// In en, this message translates to:
  /// **'{v}x  (pitch kept)'**
  String xPitchKept(Object v);

  /// No description provided for @pitch.
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get pitch;

  /// No description provided for @semitonesSpeedKept.
  ///
  /// In en, this message translates to:
  /// **'{sign}{v} semitones  (speed kept)'**
  String semitonesSpeedKept(Object sign, Object v);

  /// No description provided for @reset2.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset2;

  /// No description provided for @shuffleOn.
  ///
  /// In en, this message translates to:
  /// **'Shuffle on'**
  String get shuffleOn;

  /// No description provided for @shuffleOff.
  ///
  /// In en, this message translates to:
  /// **'Shuffle off'**
  String get shuffleOff;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get repeatOne;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @yourListeningStats.
  ///
  /// In en, this message translates to:
  /// **'Your listening stats'**
  String get yourListeningStats;

  /// No description provided for @topSongsArtistsAndStreaks.
  ///
  /// In en, this message translates to:
  /// **'Top songs, artists and streaks'**
  String get topSongsArtistsAndStreaks;

  /// No description provided for @fromSpotifyYoutubeSoundcloudDeezerApple.
  ///
  /// In en, this message translates to:
  /// **'From a link or a file. Spotify, YouTube, SoundCloud, Yandex Music, Apple Music, Deezer'**
  String get fromSpotifyYoutubeSoundcloudDeezerApple;

  /// No description provided for @smartPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Smart playlists'**
  String get smartPlaylists;

  /// No description provided for @xNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get xNew;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylist;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete2.
  ///
  /// In en, this message translates to:
  /// **'Delete {what}?'**
  String delete2(Object what);

  /// No description provided for @thisCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get thisCannotBeUndone;

  /// No description provided for @addToPlaylist2.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist2;

  /// No description provided for @newPlaylist2.
  ///
  /// In en, this message translates to:
  /// **'New playlist…'**
  String get newPlaylist2;

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to playlist'**
  String get addedToPlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @emptyPlaylistLongPressASong.
  ///
  /// In en, this message translates to:
  /// **'Empty playlist.\nLong-press a song → \"Add to playlist\".'**
  String get emptyPlaylistLongPressASong;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @saturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturation;

  /// No description provided for @lightness.
  ///
  /// In en, this message translates to:
  /// **'Lightness'**
  String get lightness;

  /// No description provided for @noLyricsPlain.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found.\nPut a .lrc file with the same name next to the song.'**
  String get noLyricsPlain;

  /// No description provided for @noLyricsHint.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found.\nPut a .lrc file with the same name next to the song, or turn on online lyrics in Settings.'**
  String get noLyricsHint;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @onlineImport.
  ///
  /// In en, this message translates to:
  /// **'Online & import'**
  String get onlineImport;

  /// No description provided for @windows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get windows;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @crossfadeN.
  ///
  /// In en, this message translates to:
  /// **'Crossfade {s} s'**
  String crossfadeN(Object s);

  /// No description provided for @gapless.
  ///
  /// In en, this message translates to:
  /// **'Gapless'**
  String get gapless;

  /// No description provided for @eqOn.
  ///
  /// In en, this message translates to:
  /// **'EQ on'**
  String get eqOn;

  /// No description provided for @eqOff.
  ///
  /// In en, this message translates to:
  /// **'EQ off'**
  String get eqOff;

  /// No description provided for @importPlaylistsAccountsOfflineCopies.
  ///
  /// In en, this message translates to:
  /// **'Import playlists, accounts, offline copies'**
  String get importPlaylistsAccountsOfflineCopies;

  /// No description provided for @anywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get anywhere;

  /// No description provided for @sameWiFiOnly.
  ///
  /// In en, this message translates to:
  /// **'Same Wi-Fi only'**
  String get sameWiFiOnly;

  /// No description provided for @closesToTheTray.
  ///
  /// In en, this message translates to:
  /// **'Closes to the tray'**
  String get closesToTheTray;

  /// No description provided for @saveOrRestoreEverythingInOne.
  ///
  /// In en, this message translates to:
  /// **'Save or restore everything in one file'**
  String get saveOrRestoreEverythingInOne;

  /// No description provided for @musicFolders.
  ///
  /// In en, this message translates to:
  /// **'Music folders'**
  String get musicFolders;

  /// No description provided for @removeFolder.
  ///
  /// In en, this message translates to:
  /// **'Remove folder'**
  String get removeFolder;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get addFolder;

  /// No description provided for @rescanLibrary.
  ///
  /// In en, this message translates to:
  /// **'Rescan library'**
  String get rescanLibrary;

  /// No description provided for @lastScanNewChangedRemovedIn.
  ///
  /// In en, this message translates to:
  /// **'Last scan: {added} new, {updated} changed, {removed} removed in {s} s'**
  String lastScanNewChangedRemovedIn(
    Object added,
    Object updated,
    Object removed,
    Object s,
  );

  /// No description provided for @onlyNewOrChangedFilesAre.
  ///
  /// In en, this message translates to:
  /// **'Only new or changed files are read again'**
  String get onlyNewOrChangedFilesAre;

  /// No description provided for @findDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Find duplicates'**
  String get findDuplicates;

  /// No description provided for @theSameSongInSeveralFiles.
  ///
  /// In en, this message translates to:
  /// **'The same song in several files'**
  String get theSameSongInSeveralFiles;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @crossfade.
  ///
  /// In en, this message translates to:
  /// **'Crossfade'**
  String get crossfade;

  /// No description provided for @blendTheEndOfASong.
  ///
  /// In en, this message translates to:
  /// **'Blend the end of a song into the next one'**
  String get blendTheEndOfASong;

  /// No description provided for @offGapless.
  ///
  /// In en, this message translates to:
  /// **'Off, gapless'**
  String get offGapless;

  /// No description provided for @sendsOnlyTitleArtistAlbumAnd.
  ///
  /// In en, this message translates to:
  /// **'Sends only title, artist, album and length to lrclib.net. Local .lrc files always work.'**
  String get sendsOnlyTitleArtistAlbumAnd;

  /// No description provided for @findLyricsOnline.
  ///
  /// In en, this message translates to:
  /// **'Find lyrics online'**
  String get findLyricsOnline;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @matrixConstellationRippleReactsToThe.
  ///
  /// In en, this message translates to:
  /// **'Matrix, Constellation, Ripple. Reacts to the mouse and the music'**
  String get matrixConstellationRippleReactsToThe;

  /// No description provided for @shownInTheFullPlayer.
  ///
  /// In en, this message translates to:
  /// **'Shown in the full player'**
  String get shownInTheFullPlayer;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @turnsOffDecorativeAnimations.
  ///
  /// In en, this message translates to:
  /// **'Turns off decorative animations'**
  String get turnsOffDecorativeAnimations;

  /// No description provided for @seekBar.
  ///
  /// In en, this message translates to:
  /// **'Seek bar'**
  String get seekBar;

  /// No description provided for @rightClickTheSeekBarTo.
  ///
  /// In en, this message translates to:
  /// **'Right-click the seek bar to switch any time.'**
  String get rightClickTheSeekBarTo;

  /// No description provided for @movesWithTheMusic.
  ///
  /// In en, this message translates to:
  /// **'Moves with the music'**
  String get movesWithTheMusic;

  /// No description provided for @everyStyleReactsToTheSong.
  ///
  /// In en, this message translates to:
  /// **'Every style reacts to the song. Analyses each song once, the first time it plays'**
  String get everyStyleReactsToTheSong;

  /// No description provided for @fromALinkAFileOr.
  ///
  /// In en, this message translates to:
  /// **'From a link, a file or your accounts'**
  String get fromALinkAFileOr;

  /// No description provided for @spotifyYoutubeSoundcloudDeezerAppleMusic.
  ///
  /// In en, this message translates to:
  /// **'Spotify, YouTube, SoundCloud, Deezer, Apple Music'**
  String get spotifyYoutubeSoundcloudDeezerAppleMusic;

  /// No description provided for @sessionsOnTheSameWiFi.
  ///
  /// In en, this message translates to:
  /// **'Sessions on the same Wi-Fi connect directly and show up in a list. Over the internet, messages go through a free public server (HiveMQ, EMQX or Mosquitto): song names, length and position, scrambled with the session code. Never any audio.'**
  String get sessionsOnTheSameWiFi;

  /// No description provided for @sessionsOverTheInternet.
  ///
  /// In en, this message translates to:
  /// **'Sessions over the internet'**
  String get sessionsOverTheInternet;

  /// No description provided for @offSameWiFiOnlyNothing.
  ///
  /// In en, this message translates to:
  /// **'Off: same Wi-Fi only, nothing leaves your network'**
  String get offSameWiFiOnlyNothing;

  /// No description provided for @yourNameInASession.
  ///
  /// In en, this message translates to:
  /// **'Your name in a session'**
  String get yourNameInASession;

  /// No description provided for @theNameOfThisDevice.
  ///
  /// In en, this message translates to:
  /// **'The name of this device'**
  String get theNameOfThisDevice;

  /// No description provided for @ownServerOptional.
  ///
  /// In en, this message translates to:
  /// **'Own server (optional)'**
  String get ownServerOptional;

  /// No description provided for @ifYouWouldRatherNotUse.
  ///
  /// In en, this message translates to:
  /// **'If you would rather not use the public server: someone runs \"dart run tool/relay.dart\" on a reachable computer and everyone enters its address here.'**
  String get ifYouWouldRatherNotUse;

  /// No description provided for @closeToTray.
  ///
  /// In en, this message translates to:
  /// **'Close to tray'**
  String get closeToTray;

  /// No description provided for @keepPlayingInTheTrayWhen.
  ///
  /// In en, this message translates to:
  /// **'Keep playing in the tray when the window is closed'**
  String get keepPlayingInTheTrayWhen;

  /// No description provided for @settingsEqThemesPlaylistsFavoritesSmart.
  ///
  /// In en, this message translates to:
  /// **'Settings, EQ, themes, playlists, favorites, smart playlists and edits. Songs are matched by path or by title and artist, so a backup also works on another device.'**
  String get settingsEqThemesPlaylistsFavoritesSmart;

  /// No description provided for @backUpToAFile.
  ///
  /// In en, this message translates to:
  /// **'Back up to a file'**
  String get backUpToAFile;

  /// No description provided for @restoreFromAFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from a file'**
  String get restoreFromAFile;

  /// No description provided for @aMusicPlayerForYourOwn.
  ///
  /// In en, this message translates to:
  /// **'A music player for your own songs, made for me and a few friends. Windows and Android.'**
  String get aMusicPlayerForYourOwn;

  /// No description provided for @lookingOfSongsFound.
  ///
  /// In en, this message translates to:
  /// **'Looking… {done} of {total} songs, found {found}'**
  String lookingOfSongsFound(Object done, Object total, Object found);

  /// No description provided for @nothingFoundYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing found yet'**
  String get nothingFoundYet;

  /// No description provided for @missingInfo.
  ///
  /// In en, this message translates to:
  /// **'Missing info'**
  String get missingInfo;

  /// No description provided for @sendsOnlyTitleAndArtistTo.
  ///
  /// In en, this message translates to:
  /// **'Sends only title and artist to Apple\'s and Deezer\'s public search. Your files are never changed and your own tags are never replaced. A song without tags only gets info when its file name clearly matches.'**
  String get sendsOnlyTitleAndArtistTo;

  /// No description provided for @findCoversAndArtistsOnline.
  ///
  /// In en, this message translates to:
  /// **'Find covers and artists online'**
  String get findCoversAndArtistsOnline;

  /// No description provided for @lookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get lookAgain;

  /// No description provided for @forSongsThatGotNothingSo.
  ///
  /// In en, this message translates to:
  /// **'For songs that got nothing so far'**
  String get forSongsThatGotNothingSo;

  /// No description provided for @undoEverythingFound.
  ///
  /// In en, this message translates to:
  /// **'Undo everything found'**
  String get undoEverythingFound;

  /// No description provided for @backToWhatYourFilesSay.
  ///
  /// In en, this message translates to:
  /// **'Back to what your files say'**
  String get backToWhatYourFilesSay;

  /// No description provided for @loudness.
  ///
  /// In en, this message translates to:
  /// **'Loudness'**
  String get loudness;

  /// No description provided for @usesReplaygainTagsOrMeasuresSongs.
  ///
  /// In en, this message translates to:
  /// **'Uses ReplayGain tags, or measures songs with FFmpeg (EBU R128, −18 LUFS).'**
  String get usesReplaygainTagsOrMeasuresSongs;

  /// No description provided for @evenOutLoudness.
  ///
  /// In en, this message translates to:
  /// **'Even out loudness'**
  String get evenOutLoudness;

  /// No description provided for @song2.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get song2;

  /// No description provided for @measureSongsAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Measure songs automatically'**
  String get measureSongsAutomatically;

  /// No description provided for @whenASongWithoutReplaygainTags.
  ///
  /// In en, this message translates to:
  /// **'When a song without ReplayGain tags starts playing'**
  String get whenASongWithoutReplaygainTags;

  /// No description provided for @measureTheWholeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Measure the whole library'**
  String get measureTheWholeLibrary;

  /// No description provided for @measuringOf.
  ///
  /// In en, this message translates to:
  /// **'Measuring {done} of {total}'**
  String measuringOf(Object done, Object total);

  /// No description provided for @ffmpegIsMissingOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg is missing on this device'**
  String get ffmpegIsMissingOnThisDevice;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @exportTheme.
  ///
  /// In en, this message translates to:
  /// **'Export theme'**
  String get exportTheme;

  /// No description provided for @themeExported.
  ///
  /// In en, this message translates to:
  /// **'Theme exported'**
  String get themeExported;

  /// No description provided for @importTheme.
  ///
  /// In en, this message translates to:
  /// **'Import theme'**
  String get importTheme;

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'Imported \"{name}\"'**
  String imported(Object name);

  /// No description provided for @couldNotImport.
  ///
  /// In en, this message translates to:
  /// **'Could not import: {e}'**
  String couldNotImport(Object e);

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as…'**
  String get saveAs;

  /// No description provided for @saveThemeAs.
  ///
  /// In en, this message translates to:
  /// **'Save theme as'**
  String get saveThemeAs;

  /// No description provided for @myTheme.
  ///
  /// In en, this message translates to:
  /// **'My theme'**
  String get myTheme;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved \"{name}\"'**
  String saved(Object name);

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @blackWhite.
  ///
  /// In en, this message translates to:
  /// **'Black & white'**
  String get blackWhite;

  /// No description provided for @greysOnlyCoversStayInColor.
  ///
  /// In en, this message translates to:
  /// **'Greys only, covers stay in color'**
  String get greysOnlyCoversStayInColor;

  /// No description provided for @colorsFromAlbumArt.
  ///
  /// In en, this message translates to:
  /// **'Colors from album art'**
  String get colorsFromAlbumArt;

  /// No description provided for @primaryColorFollowsTheCurrentCover.
  ///
  /// In en, this message translates to:
  /// **'Primary color follows the current cover'**
  String get primaryColorFollowsTheCurrentCover;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @accent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get accent;

  /// No description provided for @shapeSurfaces.
  ///
  /// In en, this message translates to:
  /// **'Shape & surfaces'**
  String get shapeSurfaces;

  /// No description provided for @cornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get cornerRadius;

  /// No description provided for @px.
  ///
  /// In en, this message translates to:
  /// **'{v} px'**
  String px(Object v);

  /// No description provided for @glassBlur.
  ///
  /// In en, this message translates to:
  /// **'Glass / blur'**
  String get glassBlur;

  /// No description provided for @textMotion.
  ///
  /// In en, this message translates to:
  /// **'Text & motion'**
  String get textMotion;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @animationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation speed'**
  String get animationSpeed;

  /// No description provided for @fastX.
  ///
  /// In en, this message translates to:
  /// **'Fast ({v}x)'**
  String fastX(Object v);

  /// No description provided for @slowX.
  ///
  /// In en, this message translates to:
  /// **'Slow ({v}x)'**
  String slowX(Object v);

  /// No description provided for @normalX.
  ///
  /// In en, this message translates to:
  /// **'Normal ({v}x)'**
  String normalX(Object v);

  /// No description provided for @themeName.
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get themeName;

  /// No description provided for @longPressToDelete.
  ///
  /// In en, this message translates to:
  /// **'{name} (long-press to delete)'**
  String longPressToDelete(Object name);

  /// No description provided for @previewSong.
  ///
  /// In en, this message translates to:
  /// **'Preview song'**
  String get previewSong;

  /// No description provided for @glassPanelPx.
  ///
  /// In en, this message translates to:
  /// **'Glass panel · {r} px'**
  String glassPanelPx(Object r);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code {code}'**
  String code(Object code);

  /// No description provided for @xWith.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String xWith(Object name);

  /// No description provided for @aFriend.
  ///
  /// In en, this message translates to:
  /// **'a friend'**
  String get aFriend;

  /// No description provided for @rightClickNextBackground.
  ///
  /// In en, this message translates to:
  /// **'Right-click: next background'**
  String get rightClickNextBackground;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @x5To12.
  ///
  /// In en, this message translates to:
  /// **'5 to 12'**
  String get x5To12;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @x12To18.
  ///
  /// In en, this message translates to:
  /// **'12 to 18'**
  String get x12To18;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @x18To23.
  ///
  /// In en, this message translates to:
  /// **'18 to 23'**
  String get x18To23;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @x23To5.
  ///
  /// In en, this message translates to:
  /// **'23 to 5'**
  String get x23To5;

  /// No description provided for @mostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get mostPlayed;

  /// No description provided for @forgottenGems.
  ///
  /// In en, this message translates to:
  /// **'Forgotten gems'**
  String get forgottenGems;

  /// No description provided for @smartPlaylistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Smart playlist not found'**
  String get smartPlaylistNotFound;

  /// No description provided for @editRules.
  ///
  /// In en, this message translates to:
  /// **'Edit rules'**
  String get editRules;

  /// No description provided for @allSongs.
  ///
  /// In en, this message translates to:
  /// **'all songs'**
  String get allSongs;

  /// No description provided for @playedNPlus.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{played {count}+ time} other{played {count}+ times}}'**
  String playedNPlus(int count);

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String inDays(Object days);

  /// No description provided for @addedInTheLastDays.
  ///
  /// In en, this message translates to:
  /// **'added in the last {days} days'**
  String addedInTheLastDays(Object days);

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'genre \"{genre}\"'**
  String genre(Object genre);

  /// No description provided for @year2.
  ///
  /// In en, this message translates to:
  /// **'year {from}–{to}'**
  String year2(Object from, Object to);

  /// No description provided for @notPlayedForDays.
  ///
  /// In en, this message translates to:
  /// **'not played for {days} days'**
  String notPlayedForDays(Object days);

  /// No description provided for @mySmartPlaylist.
  ///
  /// In en, this message translates to:
  /// **'My smart playlist'**
  String get mySmartPlaylist;

  /// No description provided for @minPlays.
  ///
  /// In en, this message translates to:
  /// **'min plays'**
  String get minPlays;

  /// No description provided for @inDays2.
  ///
  /// In en, this message translates to:
  /// **'in days'**
  String get inDays2;

  /// No description provided for @genre2.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre2;

  /// No description provided for @notPlayedFor.
  ///
  /// In en, this message translates to:
  /// **'Not played for'**
  String get notPlayedFor;

  /// No description provided for @editSmartPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Edit smart playlist'**
  String get editSmartPlaylist;

  /// No description provided for @newSmartPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New smart playlist'**
  String get newSmartPlaylist;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @songsThatMatchAllRules.
  ///
  /// In en, this message translates to:
  /// **'Songs that match all rules:'**
  String get songsThatMatchAllRules;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get addRule;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by  '**
  String get sortBy;

  /// No description provided for @random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @maxSongs.
  ///
  /// In en, this message translates to:
  /// **'max songs'**
  String get maxSongs;

  /// No description provided for @smartPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Smart playlist'**
  String get smartPlaylist;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'{m} min ago'**
  String minAgo(Object m);

  /// No description provided for @hAgo.
  ///
  /// In en, this message translates to:
  /// **'{h} h ago'**
  String hAgo(Object h);

  /// No description provided for @vsBefore.
  ///
  /// In en, this message translates to:
  /// **'{sign}{pct} % vs before'**
  String vsBefore(Object sign, Object pct);

  /// No description provided for @atAGlance.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get atAGlance;

  /// No description provided for @listeningTime.
  ///
  /// In en, this message translates to:
  /// **'Listening time'**
  String get listeningTime;

  /// No description provided for @plays.
  ///
  /// In en, this message translates to:
  /// **'Plays'**
  String get plays;

  /// No description provided for @differentSongs.
  ///
  /// In en, this message translates to:
  /// **'Different songs'**
  String get differentSongs;

  /// No description provided for @playedOnlyOnce.
  ///
  /// In en, this message translates to:
  /// **'{n} played only once'**
  String playedOnlyOnce(Object n);

  /// No description provided for @newToYou.
  ///
  /// In en, this message translates to:
  /// **'New to you'**
  String get newToYou;

  /// No description provided for @daysWithMusic.
  ///
  /// In en, this message translates to:
  /// **'Days with music'**
  String get daysWithMusic;

  /// No description provided for @aboutADay.
  ///
  /// In en, this message translates to:
  /// **'about {t} a day'**
  String aboutADay(Object t);

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'best: {n}'**
  String best(Object n);

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @aboutEach.
  ///
  /// In en, this message translates to:
  /// **'about {t} each'**
  String aboutEach(Object t);

  /// No description provided for @youHearOfASong.
  ///
  /// In en, this message translates to:
  /// **'You hear of a song'**
  String get youHearOfASong;

  /// No description provided for @onAverage.
  ///
  /// In en, this message translates to:
  /// **'on average'**
  String get onAverage;

  /// No description provided for @minutesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Minutes per day'**
  String get minutesPerDay;

  /// No description provided for @minutesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Minutes per month'**
  String get minutesPerMonth;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'{when} · {m} min'**
  String min(Object when, Object m);

  /// No description provided for @yourWeek.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get yourWeek;

  /// No description provided for @darkerMeansMoreMinutesHoverFor.
  ///
  /// In en, this message translates to:
  /// **'Darker means more minutes. Hover for the numbers.'**
  String get darkerMeansMoreMinutesHoverFor;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get last6Months;

  /// No description provided for @timeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get timeOfDay;

  /// No description provided for @ofYourListeningIsOnWeekends.
  ///
  /// In en, this message translates to:
  /// **'{pct} % of your listening is on weekends'**
  String ofYourListeningIsOnWeekends(Object pct);

  /// No description provided for @musicByDecade.
  ///
  /// In en, this message translates to:
  /// **'Music by decade'**
  String get musicByDecade;

  /// No description provided for @songsNeedAYearTagFor.
  ///
  /// In en, this message translates to:
  /// **'Songs need a year tag for this'**
  String get songsNeedAYearTagFor;

  /// No description provided for @howOldIsWhatYouPlay.
  ///
  /// In en, this message translates to:
  /// **'How old is what you play?'**
  String get howOldIsWhatYouPlay;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @longestSession.
  ///
  /// In en, this message translates to:
  /// **'Longest session'**
  String get longestSession;

  /// No description provided for @nSongsOnDate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song, {date}} other{{count} songs, {date}}}'**
  String nSongsOnDate(int count, Object date);

  /// No description provided for @biggestDay.
  ///
  /// In en, this message translates to:
  /// **'Biggest day'**
  String get biggestDay;

  /// No description provided for @onRepeat.
  ///
  /// In en, this message translates to:
  /// **'On repeat: {title}'**
  String onRepeat(Object title);

  /// No description provided for @xOn2.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String xOn2(Object date);

  /// No description provided for @loyalTo.
  ///
  /// In en, this message translates to:
  /// **'Loyal to {artist}'**
  String loyalTo(Object artist);

  /// No description provided for @ofYourPlays.
  ///
  /// In en, this message translates to:
  /// **'of your plays'**
  String get ofYourPlays;

  /// No description provided for @topSongs.
  ///
  /// In en, this message translates to:
  /// **'Top songs'**
  String get topSongs;

  /// No description provided for @topArtists.
  ///
  /// In en, this message translates to:
  /// **'Top artists'**
  String get topArtists;

  /// No description provided for @topAlbums.
  ///
  /// In en, this message translates to:
  /// **'Top albums'**
  String get topAlbums;

  /// No description provided for @topGenres.
  ///
  /// In en, this message translates to:
  /// **'Top genres'**
  String get topGenres;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @totalLength.
  ///
  /// In en, this message translates to:
  /// **'Total length'**
  String get totalLength;

  /// No description provided for @daysNonstop.
  ///
  /// In en, this message translates to:
  /// **'{d} days nonstop'**
  String daysNonstop(Object d);

  /// No description provided for @averageSong.
  ///
  /// In en, this message translates to:
  /// **'Average song'**
  String get averageSong;

  /// No description provided for @neverPlayed.
  ///
  /// In en, this message translates to:
  /// **'Never played'**
  String get neverPlayed;

  /// No description provided for @withACover.
  ///
  /// In en, this message translates to:
  /// **'With a cover'**
  String get withACover;

  /// No description provided for @fullyTagged.
  ///
  /// In en, this message translates to:
  /// **'{n} fully tagged'**
  String fullyTagged(Object n);

  /// No description provided for @extremes.
  ///
  /// In en, this message translates to:
  /// **'Extremes'**
  String get extremes;

  /// No description provided for @longest.
  ///
  /// In en, this message translates to:
  /// **'Longest: {title}'**
  String longest(Object title);

  /// No description provided for @shortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest: {title}'**
  String shortest(Object title);

  /// No description provided for @fileTypes.
  ///
  /// In en, this message translates to:
  /// **'File types'**
  String get fileTypes;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @decades.
  ///
  /// In en, this message translates to:
  /// **'Decades'**
  String get decades;

  /// No description provided for @noListensYetInThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No listens yet in this period.\nA song counts after 30 seconds, or half of it if it is short.'**
  String get noListensYetInThisPeriod;

  /// No description provided for @yourListening.
  ///
  /// In en, this message translates to:
  /// **'Your listening'**
  String get yourListening;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @xTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get xTop;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @wrapped.
  ///
  /// In en, this message translates to:
  /// **'Wrapped'**
  String get wrapped;

  /// No description provided for @aMorningListener.
  ///
  /// In en, this message translates to:
  /// **'a morning listener'**
  String get aMorningListener;

  /// No description provided for @anAfternoonListener.
  ///
  /// In en, this message translates to:
  /// **'an afternoon listener'**
  String get anAfternoonListener;

  /// No description provided for @anEveningListener.
  ///
  /// In en, this message translates to:
  /// **'an evening listener'**
  String get anEveningListener;

  /// No description provided for @aNightOwl.
  ///
  /// In en, this message translates to:
  /// **'a night owl'**
  String get aNightOwl;

  /// No description provided for @thisWeekYouListenedFor.
  ///
  /// In en, this message translates to:
  /// **'This week you listened for'**
  String get thisWeekYouListenedFor;

  /// No description provided for @thisMonthYouListenedFor.
  ///
  /// In en, this message translates to:
  /// **'This month you listened for'**
  String get thisMonthYouListenedFor;

  /// No description provided for @thisYearYouListenedFor.
  ///
  /// In en, this message translates to:
  /// **'This year you listened for'**
  String get thisYearYouListenedFor;

  /// No description provided for @inTotalYouListenedFor.
  ///
  /// In en, this message translates to:
  /// **'In total you listened for'**
  String get inTotalYouListenedFor;

  /// No description provided for @nDifferentSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} different song} other{{count} different songs}}'**
  String nDifferentSongs(int count);

  /// No description provided for @youAreMostPlaysAround00.
  ///
  /// In en, this message translates to:
  /// **'You are {who} – most plays around {hour}:00'**
  String youAreMostPlaysAround00(Object who, Object hour);

  /// No description provided for @longestListeningStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest listening streak'**
  String get longestListeningStreak;

  /// No description provided for @daysInARow.
  ///
  /// In en, this message translates to:
  /// **'days in a row'**
  String get daysInARow;

  /// No description provided for @daysInARowWithAt.
  ///
  /// In en, this message translates to:
  /// **'Days in a row with at least one song'**
  String get daysInARowWithAt;

  /// No description provided for @yourTopSong.
  ///
  /// In en, this message translates to:
  /// **'Your top song'**
  String get yourTopSong;

  /// No description provided for @whenYouListen.
  ///
  /// In en, this message translates to:
  /// **'When you listen'**
  String get whenYouListen;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get starting;

  /// No description provided for @couldNotStartCheckYourNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not start. Check your network connection.'**
  String get couldNotStartCheckYourNetwork;

  /// No description provided for @waitingForFriends.
  ///
  /// In en, this message translates to:
  /// **'Waiting for friends…'**
  String get waitingForFriends;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @listeningTogether.
  ///
  /// In en, this message translates to:
  /// **'Listening together'**
  String get listeningTogether;

  /// No description provided for @thatCodeDoesNotLookRight.
  ///
  /// In en, this message translates to:
  /// **'That code does not look right'**
  String get thatCodeDoesNotLookRight;

  /// No description provided for @lookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for {room}…'**
  String lookingFor(Object room);

  /// No description provided for @onlineSessionsAreOffSettingsListen.
  ///
  /// In en, this message translates to:
  /// **'Online sessions are off (Settings → Listen together)'**
  String get onlineSessionsAreOffSettingsListen;

  /// No description provided for @noSessionWithTheCodeCheck.
  ///
  /// In en, this message translates to:
  /// **'No session with the code {room}. Check the code, the host must keep Prism open.'**
  String noSessionWithTheCodeCheck(Object room);

  /// No description provided for @followingTheHost.
  ///
  /// In en, this message translates to:
  /// **'Following the host'**
  String get followingTheHost;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnecting;

  /// No description provided for @theHostIsGone.
  ///
  /// In en, this message translates to:
  /// **'The host is gone'**
  String get theHostIsGone;

  /// No description provided for @waitingForTheHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host…'**
  String get waitingForTheHost;

  /// No description provided for @theHostEndedTheSession.
  ///
  /// In en, this message translates to:
  /// **'The host ended the session'**
  String get theHostEndedTheSession;

  /// No description provided for @lookingForTheSongOnline.
  ///
  /// In en, this message translates to:
  /// **'Looking for the song online…'**
  String get lookingForTheSongOnline;

  /// No description provided for @theHostIsPlayingASong.
  ///
  /// In en, this message translates to:
  /// **'The host is playing a song you don\'t have'**
  String get theHostIsPlayingASong;

  /// No description provided for @everyonePlaysTheSameSongAt.
  ///
  /// In en, this message translates to:
  /// **'Everyone plays the same song at the same moment.'**
  String get everyonePlaysTheSameSongAt;

  /// No description provided for @sendThisCodeToYourFriends.
  ///
  /// In en, this message translates to:
  /// **'Send this code to your friends'**
  String get sendThisCodeToYourFriends;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @worksFromAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Works from anywhere.'**
  String get worksFromAnywhere;

  /// No description provided for @worksOnThisWiFiOnly.
  ///
  /// In en, this message translates to:
  /// **'Works on this Wi-Fi only.'**
  String get worksOnThisWiFiOnly;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session {code}'**
  String session(Object code);

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing: {song}'**
  String missing(Object song);

  /// No description provided for @addTheSongToYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add the song to your library, or turn on YouTube or SoundCloud in Settings → Online & import.'**
  String get addTheSongToYourLibrary;

  /// No description provided for @justYouAndTheHost.
  ///
  /// In en, this message translates to:
  /// **'Just you and the host'**
  String get justYouAndTheHost;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @friendSCode.
  ///
  /// In en, this message translates to:
  /// **'Friend\'s code'**
  String get friendSCode;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @startASession.
  ///
  /// In en, this message translates to:
  /// **'Start a session'**
  String get startASession;

  /// No description provided for @eachPersonPlaysTheSongFrom.
  ///
  /// In en, this message translates to:
  /// **'Each person plays the song from their own library. Song names pass through a free public server, scrambled with the code. You can turn that off in Settings → Listen together.'**
  String get eachPersonPlaysTheSongFrom;

  /// No description provided for @onThisNetwork.
  ///
  /// In en, this message translates to:
  /// **'On this network'**
  String get onThisNetwork;

  /// No description provided for @backupSummary.
  ///
  /// In en, this message translates to:
  /// **'{playlists} playlists ({playlistSongs} songs), {favorites} favorites, {themes} themes, {smart} smart playlists, {edits} edits'**
  String backupSummary(
    Object playlists,
    Object playlistSongs,
    Object favorites,
    Object themes,
    Object smart,
    Object edits,
  );

  /// No description provided for @notAPrismBackupInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Not a Prism backup (invalid JSON)'**
  String get notAPrismBackupInvalidJson;

  /// No description provided for @notAPrismBackup.
  ///
  /// In en, this message translates to:
  /// **'Not a Prism backup'**
  String get notAPrismBackup;

  /// No description provided for @backupIsFromANewerPrism.
  ///
  /// In en, this message translates to:
  /// **'Backup is from a newer Prism version'**
  String get backupIsFromANewerPrism;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'{name} (restored)'**
  String restored(Object name);

  /// No description provided for @writingTagsIsNotSupportedFor.
  ///
  /// In en, this message translates to:
  /// **'Writing tags is not supported for {ext} files'**
  String writingTagsIsNotSupportedFor(Object ext);

  /// No description provided for @couldNotWriteTags.
  ///
  /// In en, this message translates to:
  /// **'Could not write tags: {e}'**
  String couldNotWriteTags(Object e);

  /// No description provided for @tagsDidNotStickFileRestored.
  ///
  /// In en, this message translates to:
  /// **'Tags did not stick (file restored)'**
  String get tagsDidNotStickFileRestored;

  /// No description provided for @duplicateFinder.
  ///
  /// In en, this message translates to:
  /// **'Duplicate finder'**
  String get duplicateFinder;

  /// No description provided for @noDuplicatesFound.
  ///
  /// In en, this message translates to:
  /// **'No duplicates found 🎉'**
  String get noDuplicatesFound;

  /// No description provided for @nGroupsHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} group. Keep the best copy; removing from the library leaves the file on disk.} other{{count} groups. Keep the best copy; removing from the library leaves the file on disk.}}'**
  String nGroupsHint(int count);

  /// No description provided for @theFile.
  ///
  /// In en, this message translates to:
  /// **'the file\n{uri}'**
  String theFile(Object uri);

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get removeFromLibrary;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file…'**
  String get deleteFile;

  /// No description provided for @mb.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB'**
  String mb(Object mb);

  /// No description provided for @chooseCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Choose cover image'**
  String get chooseCoverImage;

  /// No description provided for @tagsSavedABackupOfThe.
  ///
  /// In en, this message translates to:
  /// **'Tags saved (a backup of the original was kept)'**
  String get tagsSavedABackupOfThe;

  /// No description provided for @editTags2.
  ///
  /// In en, this message translates to:
  /// **'Edit tags'**
  String get editTags2;

  /// No description provided for @changeCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover…'**
  String get changeCover;

  /// No description provided for @removeCover.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get removeCover;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @thisFormatOggCanOnlyBe.
  ///
  /// In en, this message translates to:
  /// **'This format (OGG) can only be read, not edited.'**
  String get thisFormatOggCanOnlyBe;

  /// No description provided for @saveToFile.
  ///
  /// In en, this message translates to:
  /// **'Save to file'**
  String get saveToFile;

  /// No description provided for @savePrismBackup.
  ///
  /// In en, this message translates to:
  /// **'Save Prism backup'**
  String get savePrismBackup;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {e}'**
  String backupFailed(Object e);

  /// No description provided for @restorePrismBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Prism backup'**
  String get restorePrismBackup;

  /// No description provided for @restored2.
  ///
  /// In en, this message translates to:
  /// **'Restored: {report}'**
  String restored2(Object report);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {e}'**
  String restoreFailed(Object e);

  /// No description provided for @theVisualizerWorksWithSongsFrom.
  ///
  /// In en, this message translates to:
  /// **'The visualizer works with songs from your library'**
  String get theVisualizerWorksWithSongsFrom;

  /// No description provided for @analysingTheSong.
  ///
  /// In en, this message translates to:
  /// **'Analysing the song'**
  String get analysingTheSong;

  /// No description provided for @couldNotAnalyseThisSong.
  ///
  /// In en, this message translates to:
  /// **'Could not analyse this song'**
  String get couldNotAnalyseThisSong;

  /// No description provided for @theVisualizerNeedsFfmpegWhichIs.
  ///
  /// In en, this message translates to:
  /// **'The visualizer needs FFmpeg, which is missing on this device'**
  String get theVisualizerNeedsFfmpegWhichIs;

  /// No description provided for @bars.
  ///
  /// In en, this message translates to:
  /// **'Bars'**
  String get bars;

  /// No description provided for @mirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get mirror;

  /// No description provided for @radial.
  ///
  /// In en, this message translates to:
  /// **'Radial'**
  String get radial;

  /// No description provided for @wave.
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get wave;

  /// No description provided for @vuMeters.
  ///
  /// In en, this message translates to:
  /// **'VU meters'**
  String get vuMeters;

  /// No description provided for @waterfall.
  ///
  /// In en, this message translates to:
  /// **'Waterfall'**
  String get waterfall;

  /// No description provided for @ledMatrix.
  ///
  /// In en, this message translates to:
  /// **'LED matrix'**
  String get ledMatrix;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @thisDeviceSEqualizerHasBands.
  ///
  /// In en, this message translates to:
  /// **'This device\'s Equalizer has {n} bands ({freqs} Hz, ±{db} dB); the 10-band curve is sampled at those frequencies.Bass boost uses the system BassBoost effect; its exact curve depends on the phone.Some phones (or other EQ apps like Wavelet) can override or block audio effects.'**
  String thisDeviceSEqualizerHasBands(Object n, Object freqs, Object db);

  /// No description provided for @changingEqBandsRebuildsTheLibmpv.
  ///
  /// In en, this message translates to:
  /// **'Changing EQ bands rebuilds the libmpv filter chain; fast slider drags are smoothed, but a very short click is possible.'**
  String get changingEqBandsRebuildsTheLibmpv;

  /// No description provided for @livePitchShiftUsesResamplingTime.
  ///
  /// In en, this message translates to:
  /// **'Live pitch shift uses resampling + time-stretch (WSOLA); exports use rubberband, which sounds a bit cleaner.'**
  String get livePitchShiftUsesResamplingTime;

  /// No description provided for @unknownSong.
  ///
  /// In en, this message translates to:
  /// **'Unknown song'**
  String get unknownSong;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused · {who}'**
  String paused(Object who);

  /// No description provided for @playingInPrism.
  ///
  /// In en, this message translates to:
  /// **'Playing in Prism'**
  String get playingInPrism;

  /// No description provided for @paused2.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused2;

  /// No description provided for @openInAppleMusic.
  ///
  /// In en, this message translates to:
  /// **'Open in Apple Music'**
  String get openInAppleMusic;

  /// No description provided for @openOnDeezer.
  ///
  /// In en, this message translates to:
  /// **'Open on Deezer'**
  String get openOnDeezer;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @couldNotRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read {path}: {e}'**
  String couldNotRead(Object path, Object e);

  /// No description provided for @topLevelMustBeAnObject.
  ///
  /// In en, this message translates to:
  /// **'top level must be an object'**
  String get topLevelMustBeAnObject;

  /// No description provided for @noSongsFoundIn.
  ///
  /// In en, this message translates to:
  /// **'No songs found in {file}.'**
  String noSongsFoundIn(Object file);

  /// No description provided for @theCsvFileHasNoSong.
  ///
  /// In en, this message translates to:
  /// **'The CSV file has no song rows.'**
  String get theCsvFileHasNoSong;

  /// No description provided for @couldNotFindATitleColumn.
  ///
  /// In en, this message translates to:
  /// **'Could not find a title column. Expected a header like \"Track name\" or \"Title\".'**
  String get couldNotFindATitleColumn;

  /// No description provided for @notValidJson.
  ///
  /// In en, this message translates to:
  /// **'Not valid JSON: {e}'**
  String notValidJson(Object e);

  /// No description provided for @unknownJsonLayout.
  ///
  /// In en, this message translates to:
  /// **'Unknown JSON layout.'**
  String get unknownJsonLayout;

  /// No description provided for @couldNotFindASongList.
  ///
  /// In en, this message translates to:
  /// **'Could not find a song list in the JSON (expected \"tracks\", \"items\" or \"playlists\").'**
  String get couldNotFindASongList;

  /// No description provided for @onlineServicesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online services unavailable: {e}'**
  String onlineServicesUnavailable(Object e);

  /// No description provided for @dragOnTheWaveformToSelect.
  ///
  /// In en, this message translates to:
  /// **'Drag on the waveform to select a part first'**
  String get dragOnTheWaveformToSelect;

  /// No description provided for @saveAsNewTrack.
  ///
  /// In en, this message translates to:
  /// **'Save as new track'**
  String get saveAsNewTrack;

  /// No description provided for @exportToFile.
  ///
  /// In en, this message translates to:
  /// **'Export to file'**
  String get exportToFile;

  /// No description provided for @savedAndAddedToYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved and added to your library:\n{path}'**
  String savedAndAddedToYourLibrary(Object path);

  /// No description provided for @exportEdit.
  ///
  /// In en, this message translates to:
  /// **'Export edit'**
  String get exportEdit;

  /// No description provided for @exported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exported;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {e}'**
  String exportFailed(Object e);

  /// No description provided for @editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @readingWaveform.
  ///
  /// In en, this message translates to:
  /// **'Reading waveform…'**
  String get readingWaveform;

  /// No description provided for @undoCtrlZ.
  ///
  /// In en, this message translates to:
  /// **'Undo (Ctrl+Z)'**
  String get undoCtrlZ;

  /// No description provided for @redoCtrlY.
  ///
  /// In en, this message translates to:
  /// **'Redo (Ctrl+Y)'**
  String get redoCtrlY;

  /// No description provided for @saveExport.
  ///
  /// In en, this message translates to:
  /// **'Save / export'**
  String get saveExport;

  /// No description provided for @saveAsNewTrack2.
  ///
  /// In en, this message translates to:
  /// **'Save as new track…'**
  String get saveAsNewTrack2;

  /// No description provided for @exportToFile2.
  ///
  /// In en, this message translates to:
  /// **'Export to file…'**
  String get exportToFile2;

  /// No description provided for @playThisEditInThePlayer.
  ///
  /// In en, this message translates to:
  /// **'Play this edit in the player'**
  String get playThisEditInThePlayer;

  /// No description provided for @livePresetTheOriginalFileIs.
  ///
  /// In en, this message translates to:
  /// **'Live preset – the original file is never changed'**
  String get livePresetTheOriginalFileIs;

  /// No description provided for @editedOriginal.
  ///
  /// In en, this message translates to:
  /// **'Edited {a}  ·  original {b}'**
  String editedOriginal(Object a, Object b);

  /// No description provided for @selection.
  ///
  /// In en, this message translates to:
  /// **'Selection {a} – {b}'**
  String selection(Object a, Object b);

  /// No description provided for @xEdit3.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get xEdit3;

  /// No description provided for @splitAtCursor.
  ///
  /// In en, this message translates to:
  /// **'Split at cursor'**
  String get splitAtCursor;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @trimToSelection.
  ///
  /// In en, this message translates to:
  /// **'Trim to selection'**
  String get trimToSelection;

  /// No description provided for @speed2.
  ///
  /// In en, this message translates to:
  /// **'Speed…'**
  String get speed2;

  /// No description provided for @speedPitchKept.
  ///
  /// In en, this message translates to:
  /// **'Speed (pitch kept)'**
  String get speedPitchKept;

  /// No description provided for @pitch2.
  ///
  /// In en, this message translates to:
  /// **'Pitch…'**
  String get pitch2;

  /// No description provided for @pitchSpeedKept.
  ///
  /// In en, this message translates to:
  /// **'Pitch (speed kept)'**
  String get pitchSpeedKept;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume…'**
  String get volume;

  /// No description provided for @volumeOfSelection.
  ///
  /// In en, this message translates to:
  /// **'Volume of selection'**
  String get volumeOfSelection;

  /// No description provided for @fadeIn.
  ///
  /// In en, this message translates to:
  /// **'Fade in…'**
  String get fadeIn;

  /// No description provided for @fadeIn2.
  ///
  /// In en, this message translates to:
  /// **'Fade in'**
  String get fadeIn2;

  /// No description provided for @fadeOut.
  ///
  /// In en, this message translates to:
  /// **'Fade out…'**
  String get fadeOut;

  /// No description provided for @fadeOut2.
  ///
  /// In en, this message translates to:
  /// **'Fade out'**
  String get fadeOut2;

  /// No description provided for @pausePreview.
  ///
  /// In en, this message translates to:
  /// **'Pause preview'**
  String get pausePreview;

  /// No description provided for @playPreview.
  ///
  /// In en, this message translates to:
  /// **'Play preview'**
  String get playPreview;

  /// No description provided for @aOriginal.
  ///
  /// In en, this message translates to:
  /// **'A  original'**
  String get aOriginal;

  /// No description provided for @bEdited.
  ///
  /// In en, this message translates to:
  /// **'B  edited'**
  String get bEdited;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @dragToSelectTapToMove.
  ///
  /// In en, this message translates to:
  /// **'Drag to select · tap to move the cursor · pinch or Ctrl+wheel to zoom · wheel to scroll · Space = play, Del = cut, Ctrl+Z / Ctrl+Y = undo / redo'**
  String get dragToSelectTapToMove;

  /// No description provided for @keysLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Keys are read only from this local file (never stored in the app or the repo). See README → Online services.'**
  String get keysLocalOnly;

  /// No description provided for @boostMayClip.
  ///
  /// In en, this message translates to:
  /// **'Boost of {db} dB may clip – lower the preamp. '**
  String boostMayClip(Object db);

  /// No description provided for @limiterNote.
  ///
  /// In en, this message translates to:
  /// **'(A limiter catches peaks on Windows.)'**
  String get limiterNote;

  /// No description provided for @editedVsOriginal.
  ///
  /// In en, this message translates to:
  /// **'Edited {a}  ·  original {b}'**
  String editedVsOriginal(Object a, Object b);

  /// No description provided for @oauthConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to {service}'**
  String oauthConnected(Object service);

  /// No description provided for @oauthFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get oauthFailed;

  /// No description provided for @oauthCloseTab.
  ///
  /// In en, this message translates to:
  /// **'You can close this tab and go back to Prism.'**
  String get oauthCloseTab;

  /// No description provided for @oauthWrongState.
  ///
  /// In en, this message translates to:
  /// **'Wrong state'**
  String get oauthWrongState;

  /// No description provided for @decade.
  ///
  /// In en, this message translates to:
  /// **'{year}s'**
  String decade(Object year);

  /// No description provided for @connectedAsWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Connected as {name} ({detail})'**
  String connectedAsWithDetail(Object name, Object detail);

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get langSystem;

  /// No description provided for @langTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get langTitle;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get langRussian;

  /// No description provided for @smartMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get smartMostPlayed;

  /// No description provided for @smartRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get smartRecentlyAdded;

  /// No description provided for @smartForgottenGems.
  ///
  /// In en, this message translates to:
  /// **'Forgotten gems'**
  String get smartForgottenGems;

  /// No description provided for @eqPresetFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get eqPresetFlat;

  /// No description provided for @eqPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get eqPresetCustom;

  /// No description provided for @eqPresetBassBoost.
  ///
  /// In en, this message translates to:
  /// **'Bass Boost'**
  String get eqPresetBassBoost;

  /// No description provided for @eqPresetVocal.
  ///
  /// In en, this message translates to:
  /// **'Vocal'**
  String get eqPresetVocal;

  /// No description provided for @eqPresetTreble.
  ///
  /// In en, this message translates to:
  /// **'Treble'**
  String get eqPresetTreble;

  /// No description provided for @eqPresetRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get eqPresetRock;

  /// No description provided for @eqPresetElectronic.
  ///
  /// In en, this message translates to:
  /// **'Electronic'**
  String get eqPresetElectronic;

  /// No description provided for @eqPresetPop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get eqPresetPop;

  /// No description provided for @eqPresetHipHop.
  ///
  /// In en, this message translates to:
  /// **'Hip-Hop'**
  String get eqPresetHipHop;

  /// No description provided for @eqPresetJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz'**
  String get eqPresetJazz;

  /// No description provided for @eqPresetClassical.
  ///
  /// In en, this message translates to:
  /// **'Classical'**
  String get eqPresetClassical;

  /// No description provided for @eqPresetAcoustic.
  ///
  /// In en, this message translates to:
  /// **'Acoustic'**
  String get eqPresetAcoustic;

  /// No description provided for @eqPresetSpeech.
  ///
  /// In en, this message translates to:
  /// **'Speech'**
  String get eqPresetSpeech;

  /// No description provided for @trayShow.
  ///
  /// In en, this message translates to:
  /// **'Show Prism'**
  String get trayShow;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @hoursValue.
  ///
  /// In en, this message translates to:
  /// **'{h} h'**
  String hoursValue(Object h);

  /// No description provided for @edTabEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edTabEdit;

  /// No description provided for @edTabSegment.
  ///
  /// In en, this message translates to:
  /// **'Segment'**
  String get edTabSegment;

  /// No description provided for @edTabQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get edTabQuick;

  /// No description provided for @edExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get edExport;

  /// No description provided for @edRippleDelete.
  ///
  /// In en, this message translates to:
  /// **'Ripple delete'**
  String get edRippleDelete;

  /// No description provided for @edDeleteGap.
  ///
  /// In en, this message translates to:
  /// **'Delete, leave a gap'**
  String get edDeleteGap;

  /// No description provided for @edDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get edDuplicate;

  /// No description provided for @edLoopN.
  ///
  /// In en, this message translates to:
  /// **'Loop…'**
  String get edLoopN;

  /// No description provided for @edLoopTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat the selection'**
  String get edLoopTitle;

  /// No description provided for @edReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get edReverse;

  /// No description provided for @edMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge songs…'**
  String get edMerge;

  /// No description provided for @edMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to the end'**
  String get edMergeTitle;

  /// No description provided for @edAddN.
  ///
  /// In en, this message translates to:
  /// **'Add {n}'**
  String edAddN(Object n);

  /// No description provided for @edAutoTrim.
  ///
  /// In en, this message translates to:
  /// **'Auto-trim silence'**
  String get edAutoTrim;

  /// No description provided for @edRemoveSilence.
  ///
  /// In en, this message translates to:
  /// **'Remove silence inside'**
  String get edRemoveSilence;

  /// No description provided for @edNormalize.
  ///
  /// In en, this message translates to:
  /// **'Normalize peaks'**
  String get edNormalize;

  /// No description provided for @edLoudness.
  ///
  /// In en, this message translates to:
  /// **'Match loudness…'**
  String get edLoudness;

  /// No description provided for @edLoudnessTitle.
  ///
  /// In en, this message translates to:
  /// **'Loudness target'**
  String get edLoudnessTitle;

  /// No description provided for @edNothingToDo.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do here'**
  String get edNothingToDo;

  /// No description provided for @edRingtone.
  ///
  /// In en, this message translates to:
  /// **'Save as ringtone'**
  String get edRingtone;

  /// No description provided for @edRingtoneSet.
  ///
  /// In en, this message translates to:
  /// **'Set as ringtone'**
  String get edRingtoneSet;

  /// No description provided for @edRingtoneDone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone set'**
  String get edRingtoneDone;

  /// No description provided for @edRingtoneAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Prism to change system settings, then tap again'**
  String get edRingtoneAllow;

  /// No description provided for @edRingtoneSave.
  ///
  /// In en, this message translates to:
  /// **'Save ringtone'**
  String get edRingtoneSave;

  /// No description provided for @edMakingRingtone.
  ///
  /// In en, this message translates to:
  /// **'Making the ringtone…'**
  String get edMakingRingtone;

  /// No description provided for @edRenderingPreset.
  ///
  /// In en, this message translates to:
  /// **'Rendering the live preset…'**
  String get edRenderingPreset;

  /// No description provided for @edRenderingPreview.
  ///
  /// In en, this message translates to:
  /// **'Rendering preview…'**
  String get edRenderingPreview;

  /// No description provided for @edLoopSel.
  ///
  /// In en, this message translates to:
  /// **'Loop selection (L)'**
  String get edLoopSel;

  /// No description provided for @edFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow the playhead'**
  String get edFollow;

  /// No description provided for @edSnapZero.
  ///
  /// In en, this message translates to:
  /// **'Snap to zero crossings'**
  String get edSnapZero;

  /// No description provided for @edSnapBeats.
  ///
  /// In en, this message translates to:
  /// **'Snap to beats'**
  String get edSnapBeats;

  /// No description provided for @edSnapSilence.
  ///
  /// In en, this message translates to:
  /// **'Snap to silence'**
  String get edSnapSilence;

  /// No description provided for @edZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in (+)'**
  String get edZoomIn;

  /// No description provided for @edZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out (-)'**
  String get edZoomOut;

  /// No description provided for @edSegmentN.
  ///
  /// In en, this message translates to:
  /// **'Segment {n} of {total}'**
  String edSegmentN(Object n, Object total);

  /// No description provided for @edRamp.
  ///
  /// In en, this message translates to:
  /// **'Gradual speed change'**
  String get edRamp;

  /// No description provided for @edRampTo.
  ///
  /// In en, this message translates to:
  /// **'Speed at the end'**
  String get edRampTo;

  /// No description provided for @edVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get edVolume;

  /// No description provided for @edCrossfadeNext.
  ///
  /// In en, this message translates to:
  /// **'Crossfade into the next'**
  String get edCrossfadeNext;

  /// No description provided for @edCurve.
  ///
  /// In en, this message translates to:
  /// **'Fade curve'**
  String get edCurve;

  /// No description provided for @edCurveLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get edCurveLinear;

  /// No description provided for @edCurveSmooth.
  ///
  /// In en, this message translates to:
  /// **'Smooth'**
  String get edCurveSmooth;

  /// No description provided for @edCurveS.
  ///
  /// In en, this message translates to:
  /// **'S-curve'**
  String get edCurveS;

  /// No description provided for @edCurveFast.
  ///
  /// In en, this message translates to:
  /// **'Fast start'**
  String get edCurveFast;

  /// No description provided for @edCurveSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow start'**
  String get edCurveSlow;

  /// No description provided for @edEq.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get edEq;

  /// No description provided for @edMid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get edMid;

  /// No description provided for @edHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get edHigh;

  /// No description provided for @edGate.
  ///
  /// In en, this message translates to:
  /// **'Noise gate'**
  String get edGate;

  /// No description provided for @edGateHint.
  ///
  /// In en, this message translates to:
  /// **'Mutes everything quieter than the level'**
  String get edGateHint;

  /// No description provided for @edGateLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get edGateLevel;

  /// No description provided for @edVbr.
  ///
  /// In en, this message translates to:
  /// **'Variable bitrate (VBR)'**
  String get edVbr;

  /// No description provided for @edVbrQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality {q} (0 is best, 9 is smallest)'**
  String edVbrQuality(Object q);

  /// No description provided for @edBitrate.
  ///
  /// In en, this message translates to:
  /// **'{kbps} kbps'**
  String edBitrate(Object kbps);

  /// No description provided for @edWavBits.
  ///
  /// In en, this message translates to:
  /// **'{bits}-bit'**
  String edWavBits(Object bits);

  /// No description provided for @edFlacLevel.
  ///
  /// In en, this message translates to:
  /// **'Compression {n}'**
  String edFlacLevel(Object n);

  /// No description provided for @edApplyEq.
  ///
  /// In en, this message translates to:
  /// **'Apply the global equalizer'**
  String get edApplyEq;

  /// No description provided for @edKeepTags.
  ///
  /// In en, this message translates to:
  /// **'Keep tags and cover'**
  String get edKeepTags;

  /// No description provided for @edKeepCover.
  ///
  /// In en, this message translates to:
  /// **'Keep cover'**
  String get edKeepCover;

  /// No description provided for @edOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite the original (a backup is kept)'**
  String get edOverwrite;

  /// No description provided for @edOverwriteDone.
  ///
  /// In en, this message translates to:
  /// **'Original replaced. Backup: {path}'**
  String edOverwriteDone(Object path);

  /// No description provided for @edOverwriteUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Can\'t overwrite {ext} files, save as a new track instead'**
  String edOverwriteUnsupported(Object ext);

  /// No description provided for @edOverwriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not replace the file, the original was put back: {e}'**
  String edOverwriteFailed(Object e);

  /// No description provided for @edHelpDesktop.
  ///
  /// In en, this message translates to:
  /// **'Drag to select, drag an edge to adjust, click to move the cursor, double-click selects a segment. Wheel scrolls, Ctrl+wheel zooms. Space play, S split, Del ripple delete, Shift+Del delete with gap, T trim, R reverse, L loop, B A/B, Ctrl+D duplicate, Ctrl+A select all, Ctrl+E export, Ctrl+Z / Ctrl+Y undo / redo, arrows move the cursor, + - 0 zoom.'**
  String get edHelpDesktop;

  /// No description provided for @edHelpTouch.
  ///
  /// In en, this message translates to:
  /// **'Drag to select, drag an edge to adjust, tap to move the cursor, double-tap selects a segment. Pinch to zoom, two fingers to scroll. Hold a block in the row below the waveform to move it.'**
  String get edHelpTouch;

  /// No description provided for @lyricsError.
  ///
  /// In en, this message translates to:
  /// **'Lyrics error: {e}'**
  String lyricsError(Object e);

  /// No description provided for @lyricsOffsetTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics timing'**
  String get lyricsOffsetTitle;

  /// No description provided for @lyricsOffsetHint.
  ///
  /// In en, this message translates to:
  /// **'Plus shows the lines earlier, minus later. Saved for this song.'**
  String get lyricsOffsetHint;

  /// No description provided for @vizRibbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get vizRibbon;

  /// No description provided for @vizParticles.
  ///
  /// In en, this message translates to:
  /// **'Particles'**
  String get vizParticles;

  /// No description provided for @vizGlow.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get vizGlow;

  /// No description provided for @vizSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity'**
  String get vizSensitivity;

  /// No description provided for @vizLowPower.
  ///
  /// In en, this message translates to:
  /// **'Low-power visualizer'**
  String get vizLowPower;

  /// No description provided for @vizLowPowerHint.
  ///
  /// In en, this message translates to:
  /// **'30 frames per second and fewer details'**
  String get vizLowPowerHint;

  /// No description provided for @vizLive.
  ///
  /// In en, this message translates to:
  /// **'Live spectrum'**
  String get vizLive;

  /// No description provided for @vizLiveHint.
  ///
  /// In en, this message translates to:
  /// **'Reacts to what is actually playing, also streams and EQ. Android asks for the microphone permission for this; Prism records nothing.'**
  String get vizLiveHint;

  /// No description provided for @vizLiveRefused.
  ///
  /// In en, this message translates to:
  /// **'Permission refused, the visualizer keeps analysing the file'**
  String get vizLiveRefused;

  /// No description provided for @metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Fix song info'**
  String get metaTitle;

  /// No description provided for @metaFix.
  ///
  /// In en, this message translates to:
  /// **'Fix info…'**
  String get metaFix;

  /// No description provided for @metaFixAlbum.
  ///
  /// In en, this message translates to:
  /// **'Fix info of all these songs'**
  String get metaFixAlbum;

  /// No description provided for @metaSearchAll.
  ///
  /// In en, this message translates to:
  /// **'Search all'**
  String get metaSearchAll;

  /// No description provided for @metaSaveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get metaSaveAll;

  /// No description provided for @metaSave.
  ///
  /// In en, this message translates to:
  /// **'Save to file'**
  String get metaSave;

  /// No description provided for @metaResearch.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get metaResearch;

  /// No description provided for @metaNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Try other words above, or type the info by hand.'**
  String get metaNothingFound;

  /// No description provided for @metaCandidates.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get metaCandidates;

  /// No description provided for @metaUseCover.
  ///
  /// In en, this message translates to:
  /// **'Use this cover'**
  String get metaUseCover;

  /// No description provided for @metaSavedN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Saved {count} song, a backup of the original was kept} other{Saved {count} songs, backups of the originals were kept}}'**
  String metaSavedN(int count);

  /// No description provided for @metaSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {e}'**
  String metaSaveFailed(Object e);

  /// No description provided for @yandexChanged.
  ///
  /// In en, this message translates to:
  /// **'Yandex Music answered in an unexpected way. It has no official API, so this can break at any time. Export the playlist to CSV or JSON and import the file instead.'**
  String get yandexChanged;

  /// No description provided for @yandexNeedsToken.
  ///
  /// In en, this message translates to:
  /// **'Yandex Music needs your token for this: Settings → Online services.'**
  String get yandexNeedsToken;

  /// No description provided for @yandexPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Yandex Music playlist'**
  String get yandexPlaylist;

  /// No description provided for @yandexLikes.
  ///
  /// In en, this message translates to:
  /// **'Liked songs (Yandex Music)'**
  String get yandexLikes;

  /// No description provided for @yandexLabel.
  ///
  /// In en, this message translates to:
  /// **'Yandex Music'**
  String get yandexLabel;

  /// No description provided for @yandexDescribe.
  ///
  /// In en, this message translates to:
  /// **'Experimental, no official API. Public links, your playlists and likes with your token. Song names only, no audio.'**
  String get yandexDescribe;

  /// No description provided for @yandexTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Yandex Music token'**
  String get yandexTokenTitle;

  /// No description provided for @yandexTokenSteps.
  ///
  /// In en, this message translates to:
  /// **'Only needed for your own playlists and likes; public links work without it.\n\n1. Open the guide below.\n2. Follow its browser steps while signed in to your Yandex account.\n3. Copy the token and paste it here.'**
  String get yandexTokenSteps;

  /// No description provided for @yandexOpenGuide.
  ///
  /// In en, this message translates to:
  /// **'Open the guide (community project)'**
  String get yandexOpenGuide;

  /// No description provided for @yandexToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get yandexToken;

  /// No description provided for @yandexTokenPrivate.
  ///
  /// In en, this message translates to:
  /// **'The token gives access to your Yandex account: don\'t share it. Prism keeps it in the system\'s secure storage and sends it only to api.music.yandex.net.'**
  String get yandexTokenPrivate;

  /// No description provided for @yandexTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Yandex Music – unofficial, import only'**
  String get yandexTermsTitle;

  /// No description provided for @yandexTermsText.
  ///
  /// In en, this message translates to:
  /// **'Yandex has no public API. Prism reads song names through the private one its apps use (documented by the community project yandex-music-api), which can change or stop without warning and answers only from some countries. Public links are read when you import them; your account stays off until you turn it on. For personal use. Prism never downloads or plays Yandex audio. If it stops working, import a CSV or JSON export instead.'**
  String get yandexTermsText;

  /// No description provided for @regionBlocked.
  ///
  /// In en, this message translates to:
  /// **'{service} isn\'t available from your country or network (blocked by the service). Export the playlist to CSV or JSON and import the file instead.'**
  String regionBlocked(Object service);

  /// No description provided for @setUpYandexToken.
  ///
  /// In en, this message translates to:
  /// **'Paste token'**
  String get setUpYandexToken;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this playlist'**
  String get shareTitle;

  /// No description provided for @shareHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Send this code to a friend. It holds the name of {count} song, no audio and no file paths; Prism finds it in their library or enabled services.} other{Send this code to a friend. It holds the names of {count} songs, no audio and no file paths; Prism finds them in their library or enabled services.}}'**
  String shareHint(int count);

  /// No description provided for @shareLong.
  ///
  /// In en, this message translates to:
  /// **'This code is long and some chat apps may cut it. If so, send the file instead.'**
  String get shareLong;

  /// No description provided for @shareSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Save .liner file'**
  String get shareSaveFile;

  /// No description provided for @shareSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get shareSaved;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @shareBadCode.
  ///
  /// In en, this message translates to:
  /// **'This code is damaged or incomplete. Ask for it again, or for the .liner file.'**
  String get shareBadCode;

  /// No description provided for @shareNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This code was made by a newer Prism. Update the app to open it.'**
  String get shareNewerVersion;

  /// No description provided for @shareTooBig.
  ///
  /// In en, this message translates to:
  /// **'This playlist is too big to open.'**
  String get shareTooBig;

  /// No description provided for @shareEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no songs in this code.'**
  String get shareEmpty;

  /// No description provided for @shareDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Shared playlist'**
  String get shareDefaultName;

  /// No description provided for @shareRecognized.
  ///
  /// In en, this message translates to:
  /// **'A shared playlist'**
  String get shareRecognized;

  /// No description provided for @orderSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} selected} other{{count} selected}}'**
  String orderSelected(int count);

  /// No description provided for @orderMoveTop.
  ///
  /// In en, this message translates to:
  /// **'Move to top'**
  String get orderMoveTop;

  /// No description provided for @orderMoveBottom.
  ///
  /// In en, this message translates to:
  /// **'Move to bottom'**
  String get orderMoveBottom;

  /// No description provided for @orderSelect.
  ///
  /// In en, this message translates to:
  /// **'Select several'**
  String get orderSelect;

  /// No description provided for @orderSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get orderSort;

  /// No description provided for @orderCustom.
  ///
  /// In en, this message translates to:
  /// **'My order'**
  String get orderCustom;

  /// No description provided for @orderSortedHint.
  ///
  /// In en, this message translates to:
  /// **'Sorted by: {by}. Your own order is kept.'**
  String orderSortedHint(Object by);

  /// No description provided for @orderBackToCustom.
  ///
  /// In en, this message translates to:
  /// **'Back to my order'**
  String get orderBackToCustom;

  /// No description provided for @orderKeepThis.
  ///
  /// In en, this message translates to:
  /// **'Make this my order'**
  String get orderKeepThis;

  /// No description provided for @statsNewVsRepeat.
  ///
  /// In en, this message translates to:
  /// **'New and repeat'**
  String get statsNewVsRepeat;

  /// No description provided for @statsNewVsRepeatNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song heard for the first time} other{{count} songs heard for the first time}}'**
  String statsNewVsRepeatNote(int count);

  /// No description provided for @statsNewPlays.
  ///
  /// In en, this message translates to:
  /// **'Discoveries'**
  String get statsNewPlays;

  /// No description provided for @statsRepeatPlays.
  ///
  /// In en, this message translates to:
  /// **'Songs you knew'**
  String get statsRepeatPlays;

  /// No description provided for @statsStoryPlay.
  ///
  /// In en, this message translates to:
  /// **'Play as a story'**
  String get statsStoryPlay;

  /// No description provided for @statsSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save this card as a picture'**
  String get statsSaveImage;

  /// No description provided for @statsImageSaved.
  ///
  /// In en, this message translates to:
  /// **'Picture saved'**
  String get statsImageSaved;

  /// No description provided for @statsMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{minute} other{minutes}}'**
  String statsMinutesUnit(int count);

  /// No description provided for @statsDaysInARow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{day in a row} other{days in a row}}'**
  String statsDaysInARow(int count);

  /// No description provided for @statsWrappedNew.
  ///
  /// In en, this message translates to:
  /// **'You discovered'**
  String get statsWrappedNew;

  /// No description provided for @statsNewSongsUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{new song} other{new songs}}'**
  String statsNewSongsUnit(int count);

  /// No description provided for @bgMesh.
  ///
  /// In en, this message translates to:
  /// **'Mesh gradient'**
  String get bgMesh;

  /// No description provided for @bgMeshDesc.
  ///
  /// In en, this message translates to:
  /// **'Soft colors slowly flowing into each other.'**
  String get bgMeshDesc;

  /// No description provided for @bgAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get bgAurora;

  /// No description provided for @bgAuroraDesc.
  ///
  /// In en, this message translates to:
  /// **'Curtains of light moving across a dark sky.'**
  String get bgAuroraDesc;

  /// No description provided for @bgBlobs.
  ///
  /// In en, this message translates to:
  /// **'Liquid blobs'**
  String get bgBlobs;

  /// No description provided for @bgBlobsDesc.
  ///
  /// In en, this message translates to:
  /// **'Shapes that merge and split like a lava lamp, swelling with the bass.'**
  String get bgBlobsDesc;

  /// No description provided for @bgGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get bgGradient;

  /// No description provided for @bgGradientDesc.
  ///
  /// In en, this message translates to:
  /// **'A still gradient. Pick a preset below. Uses no power once drawn.'**
  String get bgGradientDesc;

  /// No description provided for @bgStarfield.
  ///
  /// In en, this message translates to:
  /// **'Starfield'**
  String get bgStarfield;

  /// No description provided for @bgStarfieldDesc.
  ///
  /// In en, this message translates to:
  /// **'Flying through the stars, faster on the bass.'**
  String get bgStarfieldDesc;

  /// No description provided for @bgRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get bgRain;

  /// No description provided for @bgRainDesc.
  ///
  /// In en, this message translates to:
  /// **'Thin falling rain. The mouse is the wind.'**
  String get bgRainDesc;

  /// No description provided for @bgSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get bgSnow;

  /// No description provided for @bgSnowDesc.
  ///
  /// In en, this message translates to:
  /// **'Flakes drifting down in layers.'**
  String get bgSnowDesc;

  /// No description provided for @bgGrain.
  ///
  /// In en, this message translates to:
  /// **'Film grain'**
  String get bgGrain;

  /// No description provided for @bgGrainDesc.
  ///
  /// In en, this message translates to:
  /// **'A quiet tinted gradient with moving film grain.'**
  String get bgGrainDesc;

  /// No description provided for @bgImage.
  ///
  /// In en, this message translates to:
  /// **'My picture'**
  String get bgImage;

  /// No description provided for @bgImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Your own picture behind the app. Blur and darken it below.'**
  String get bgImageDesc;

  /// No description provided for @bgVideo.
  ///
  /// In en, this message translates to:
  /// **'My video'**
  String get bgVideo;

  /// No description provided for @bgVideoDesc.
  ///
  /// In en, this message translates to:
  /// **'The first 30 seconds of your video as a silent loop at 12 frames per second.'**
  String get bgVideoDesc;

  /// No description provided for @bgChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose a picture…'**
  String get bgChooseImage;

  /// No description provided for @bgChooseVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose a video…'**
  String get bgChooseVideo;

  /// No description provided for @bgPreparingVideo.
  ///
  /// In en, this message translates to:
  /// **'Preparing the video…'**
  String get bgPreparingVideo;

  /// No description provided for @bgVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read this video on this device.'**
  String get bgVideoFailed;

  /// No description provided for @bgPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get bgPresets;

  /// No description provided for @bgDim.
  ///
  /// In en, this message translates to:
  /// **'Darken'**
  String get bgDim;

  /// No description provided for @bgParallax.
  ///
  /// In en, this message translates to:
  /// **'Parallax'**
  String get bgParallax;

  /// No description provided for @bgParallaxHint.
  ///
  /// In en, this message translates to:
  /// **'The background shifts a little with the mouse'**
  String get bgParallaxHint;

  /// No description provided for @bgBatterySaver.
  ///
  /// In en, this message translates to:
  /// **'Battery saver'**
  String get bgBatterySaver;

  /// No description provided for @bgBatterySaverHint.
  ///
  /// In en, this message translates to:
  /// **'20 frames per second, fewer details, no blur or frosted panels'**
  String get bgBatterySaverHint;

  /// No description provided for @bgPresetDusk.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get bgPresetDusk;

  /// No description provided for @bgPresetOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get bgPresetOcean;

  /// No description provided for @bgPresetForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get bgPresetForest;

  /// No description provided for @bgPresetEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get bgPresetEmber;

  /// No description provided for @bgPresetIce.
  ///
  /// In en, this message translates to:
  /// **'Ice'**
  String get bgPresetIce;

  /// No description provided for @bgPresetGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get bgPresetGraphite;

  /// No description provided for @bgPresetRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get bgPresetRose;

  /// No description provided for @bgPresetNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get bgPresetNight;

  /// No description provided for @bgDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get bgDensity;

  /// No description provided for @bgSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get bgSize;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheck;

  /// No description provided for @updateAuto.
  ///
  /// In en, this message translates to:
  /// **'Check when the app starts'**
  String get updateAuto;

  /// No description provided for @updateAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Asks GitHub once a day for the latest version'**
  String get updateAutoHint;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateNone.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version ({version})'**
  String updateNone(Object version);

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates: {reason}'**
  String updateFailed(Object reason);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is out'**
  String updateAvailable(Object version);

  /// No description provided for @updateHowTo.
  ///
  /// In en, this message translates to:
  /// **'Download the new installer or APK and install it over this one. Your library and settings stay.'**
  String get updateHowTo;

  /// No description provided for @updateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open download page'**
  String get updateOpen;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyNoLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Prism does not read your location'**
  String get privacyNoLocationTitle;

  /// No description provided for @privacyNoLocationText.
  ///
  /// In en, this message translates to:
  /// **'No analytics, no telemetry, no ads, no crash reports. No device id. Prism has no account or server of its own.'**
  String get privacyNoLocationText;

  /// No description provided for @privacyPermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Android permissions'**
  String get privacyPermsTitle;

  /// No description provided for @privacyPermMusic.
  ///
  /// In en, this message translates to:
  /// **'Music and audio files'**
  String get privacyPermMusic;

  /// No description provided for @privacyPermMusicWhy.
  ///
  /// In en, this message translates to:
  /// **'Reads your music. Asked when you add a folder.'**
  String get privacyPermMusicWhy;

  /// No description provided for @privacyPermPlayback.
  ///
  /// In en, this message translates to:
  /// **'Background playback'**
  String get privacyPermPlayback;

  /// No description provided for @privacyPermPlaybackWhy.
  ///
  /// In en, this message translates to:
  /// **'Keeps music playing with the screen off.'**
  String get privacyPermPlaybackWhy;

  /// No description provided for @privacyPermNotify.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get privacyPermNotify;

  /// No description provided for @privacyPermNotifyWhy.
  ///
  /// In en, this message translates to:
  /// **'Only the player notification with its buttons.'**
  String get privacyPermNotifyWhy;

  /// No description provided for @privacyPermInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet and network state'**
  String get privacyPermInternet;

  /// No description provided for @privacyPermInternetWhy.
  ///
  /// In en, this message translates to:
  /// **'For the requests listed below, and to know whether you are online.'**
  String get privacyPermInternetWhy;

  /// No description provided for @privacyPermMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone (live visualizer only)'**
  String get privacyPermMic;

  /// No description provided for @privacyPermMicWhy.
  ///
  /// In en, this message translates to:
  /// **'Android files its visualizer under the microphone. Asked only when you turn it on. Prism records nothing.'**
  String get privacyPermMicWhy;

  /// No description provided for @privacyPermRingtone.
  ///
  /// In en, this message translates to:
  /// **'Change system settings (ringtones only)'**
  String get privacyPermRingtone;

  /// No description provided for @privacyPermRingtoneWhy.
  ///
  /// In en, this message translates to:
  /// **'Sets a ringtone made in the editor. You allow it on a system screen when you use it.'**
  String get privacyPermRingtoneWhy;

  /// No description provided for @privacyPermsFooter.
  ///
  /// In en, this message translates to:
  /// **'Never asked for: location, Bluetooth, Wi-Fi details, phone state, contacts, accounts, advertising id.'**
  String get privacyPermsFooter;

  /// No description provided for @privacyWindowsTitle.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get privacyWindowsTitle;

  /// No description provided for @privacyWindowsText.
  ///
  /// In en, this message translates to:
  /// **'Needs no special permissions and does not use the Windows location API. Before version 1.2 a library started the Windows location service at launch, so Windows could list Prism as using location. Prism never read or sent the result, and that library is gone.'**
  String get privacyWindowsText;

  /// No description provided for @privacySentTitle.
  ///
  /// In en, this message translates to:
  /// **'What leaves this device'**
  String get privacySentTitle;

  /// No description provided for @privacySentFooter.
  ///
  /// In en, this message translates to:
  /// **'Every server sees your IP address, like with any internet request. Prism never looks up where that address is.'**
  String get privacySentFooter;

  /// No description provided for @privacySentUpdates.
  ///
  /// In en, this message translates to:
  /// **'Update check: GitHub'**
  String get privacySentUpdates;

  /// No description provided for @privacySentUpdatesWhat.
  ///
  /// In en, this message translates to:
  /// **'Sends the app version. Automatic, can be turned off in About.'**
  String get privacySentUpdatesWhat;

  /// No description provided for @privacySentInfo.
  ///
  /// In en, this message translates to:
  /// **'Missing info: Apple, Deezer'**
  String get privacySentInfo;

  /// No description provided for @privacySentInfoWhat.
  ///
  /// In en, this message translates to:
  /// **'Sends song title and artist. Automatic, can be turned off in Library.'**
  String get privacySentInfoWhat;

  /// No description provided for @privacySentLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics: LRCLIB'**
  String get privacySentLyrics;

  /// No description provided for @privacySentLyricsWhat.
  ///
  /// In en, this message translates to:
  /// **'Sends title, artist, album and length of the song you open lyrics for.'**
  String get privacySentLyricsWhat;

  /// No description provided for @privacySentFonts.
  ///
  /// In en, this message translates to:
  /// **'Font: Google Fonts'**
  String get privacySentFonts;

  /// No description provided for @privacySentFontsWhat.
  ///
  /// In en, this message translates to:
  /// **'Downloads the app font once. Sends nothing about you or your music.'**
  String get privacySentFontsWhat;

  /// No description provided for @privacySentImport.
  ///
  /// In en, this message translates to:
  /// **'Import: Spotify, YouTube, SoundCloud, Deezer, Apple Music, Yandex Music'**
  String get privacySentImport;

  /// No description provided for @privacySentImportWhat.
  ///
  /// In en, this message translates to:
  /// **'Only when you import: the link you gave. A copied link stays on this device until you tap Import.'**
  String get privacySentImportWhat;

  /// No description provided for @privacySentOnline.
  ///
  /// In en, this message translates to:
  /// **'Online songs: YouTube, SoundCloud'**
  String get privacySentOnline;

  /// No description provided for @privacySentOnlineWhat.
  ///
  /// In en, this message translates to:
  /// **'If you turn them on: song searches and the songs you play.'**
  String get privacySentOnlineWhat;

  /// No description provided for @privacySentFixer.
  ///
  /// In en, this message translates to:
  /// **'Song info fixer: MusicBrainz, Cover Art Archive, Apple, AcoustID'**
  String get privacySentFixer;

  /// No description provided for @privacySentFixerWhat.
  ///
  /// In en, this message translates to:
  /// **'When you use it: title, artist, album. AcoustID only with your own key.'**
  String get privacySentFixerWhat;

  /// No description provided for @privacySentTogether.
  ///
  /// In en, this message translates to:
  /// **'Listen together: public servers or your Wi-Fi'**
  String get privacySentTogether;

  /// No description provided for @privacySentTogetherWhat.
  ///
  /// In en, this message translates to:
  /// **'While in a session: what is playing and the name you typed. Without a name you appear as “Someone”, never your computer name.'**
  String get privacySentTogetherWhat;

  /// No description provided for @privacySentDiscord.
  ///
  /// In en, this message translates to:
  /// **'Discord status'**
  String get privacySentDiscord;

  /// No description provided for @privacySentDiscordWhat.
  ///
  /// In en, this message translates to:
  /// **'If Discord runs on this computer: the song you play.'**
  String get privacySentDiscordWhat;

  /// No description provided for @privacyFullText.
  ///
  /// In en, this message translates to:
  /// **'Read the full privacy notes'**
  String get privacyFullText;

  /// No description provided for @privacyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get privacyContinue;

  /// No description provided for @vizLiveAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Android will ask about the microphone'**
  String get vizLiveAskTitle;

  /// No description provided for @vizLiveAskText.
  ///
  /// In en, this message translates to:
  /// **'The live visualizer uses the Visualizer API, which Android files under the microphone. Prism only reads the sound it plays itself. It records nothing and sends nothing.'**
  String get vizLiveAskText;

  /// No description provided for @removeFromPrism.
  ///
  /// In en, this message translates to:
  /// **'Remove from Prism'**
  String get removeFromPrism;

  /// No description provided for @removeFromPrismHint.
  ///
  /// In en, this message translates to:
  /// **'The file stays on your disk'**
  String get removeFromPrismHint;

  /// No description provided for @removeFromPrismAsk.
  ///
  /// In en, this message translates to:
  /// **'Remove “{title}” from Prism?'**
  String removeFromPrismAsk(String title);

  /// No description provided for @removeFromPrismText.
  ///
  /// In en, this message translates to:
  /// **'It leaves your library, playlists, favorites and stats in Prism. The file stays on your disk and rescans skip it. You can bring it back in Settings → Library.'**
  String get removeFromPrismText;

  /// No description provided for @removeFromPrismDone.
  ///
  /// In en, this message translates to:
  /// **'Removed from Prism. The file is still on your disk.'**
  String get removeFromPrismDone;

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @removedSongs.
  ///
  /// In en, this message translates to:
  /// **'Removed songs'**
  String get removedSongs;

  /// No description provided for @removedSongsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing removed} one{{count} song hidden from Prism} other{{count} songs hidden from Prism}}'**
  String removedSongsCount(int count);

  /// No description provided for @removedSongsHelp.
  ///
  /// In en, this message translates to:
  /// **'Their files are still on your disk. Restore puts a song back in your library with a scan, which starts right away. Old stats and playlist places do not come back.'**
  String get removedSongsHelp;

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @importSupported.
  ///
  /// In en, this message translates to:
  /// **'Spotify, YouTube, SoundCloud, Yandex Music, Apple Music or Deezer. Public links work with no account.'**
  String get importSupported;

  /// No description provided for @importFileOrDrop.
  ///
  /// In en, this message translates to:
  /// **'Or drop a file here: CSV, JSON, M3U, .liner'**
  String get importFileOrDrop;

  /// No description provided for @importFileHint.
  ///
  /// In en, this message translates to:
  /// **'Or pick a file: CSV, JSON, M3U, .liner'**
  String get importFileHint;

  /// No description provided for @importDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop to import'**
  String get importDropHere;

  /// No description provided for @importClipboardAsk.
  ///
  /// In en, this message translates to:
  /// **'Import this playlist?'**
  String get importClipboardAsk;

  /// No description provided for @importRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent imports'**
  String get importRecent;

  /// No description provided for @importResync.
  ///
  /// In en, this message translates to:
  /// **'Sync again'**
  String get importResync;

  /// No description provided for @importSynced.
  ///
  /// In en, this message translates to:
  /// **'Syncing with the source'**
  String get importSynced;

  /// No description provided for @importAccept.
  ///
  /// In en, this message translates to:
  /// **'Right song'**
  String get importAccept;

  /// No description provided for @importAcceptAll.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Accept {count}} other{Accept all {count}}}'**
  String importAcceptAll(int count);

  /// No description provided for @importReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get importReview;

  /// No description provided for @importReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to check. Songs Prism is unsure about will wait here.'**
  String get importReviewEmpty;

  /// No description provided for @importReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} song to check} other{{count} songs to check}}'**
  String importReviewCount(int count);

  /// No description provided for @importReviewHint.
  ///
  /// In en, this message translates to:
  /// **'One tap to accept or fix'**
  String get importReviewHint;

  /// No description provided for @importAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced: connect an account'**
  String get importAdvanced;

  /// No description provided for @importAdvancedHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Only for private playlists, liked songs and long Spotify lists.'**
  String get importAdvancedHint;

  /// No description provided for @importNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get importNotConnected;

  /// No description provided for @importOneScreenHint.
  ///
  /// In en, this message translates to:
  /// **'From a link or a file, on one screen'**
  String get importOneScreenHint;

  /// No description provided for @importOnlyLibrarySearched.
  ///
  /// In en, this message translates to:
  /// **'Only your library was searched. Prism can look for the rest on YouTube if you turn it on.'**
  String get importOnlyLibrarySearched;

  /// No description provided for @importFindOnYoutube.
  ///
  /// In en, this message translates to:
  /// **'Find the rest on YouTube'**
  String get importFindOnYoutube;

  /// No description provided for @importSearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again for songs not found'**
  String get importSearchAgain;

  /// No description provided for @importStepsSpotify.
  ///
  /// In en, this message translates to:
  /// **'For your private playlists and liked songs. Public links already work.\n1. Open developer.spotify.com/dashboard and create an app with the Web API.\n2. Add the redirect URI http://127.0.0.1:43821/callback.\n3. Copy the Client ID.\n4. In Online services tap Create file, paste it as spotify.clientId, tap Reload, then Connect.'**
  String get importStepsSpotify;

  /// No description provided for @importStepsYoutube.
  ///
  /// In en, this message translates to:
  /// **'For your private playlists and liked videos. Public links already work.\n1. Open console.cloud.google.com and make a project with the YouTube Data API v3.\n2. Add yourself as a test user on the OAuth consent screen.\n3. Create an OAuth client of type Desktop app.\n4. In Online services tap Create file, paste youtube.oauthClientId and youtube.oauthClientSecret, tap Reload, then Connect.'**
  String get importStepsYoutube;

  /// No description provided for @importStepsSoundcloud.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud links need this, or export the playlist to a file.\n1. Open soundcloud.com/you/apps and register an app. SoundCloud may need to approve it.\n2. Add the redirect URI http://127.0.0.1:43822/callback.\n3. In Online services tap Create file, paste soundcloud.clientId and soundcloud.clientSecret, tap Reload.'**
  String get importStepsSoundcloud;

  /// No description provided for @importStepsYandex.
  ///
  /// In en, this message translates to:
  /// **'For your own playlists and liked songs. Public links already work where Yandex answers.\n1. Open Online services and turn on Yandex Music.\n2. Tap Connect and follow the steps to get your token.\n3. Paste the token. It stays in the secure storage of this device.'**
  String get importStepsYandex;

  /// No description provided for @importErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'You seem to be offline. Check your connection and try again.'**
  String get importErrorOffline;

  /// No description provided for @importErrorSlowDown.
  ///
  /// In en, this message translates to:
  /// **'{service} is asking to slow down. Wait a few minutes and try again.'**
  String importErrorSlowDown(String service);

  /// No description provided for @importErrorServer.
  ///
  /// In en, this message translates to:
  /// **'{service} has problems right now. Try again later.'**
  String importErrorServer(String service);

  /// No description provided for @importErrorPrivate.
  ///
  /// In en, this message translates to:
  /// **'This playlist is private or was deleted. Make it public, or export it to a file and import that.'**
  String get importErrorPrivate;

  /// No description provided for @importErrorRegion.
  ///
  /// In en, this message translates to:
  /// **'{service} does not answer from your country or network. Export the playlist to a CSV or JSON file and import that.'**
  String importErrorRegion(String service);

  /// No description provided for @importErrorAccount.
  ///
  /// In en, this message translates to:
  /// **'This list is private, so {service} needs your account. Connect it, or export a file.'**
  String importErrorAccount(String service);

  /// No description provided for @importErrorNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'{service} links need a free key, or export the playlist to a file.'**
  String importErrorNeedsKey(String service);

  /// No description provided for @importErrorCantRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read this {service} page. It may have changed. Export the playlist to a file and import that.'**
  String importErrorCantRead(String service);

  /// No description provided for @importErrorFile.
  ///
  /// In en, this message translates to:
  /// **'{problem} Prism reads CSV, JSON, M3U and .liner files.'**
  String importErrorFile(String problem);

  /// No description provided for @importErrorFileGone.
  ///
  /// In en, this message translates to:
  /// **'The file is no longer at {path}. Pick it again.'**
  String importErrorFileGone(String path);

  /// No description provided for @importErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading this. Try exporting the playlist to a file.'**
  String get importErrorUnknown;

  /// No description provided for @importSkipNotFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Skip {count} not found} other{Skip {count} not found}}'**
  String importSkipNotFound(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
