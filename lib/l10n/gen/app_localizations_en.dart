// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String nSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '$count song',
    );
    return '$_temp0';
  }

  @override
  String nAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '$count album',
    );
    return '$_temp0';
  }

  @override
  String nPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '$count playlist',
    );
    return '$_temp0';
  }

  @override
  String nFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders',
      one: '$count folder',
    );
    return '$_temp0';
  }

  @override
  String nDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String nTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '$count time',
    );
    return '$_temp0';
  }

  @override
  String nPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '$count play',
    );
    return '$_temp0';
  }

  @override
  String nDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates',
      one: '$count duplicate',
    );
    return '$_temp0';
  }

  @override
  String nGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '$count group',
    );
    return '$_temp0';
  }

  @override
  String nCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copies',
      one: '$count copy',
    );
    return '$_temp0';
  }

  @override
  String nNewArtists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new artists',
      one: '$count new artist',
    );
    return '$_temp0';
  }

  @override
  String nListening(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listening',
    );
    return '$_temp0';
  }

  @override
  String undoFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Put $count songs back as they were',
      one: 'Put $count song back as it was',
    );
    return '$_temp0';
  }

  @override
  String foundInfoFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found info for $count songs',
      one: 'Found info for $count song',
    );
    return '$_temp0';
  }

  @override
  String skipDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skip $count duplicates',
      one: 'Skip $count duplicate',
    );
    return '$_temp0';
  }

  @override
  String matchNSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Match $count songs',
      one: 'Match $count song',
    );
    return '$_temp0';
  }

  @override
  String createPlaylistN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Create playlist ($count songs)',
      one: 'Create playlist ($count song)',
    );
    return '$_temp0';
  }

  @override
  String notMeasuredYet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs not measured yet',
      one: '$count song not measured yet',
    );
    return '$_temp0';
  }

  @override
  String songsNotInLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs not in this library',
      one: '$count song not in this library',
    );
    return '$_temp0';
  }

  @override
  String readingNAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reading $count albums…',
      one: 'Reading $count album…',
    );
    return '$_temp0';
  }

  @override
  String readingNPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reading $count playlists…',
      one: 'Reading $count playlist…',
    );
    return '$_temp0';
  }

  @override
  String previewNPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preview · $count playlists',
      one: 'Preview · $count playlist',
    );
    return '$_temp0';
  }

  @override
  String songsFromOrigin(int count, Object origin) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs from $origin',
      one: '$count song from $origin',
    );
    return '$_temp0';
  }

  @override
  String musicFoldersIntro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count songs. Prism reads mp3, flac, m4a, ogg and wav files in these folders.',
      one:
          '$count song. Prism reads mp3, flac, m4a, ogg and wav files in these folders.',
    );
    return '$_temp0';
  }

  @override
  String versionAndSongs(int count, Object version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Version $version · $count songs in your library',
      one: 'Version $version · $count song in your library',
    );
    return '$_temp0';
  }

  @override
  String minutesValue(Object m) {
    return '$m min';
  }

  @override
  String hoursMinutesValue(Object h, Object m) {
    return '$h h $m min';
  }

  @override
  String secondsValue(Object s) {
    return '$s s';
  }

  @override
  String dbValue(Object sign, Object value) {
    return '$sign$value dB';
  }

  @override
  String stValue(Object sign, Object value) {
    return '$sign$value st';
  }

  @override
  String get notAValidJsonFile => 'Not a valid JSON file';

  @override
  String get themeFileMustContainAJson =>
      'Theme file must contain a JSON object';

  @override
  String unknownFileFormat(Object format) {
    return 'Unknown file format \"$format\"';
  }

  @override
  String themeWasMadeWithANewer(Object v) {
    return 'Theme was made with a newer Prism (v$v)';
  }

  @override
  String get missingThemeObject => 'Missing \"theme\" object';

  @override
  String invalidThemeValues(Object e) {
    return 'Invalid theme values: $e';
  }

  @override
  String get audioEffectsAreNotAvailableOn =>
      'Audio effects are not available on this platform.';

  @override
  String get equalizer => 'Equalizer';

  @override
  String get resetToFlat => 'Reset to flat';

  @override
  String get saveAsPreset => 'Save as preset';

  @override
  String get saveEqPreset => 'Save EQ preset';

  @override
  String get myPreset => 'My preset';

  @override
  String boostOfDbMayClipLower(Object db) {
    return 'Boost of $db dB may clip – lower the preamp. ';
  }

  @override
  String get aLimiterCatchesPeaksOnWindows =>
      '(A limiter catches peaks on Windows.)';

  @override
  String preset(Object name) {
    return 'preset \"$name\"';
  }

  @override
  String get preamp => 'Preamp';

  @override
  String get bassBoost => 'Bass boost';

  @override
  String get xOff => 'Off';

  @override
  String get xOn => 'On';

  @override
  String get cover => 'Cover';

  @override
  String get theCurrentCoverBlurredAndGrey =>
      'The current cover, blurred and grey. Uses no power at all.';

  @override
  String get matrix => 'Matrix';

  @override
  String get fallingSymbolsTheyLightUpAnd =>
      'Falling symbols. They light up and bend around the mouse, a click sends a shockwave.';

  @override
  String get constellation => 'Constellation';

  @override
  String get driftingStarsJoinedByLinesThe =>
      'Drifting stars joined by lines. The mouse pulls them in, a click scatters them.';

  @override
  String get ripple => 'Ripple';

  @override
  String get aGridOfDotsLikeA =>
      'A grid of dots like a water surface. The mouse leaves waves, the bass makes drops.';

  @override
  String get katakana => 'Katakana';

  @override
  String get x0And1 => '0 and 1';

  @override
  String get hex => 'Hex';

  @override
  String get letters => 'Letters';

  @override
  String get musicNotes => 'Music notes';

  @override
  String get myOwnText => 'My own text';

  @override
  String get dots => 'Dots';

  @override
  String get dashes => 'Dashes';

  @override
  String get plusSigns => 'Plus signs';

  @override
  String get trailLength => 'Trail length';

  @override
  String get lineLength => 'Line length';

  @override
  String get waveWidth => 'Wave width';

  @override
  String get amountOfRain => 'Amount of rain';

  @override
  String get numberOfStars => 'Number of stars';

  @override
  String get dotsPerArea => 'Dots per area';

  @override
  String get symbolSize => 'Symbol size';

  @override
  String get starSize => 'Star size';

  @override
  String get dotSize => 'Dot size';

  @override
  String get background => 'Background';

  @override
  String get tryIt => 'Try it';

  @override
  String get symbols => 'Symbols';

  @override
  String get yourSymbols => 'Your symbols';

  @override
  String get anyLettersOrSymbolsEG => 'Any letters or symbols, e.g. your name';

  @override
  String get shape => 'Shape';

  @override
  String get colors => 'Colors';

  @override
  String get useTheThemeColors => 'Use the theme colors';

  @override
  String get mainColor => 'Main color';

  @override
  String get highlightColor => 'Highlight color';

  @override
  String get look => 'Look';

  @override
  String get brightness => 'Brightness';

  @override
  String get speed => 'Speed';

  @override
  String get reactions => 'Reactions';

  @override
  String get clicksAlsoSendAWaveMusic =>
      'Clicks also send a wave. Music reaction analyses each song once, the first time it plays.';

  @override
  String get mouse => 'Mouse';

  @override
  String get music => 'Music';

  @override
  String get forEveryAnimatedBackground => 'For every animated background';

  @override
  String get strength => 'Strength';

  @override
  String get outOfFocus => 'Out of focus';

  @override
  String get frostedPanels => 'Frosted panels';

  @override
  String get panelsBlurWhatIsBehindThem => 'Panels blur what is behind them';

  @override
  String get solidPanels => 'Solid panels';

  @override
  String get keepTheCoverUnderneath => 'Keep the cover underneath';

  @override
  String get stopWhileTheMusicIsPaused => 'Stop while the music is paused';

  @override
  String get savesPower => 'Saves power';

  @override
  String get framesPerSecond => 'Frames per second';

  @override
  String get lowerSavesPower => 'Lower saves power';

  @override
  String get screen => 'Screen';

  @override
  String reset(Object style) {
    return 'Reset $style';
  }

  @override
  String get closeEsc => 'Close (Esc)';

  @override
  String get moveTheMouseAndClick => 'Move the mouse and click';

  @override
  String get watchOnYoutube => 'Watch on YouTube';

  @override
  String get openOnSoundcloud => 'Open on SoundCloud';

  @override
  String get findOnYoutube => 'Find on YouTube';

  @override
  String get connectedToDiscord => 'Connected to Discord';

  @override
  String connectedAs(Object user) {
    return 'Connected as $user';
  }

  @override
  String get discordIsnTRunningItConnects =>
      'Discord isn\'t running. It connects by itself when you open it.';

  @override
  String get discordDidnTAcceptThisApplication =>
      'Discord didn\'t accept this application ID.';

  @override
  String get oneSetupStepLeft => 'One setup step left';

  @override
  String get connecting => 'Connecting…';

  @override
  String get discordStatus => 'Discord status';

  @override
  String get songAlbumArtProgressLinksAnd =>
      'Song, album art, progress, links and who you listen with';

  @override
  String get findAlbumArt => 'Find album art';

  @override
  String get sendsTitleAndArtistToApple =>
      'Sends title and artist to Apple\'s and Deezer\'s public search. Discord can\'t show covers from your PC.';

  @override
  String get discordNeedsAnApplicationToShow =>
      'Discord needs an application to show a status, and only a logged-in person can create one. Once, 30 seconds: New Application → name it Prism → Create → copy Application ID. Prism picks it up from the clipboard by itself.';

  @override
  String get openTheDiscordPage => 'Open the Discord page';

  @override
  String get applicationId => 'Application ID';

  @override
  String get useMyOwnApplication => 'Use my own application';

  @override
  String get nothingPlaying => 'Nothing playing';

  @override
  String get backToFullWindow => 'Back to full window';

  @override
  String get miniPlayerAlwaysOnTop => 'Mini player (always on top)';

  @override
  String get trackNotFound => 'Track not found';

  @override
  String get ffmpegIsNotAvailableWaveformAnd =>
      'FFmpeg is not available – waveform and export are disabled.';

  @override
  String get savingNewTrack => 'Saving new track…';

  @override
  String get exporting => 'Exporting…';

  @override
  String get ffmpegIsNotAvailableOnThis =>
      'FFmpeg is not available on this device';

  @override
  String ffmpegFailed(Object code, Object tail) {
    return 'FFmpeg failed ($code):\n$tail';
  }

  @override
  String xEdit(Object title) {
    return '$title (edit)';
  }

  @override
  String couldNotDecodeAudio(Object tail) {
    return 'Could not decode audio:\n$tail';
  }

  @override
  String get pausedTheSearchServicesAreNot =>
      'Paused: the search services are not answering';

  @override
  String get prismNeedsPermissionToReadYour =>
      'Prism needs permission to read your music';

  @override
  String get settings => 'Settings';

  @override
  String get chooseAMusicFolder => 'Choose a music folder';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get xLibrary => 'Library';

  @override
  String get sortSongs => 'Sort songs';

  @override
  String get title => 'Title';

  @override
  String get artist => 'Artist';

  @override
  String get album => 'Album';

  @override
  String get recentlyAdded => 'Recently added';

  @override
  String get longestFirst => 'Longest first';

  @override
  String get songs => 'Songs';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artists';

  @override
  String get folders => 'Folders';

  @override
  String get songsArtistsAlbums => 'Songs, artists, albums';

  @override
  String get songsArtistsAlbumsHereAndOnline =>
      'Songs, artists, albums – here and online';

  @override
  String get typeToSearchYourLibrary => 'Type to search your library';

  @override
  String get typeToSearchYourLibraryAnd =>
      'Type to search your library and online';

  @override
  String get yourLibrary => 'Your library';

  @override
  String get nothingFoundInYourLibrary => 'Nothing found in your library';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get tryAgain => 'Try again';

  @override
  String get play => 'Play';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get yourLibraryIsEmpty => 'Your library is empty';

  @override
  String get addAFolderWithMusicMp3 =>
      'Add a folder with music (mp3, flac, m4a, ogg, wav).';

  @override
  String add(Object name) {
    return 'Add $name';
  }

  @override
  String get chooseFolder => 'Choose folder…';

  @override
  String lookingForMusicFiles(Object found) {
    return 'Looking for music… $found files';
  }

  @override
  String readingTags(Object done, Object total) {
    return 'Reading tags $done / $total';
  }

  @override
  String error(Object e) {
    return 'Error: $e';
  }

  @override
  String get playNext => 'Play next';

  @override
  String get playingNext => 'Playing next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get addToPlaylist => 'Add to playlist…';

  @override
  String get removeOfflineCopy => 'Remove offline copy';

  @override
  String get saveForOffline => 'Save for offline';

  @override
  String get personalUseOnlySeeSettingsOnline =>
      'Personal use only – see Settings → Online services';

  @override
  String get offlineCopyRemoved => 'Offline copy removed';

  @override
  String get savingForOffline => 'Saving for offline…';

  @override
  String openOn(Object service) {
    return 'Open on $service';
  }

  @override
  String get theWeb => 'the web';

  @override
  String get xEdit2 => 'Edit…';

  @override
  String get trimCutSpeedPitchFadesOriginal =>
      'Trim, cut, speed, pitch, fades – original stays untouched';

  @override
  String get editTags => 'Edit tags…';

  @override
  String get removeFromThisPlaylist => 'Remove from this playlist';

  @override
  String get goToAlbum => 'Go to album';

  @override
  String get goToArtist => 'Go to artist';

  @override
  String get more => 'More';

  @override
  String notSynced(Object source) {
    return 'Not synced · $source';
  }

  @override
  String get sameFile => 'same file';

  @override
  String get linkedVideo => 'linked video';

  @override
  String get notInYourLibraryTurnOn =>
      'Not in your library. Turn on YouTube playback or SoundCloud to look online.';

  @override
  String isMissingIn(Object what, Object path, Object error) {
    return '$what is missing in $path.$error';
  }

  @override
  String get youtubeApikeyOrTurnOnThe =>
      'youtube.apiKey (or turn on the YouTube extractor)';

  @override
  String pausedSongsLeft(Object left) {
    return 'Paused – $left songs left.';
  }

  @override
  String get importedPlaylist => 'Imported playlist';

  @override
  String portIsBusyCloseTheOther(Object port) {
    return 'Port $port is busy. Close the other app using it or change redirectPort in the config file.';
  }

  @override
  String get couldNotOpenTheBrowser => 'Could not open the browser.';

  @override
  String loginTimedOut(Object service) {
    return '$service login timed out.';
  }

  @override
  String get loginWasCancelled => 'Login was cancelled.';

  @override
  String loginFailed(Object service, Object error) {
    return '$service login failed: $error';
  }

  @override
  String connectFirstSettingsOnlineServices(Object service) {
    return 'Connect $service first (Settings → Online services).';
  }

  @override
  String didNotAnswerInTimeCheck(Object service) {
    return '$service did not answer in time. Check your connection.';
  }

  @override
  String secureConnectionToFailedCheckThe(Object service) {
    return 'Secure connection to $service failed (check the PC clock or a proxy).';
  }

  @override
  String get xFile => 'File';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get lowCheckIt => 'Low – check it';

  @override
  String get noMatch => 'No match';

  @override
  String notThe(Object v) {
    return 'not the $v';
  }

  @override
  String get theService => 'The service';

  @override
  String get youSeemToBeOfflineLocal =>
      'You seem to be offline. Local songs still play; online parts resume when you are back.';

  @override
  String isLimitingRequestsRightNowTry(Object name) {
    return '$name is limiting requests right now. Try again in a few minutes.';
  }

  @override
  String yourLoginExpiredConnectTheAccount(Object name) {
    return 'Your $name login expired. Connect the account again in Settings → Online services.';
  }

  @override
  String refusedTheRequest(Object name) {
    return '$name refused the request.';
  }

  @override
  String notFoundOnDeletedPrivateOr(Object name) {
    return 'Not found on $name (deleted, private or a wrong link).';
  }

  @override
  String hasServerProblemsTryAgainLater(Object name) {
    return '$name has server problems. Try again later.';
  }

  @override
  String needsAnApiKeyInThe(Object name) {
    return '$name needs an API key in the online config file (Settings → Online services).';
  }

  @override
  String isTurnedOffInSettingsOnline(Object name) {
    return '$name is turned off in Settings → Online services.';
  }

  @override
  String canNotDoThis(Object name) {
    return '$name can not do this.';
  }

  @override
  String sentSomethingUnexpectedItMayHave(Object name) {
    return '$name sent something unexpected (it may have changed). Try again later.';
  }

  @override
  String somethingWentWrong(Object e) {
    return 'Something went wrong: $e';
  }

  @override
  String get youtube => 'YouTube';

  @override
  String get playlistCreated => 'Playlist created';

  @override
  String get playlistUpdated => 'Playlist updated';

  @override
  String get open => 'Open';

  @override
  String get thisImportWasDeleted => 'This import was deleted';

  @override
  String get openPlaylist => 'Open playlist';

  @override
  String matchedOf(Object matched, Object total) {
    return '$matched of $total matched';
  }

  @override
  String nToCheck(Object n) {
    return '$n to check';
  }

  @override
  String nNotFound(Object n) {
    return '$n not found';
  }

  @override
  String matchingLocalFilesFirstThenOnline(Object done, Object total) {
    return 'Matching $done / $total… (local files first, then online)';
  }

  @override
  String get pause => 'Pause';

  @override
  String resumeMatchingLeft(Object left) {
    return 'Resume matching ($left left)';
  }

  @override
  String get updatePlaylistWithFixes => 'Update playlist with fixes';

  @override
  String xAll(Object n) {
    return 'All $n';
  }

  @override
  String check(Object n) {
    return 'Check $n';
  }

  @override
  String notFound(Object n) {
    return 'Not found $n';
  }

  @override
  String matched(Object n) {
    return 'Matched $n';
  }

  @override
  String duplicates(Object n) {
    return 'Duplicates $n';
  }

  @override
  String get waiting => 'Waiting…';

  @override
  String duplicateOfSkipped(Object n) {
    return 'Duplicate of #$n – skipped';
  }

  @override
  String get skipped => 'Skipped';

  @override
  String get noGoodMatchFound => 'No good match found';

  @override
  String get fix => 'Fix';

  @override
  String get fixMatch => 'Fix match';

  @override
  String get markedAsNoMatch => 'Marked as no match';

  @override
  String get nothingFoundTryOtherWords => 'Nothing found – try other words';

  @override
  String get listen => 'Listen';

  @override
  String get pasteAPlaylistAlbumOrLikes =>
      'Paste a playlist, album or likes link from Spotify, YouTube, SoundCloud, Apple Music or Deezer';

  @override
  String isTurnedOff(Object service) {
    return '$service is turned off';
  }

  @override
  String get notAvailable => 'not available';

  @override
  String get setUp => 'Set up';

  @override
  String reading(Object service) {
    return 'Reading $service…';
  }

  @override
  String get importAPlaylistFile => 'Import a playlist file';

  @override
  String get playlist => 'playlist';

  @override
  String get album2 => 'album';

  @override
  String get song => 'song';

  @override
  String get likes => 'likes';

  @override
  String get link => 'link';

  @override
  String get playlistAlbumAndLikesLinksWork =>
      'Playlist, album and likes links work';

  @override
  String get notALinkPrismCanRead => 'Not a link Prism can read';

  @override
  String needsToBeSetUpFirst(Object what, Object service) {
    return '$what · $service needs to be set up first';
  }

  @override
  String get fromYourClipboard => ' · from your clipboard';

  @override
  String get importPlaylists => 'Import playlists';

  @override
  String get bringYourPlaylistsFromSpotifyYoutube =>
      'Bring your playlists from Spotify, YouTube and other apps. Prism finds each song in your library first, then online, and shows how sure each match is.';

  @override
  String get pasteALink => 'Paste a link';

  @override
  String get clear => 'Clear';

  @override
  String get xImport => 'Import';

  @override
  String get orAFileCsvFromExportify =>
      'Or a file: CSV from Exportify or TuneMyMusic, JSON, M3U';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get setUpServices => 'Set up services';

  @override
  String get fromYourAccounts => 'From your accounts';

  @override
  String get yourImports => 'Your imports';

  @override
  String loading(Object service) {
    return 'Loading $service…';
  }

  @override
  String get notConnectedSettingsOnlineServices =>
      'Not connected – Settings → Online services';

  @override
  String get likedVideos => 'Liked videos';

  @override
  String get likedSongs => 'Liked songs';

  @override
  String get readingLikes => 'Reading likes…';

  @override
  String get savedAlbums => 'Saved albums…';

  @override
  String get savedAlbums2 => 'Saved albums';

  @override
  String get playlists => 'Playlists…';

  @override
  String get playlists2 => 'Playlists';

  @override
  String xImport2(Object n) {
    return 'Import $n';
  }

  @override
  String get nothingHere => 'Nothing here';

  @override
  String matching(Object done, Object total) {
    return 'Matching $done / $total…';
  }

  @override
  String pausedLeft(Object n) {
    return 'Paused · $n left';
  }

  @override
  String stoppedLeftTapToResume(Object n) {
    return 'Stopped · $n left – tap to resume';
  }

  @override
  String ofMatchedReadyToSave(Object matched, Object total) {
    return '$matched of $total matched · ready to save';
  }

  @override
  String ofMatchedSaved(Object matched, Object total) {
    return '$matched of $total matched · saved';
  }

  @override
  String get thisImportThePlaylistStays => 'this import (the playlist stays)';

  @override
  String get deleteImport => 'Delete import';

  @override
  String get preview => 'Preview';

  @override
  String get onlyYourLibraryWillBeSearched =>
      'Only your library will be searched';

  @override
  String get turnOnYoutubePlaybackOrSoundcloud =>
      'Turn on YouTube playback or SoundCloud in Settings → Online services to also match songs you don\'t have.';

  @override
  String get sameSongTwiceInOneList =>
      'Same song twice in one list (also different \"remaster\" tags)';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get importedBefore => 'Imported before';

  @override
  String ofMatchedImportingAgainMakesA(
    Object name,
    Object matched,
    Object total,
  ) {
    return '\"$name\" – $matched of $total matched. Importing again makes a new playlist.';
  }

  @override
  String duplicateOf(Object n) {
    return 'duplicate of #$n';
  }

  @override
  String get onlineServices => 'Online services';

  @override
  String get apiKeysFile => 'API keys file';

  @override
  String get keysAreReadOnlyFromThis =>
      'Keys are read only from this local file (never stored in the app or the repo). See README → Online services.';

  @override
  String get createFile => 'Create file';

  @override
  String templateAtFillInYourKeys(Object path) {
    return 'Template at $path – fill in your keys, then tap Reload.';
  }

  @override
  String get openFolder => 'Open folder';

  @override
  String get reload => 'Reload';

  @override
  String get configReloaded => 'Config reloaded';

  @override
  String get services => 'Services';

  @override
  String get offline => 'Offline';

  @override
  String get terms => 'Terms';

  @override
  String get importPlaylistsLikedSongsAndSaved =>
      'Import playlists, liked songs and saved albums (no audio)';

  @override
  String get searchPlaylistsPlaybackYoutubeYoutubeMusic =>
      'Search, playlists, playback (YouTube + YouTube Music links)';

  @override
  String get searchLikesAndPlaylistsPlaybackWhere =>
      'Search, likes and playlists, playback where allowed';

  @override
  String get importPublicPlaylistAlbumLinksNo =>
      'Import public playlist / album links (no login)';

  @override
  String get importPublicPlaylistAlbumLinksReads =>
      'Import public playlist / album links (reads the web page)';

  @override
  String finishTheLoginInYourBrowser(Object service) {
    return 'Finish the $service login in your browser…';
  }

  @override
  String get turnOnTheYoutubeExtractor => 'Turn on the YouTube extractor?';

  @override
  String get thisPlaysYoutubeAudioInsidePrism =>
      'This plays YouTube audio inside Prism, searches without an API key and can save offline copies. It uses an unofficial extractor, which YouTube\'s Terms of Service do not allow.\n\nUse it only for yourself, don\'t share saved files, and expect it to break sometimes.';

  @override
  String get cancel => 'Cancel';

  @override
  String get iUnderstandTurnOn => 'I understand, turn on';

  @override
  String needsSetup(Object msg) {
    return 'Needs setup: $msg';
  }

  @override
  String notWorking(Object msg) {
    return 'Not working: $msg';
  }

  @override
  String get ready => 'Ready';

  @override
  String redirectUriToRegister(Object uri) {
    return 'Redirect URI to register: $uri';
  }

  @override
  String get copy => 'Copy';

  @override
  String get youtubeExtractor => 'YouTube extractor';

  @override
  String get playbackOfflineCopiesSearchWithoutAn =>
      'Playback, offline copies, search without an API key';

  @override
  String get checking => 'Checking…';

  @override
  String get notConnected => 'Not connected';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connect => 'Connect';

  @override
  String get keepPlayedSongsOffline => 'Keep played songs offline';

  @override
  String get savesACopyOfYoutubeSongs =>
      'Saves a copy of YouTube songs you play, so they work without internet';

  @override
  String get needsTheYoutubeExtractor => 'Needs the YouTube extractor';

  @override
  String offlineCopiesMbOfGb(Object mb, Object gb) {
    return 'Offline copies: $mb MB of $gb GB';
  }

  @override
  String gb(Object gb) {
    return '$gb GB';
  }

  @override
  String get spotifyImportOnlyNeverAudio =>
      'Spotify – import only, never audio';

  @override
  String get usesTheOfficialWebApiTo =>
      'Uses the official Web API to read your playlists, liked songs and saved albums as text (title, artist, length). Prism never downloads, records or plays Spotify audio; songs are matched to your files or other services. Spotify\'s Developer Terms allow non-commercial apps; a Development Mode app works for at most 5 people you add in the Spotify dashboard, and only reads playlists you own or collaborate on.';

  @override
  String get youtubeDataApiOfficial => 'YouTube Data API – official';

  @override
  String get searchPlaylistsAndWithGoogleLogin =>
      'Search, playlists and (with Google login) your own playlists and liked videos through the official API with your own key. Limited by its daily quota (about 100 searches/day). The official API has no audio.';

  @override
  String get youtubeExtractorPlaybackAndOfflineCopies =>
      'YouTube extractor – playback and offline copies';

  @override
  String get playsYoutubeAudioInsidePrismSearches =>
      'Plays YouTube audio inside Prism, searches without a key and saves offline copies using an unofficial extractor (youtube_explode_dart). YouTube\'s Terms of Service do not allow this (no access except through their player, no downloads without a download button). Off by default; turn it on only for yourself, don\'t share saved files, and expect it to break when YouTube changes.';

  @override
  String get soundcloudOfficialApi => 'SoundCloud – official API';

  @override
  String get searchYourLikesAndPlaylistsThrough =>
      'Search, your likes and playlists through the official API with your own registered app. Only tracks the uploader made streamable are played, always credited to SoundCloud with a link. No offline copies (the API terms don\'t allow storing audio).';

  @override
  String get deezerPublicPlaylistLinks => 'Deezer – public playlist links';

  @override
  String get readsPublicPlaylistsAlbumsAndSongs =>
      'Reads public playlists, albums and songs from Deezer\'s open API (text only, no login, no audio). Deezer\'s API terms are for non-commercial use.';

  @override
  String get appleMusicPublicPageReading => 'Apple Music – public page reading';

  @override
  String get appleHasNoFreeApiSo =>
      'Apple has no free API, so Prism reads the song list from the public web page of a playlist or album when you import a link. Best effort: it can stop working whenever Apple changes the page. For personal use.';

  @override
  String get personalUseOnly => 'Personal use only';

  @override
  String get whatEachServiceAllows => 'What each service allows';

  @override
  String get termsOfServiceLimitsInPlain =>
      'Terms of service limits, in plain words';

  @override
  String get prismIsAPersonalPlayerFor =>
      'Prism is a personal player for you and friends. It is not affiliated with any of these services. API keys and logins are yours: keys stay in a local config file, logins in the system keychain.';

  @override
  String deezer(Object msg) {
    return 'Deezer: $msg';
  }

  @override
  String get couldNotOpenThisDeezerShort =>
      'Could not open this Deezer short link.';

  @override
  String get deezerPlaylist => 'Deezer playlist';

  @override
  String get openThisLink => 'open this link';

  @override
  String get couldNotReadSongsFromThis =>
      'Could not read songs from this Apple Music page (private playlist, or Apple changed the page). Use a TuneMyMusic CSV export instead.';

  @override
  String get appleMusicPlaylist => 'Apple Music playlist';

  @override
  String canNot(Object service, Object what) {
    return '$service can not $what.';
  }

  @override
  String get logIn => 'log in';

  @override
  String get listYourPlaylists => 'list your playlists';

  @override
  String get listSavedAlbums => 'list saved albums';

  @override
  String get readLikedSongs => 'read liked songs';

  @override
  String get openPlaylists => 'open playlists';

  @override
  String get openLinks => 'open links';

  @override
  String get playAudio => 'play audio';

  @override
  String get saveSongsOffline => 'save songs offline';

  @override
  String get soundcloudLogInOrAddThe =>
      'SoundCloud: log in, or add the app\'s client secret to the config file for search without login.';

  @override
  String get soundcloudUser => 'SoundCloud user';

  @override
  String get connected => 'Connected';

  @override
  String get playlist2 => 'Playlist';

  @override
  String get likesSoundcloud => 'Likes (SoundCloud)';

  @override
  String get soundcloudPlaylist => 'SoundCloud playlist';

  @override
  String likesOf(Object user) {
    return 'Likes of $user';
  }

  @override
  String get theUploaderDoesNotAllowStreaming =>
      'The uploader does not allow streaming this SoundCloud track outside SoundCloud.';

  @override
  String get spotifyUser => 'Spotify user';

  @override
  String get likedSongsSpotify => 'Liked Songs (Spotify)';

  @override
  String get openTheSpotifyLinkInA =>
      'Open the spotify.link in a browser and paste the full open.spotify.com link.';

  @override
  String get spotifyPlaylist => 'Spotify playlist';

  @override
  String get spotifyOnlyLetsSmallDevelopmentMode =>
      'Spotify only lets small (Development Mode) apps read playlists you own or collaborate on. For other playlists: export them with Exportify or TuneMyMusic and import the CSV file.';

  @override
  String get youtubeDataApiOfficial2 => 'YouTube Data API (official)';

  @override
  String get youtubePlaylist => 'YouTube playlist';

  @override
  String get youtubeExplodeUnofficial => 'youtube_explode (unofficial)';

  @override
  String get youtubeAsksToSlowDownToo =>
      'YouTube asks to slow down (too many searches from this connection). Wait a while, then resume.';

  @override
  String get youtubeDidNotAnswerInTime => 'YouTube did not answer in time.';

  @override
  String thisYoutubeVideoIsUnavailableRemoved(Object e) {
    return 'This YouTube video is unavailable (removed, private or region-locked). $e';
  }

  @override
  String youtubeExtractorFailedYoutubeMayHave(Object e) {
    return 'YouTube extractor failed – YouTube may have changed. $e';
  }

  @override
  String notAValidYoutubeId(Object e) {
    return 'Not a valid YouTube id: $e';
  }

  @override
  String get noAudioStreamForThisVideo => 'No audio stream for this video.';

  @override
  String canNotStreamAudio(Object name) {
    return '$name can not stream audio';
  }

  @override
  String canNotDownloadAudio(Object name) {
    return '$name can not download audio';
  }

  @override
  String get addAYoutubeDataApiKey =>
      'Add a YouTube Data API key to the config file, or turn on the YouTube extractor.';

  @override
  String get searchAndImportWorkPlaybackNeeds =>
      'Search and import work. Playback needs the YouTube extractor (personal use only).';

  @override
  String get googleAccount => 'Google account';

  @override
  String get logInNoGoogleOauthClient =>
      'log in (no Google OAuth client id in the config file)';

  @override
  String get listYourPlaylistsWithoutAGoogle =>
      'list your playlists without a Google login';

  @override
  String get readLikedVideosWithoutAGoogle =>
      'read liked videos without a Google login';

  @override
  String get likedVideosYoutube => 'Liked videos (YouTube)';

  @override
  String get openThisKindOfLink => 'open this kind of link';

  @override
  String get youtubePlaybackIsOffTurnOn =>
      'YouTube playback is off. Turn on \"YouTube extractor\" in Settings → Online services (personal use only).';

  @override
  String get saveSongsOfflineWithoutTheExtractor =>
      'save songs offline without the extractor';

  @override
  String get waveform => 'Waveform';

  @override
  String get barsWithABrightTrailBehind =>
      'Bars with a bright trail behind the playhead';

  @override
  String get ribbon => 'Ribbon';

  @override
  String get aLineThatWavesWhileThe =>
      'A line that waves while the song plays and flattens on pause';

  @override
  String get ledBlocks => 'LED blocks';

  @override
  String get aHiFiMeterMadeOf =>
      'A hi-fi meter made of small blocks, with a lit column at the playhead';

  @override
  String get tuner => 'Tuner';

  @override
  String get aRadioDialWithANeedle =>
      'A radio dial with a needle, the scale swells around it';

  @override
  String get liveSpectrum => 'Live spectrum';

  @override
  String get theWholeBarIsASpectrum =>
      'The whole bar is a spectrum analyser, it always moves';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get endOfSong => 'End of song';

  @override
  String get x1Min => '< 1 min';

  @override
  String get normal => 'Normal';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get speedPitch => 'Speed & pitch';

  @override
  String get aBLoop => 'A-B loop';

  @override
  String get setB => 'Set B';

  @override
  String get listenTogether => 'Listen together';

  @override
  String get miniPlayer => 'Mini player';

  @override
  String get leaveFullScreenF11 => 'Leave full screen (F11)';

  @override
  String get fullScreenF11 => 'Full screen (F11)';

  @override
  String get next => 'Next';

  @override
  String get upNext => 'Up next';

  @override
  String get close => 'Close';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get editThisSong => 'Edit this song';

  @override
  String get queue => 'Queue';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get visualizer => 'Visualizer';

  @override
  String get expand => 'Expand';

  @override
  String get unmute => 'Unmute';

  @override
  String mute(Object v) {
    return 'Mute ($v %)';
  }

  @override
  String get queueIsEmpty => 'Queue is empty';

  @override
  String get stopsAfterThisSong => 'Stops after this song';

  @override
  String stopsIn(Object t) {
    return 'Stops in $t';
  }

  @override
  String get musicFadesOutAndPauses => 'Music fades out and pauses';

  @override
  String get turnOff => 'Turn off';

  @override
  String loopingTapToClear(Object a, Object b) {
    return 'Looping $a–$b (tap to clear)';
  }

  @override
  String get tapAgainToSetB => 'Tap again to set B';

  @override
  String get aBLoopTapToSet => 'A-B loop: tap to set A';

  @override
  String xPitchKept(Object v) {
    return '${v}x  (pitch kept)';
  }

  @override
  String get pitch => 'Pitch';

  @override
  String semitonesSpeedKept(Object sign, Object v) {
    return '$sign$v semitones  (speed kept)';
  }

  @override
  String get reset2 => 'Reset';

  @override
  String get shuffleOn => 'Shuffle on';

  @override
  String get shuffleOff => 'Shuffle off';

  @override
  String get previous => 'Previous';

  @override
  String get repeatOff => 'Repeat off';

  @override
  String get repeatAll => 'Repeat all';

  @override
  String get repeatOne => 'Repeat one';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get favorites => 'Favorites';

  @override
  String get yourListeningStats => 'Your listening stats';

  @override
  String get topSongsArtistsAndStreaks => 'Top songs, artists and streaks';

  @override
  String get fromSpotifyYoutubeSoundcloudDeezerApple =>
      'From a link or a file. Spotify, YouTube, SoundCloud, Yandex Music, Apple Music, Deezer';

  @override
  String get smartPlaylists => 'Smart playlists';

  @override
  String get xNew => 'New';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String delete2(Object what) {
    return 'Delete $what?';
  }

  @override
  String get thisCannotBeUndone => 'This cannot be undone.';

  @override
  String get addToPlaylist2 => 'Add to playlist';

  @override
  String get newPlaylist2 => 'New playlist…';

  @override
  String get addedToPlaylist => 'Added to playlist';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get emptyPlaylistLongPressASong =>
      'Empty playlist.\nLong-press a song → \"Add to playlist\".';

  @override
  String get hue => 'Hue';

  @override
  String get saturation => 'Saturation';

  @override
  String get lightness => 'Lightness';

  @override
  String get noLyricsPlain =>
      'No lyrics found.\nPut a .lrc file with the same name next to the song.';

  @override
  String get noLyricsHint =>
      'No lyrics found.\nPut a .lrc file with the same name next to the song, or turn on online lyrics in Settings.';

  @override
  String get playback => 'Playback';

  @override
  String get appearance => 'Appearance';

  @override
  String get onlineImport => 'Online & import';

  @override
  String get windows => 'Windows';

  @override
  String get backup => 'Backup';

  @override
  String get about => 'About';

  @override
  String crossfadeN(Object s) {
    return 'Crossfade $s s';
  }

  @override
  String get gapless => 'Gapless';

  @override
  String get eqOn => 'EQ on';

  @override
  String get eqOff => 'EQ off';

  @override
  String get importPlaylistsAccountsOfflineCopies =>
      'Import playlists, accounts, offline copies';

  @override
  String get anywhere => 'Anywhere';

  @override
  String get sameWiFiOnly => 'Same Wi-Fi only';

  @override
  String get closesToTheTray => 'Closes to the tray';

  @override
  String get saveOrRestoreEverythingInOne =>
      'Save or restore everything in one file';

  @override
  String get musicFolders => 'Music folders';

  @override
  String get removeFolder => 'Remove folder';

  @override
  String get addFolder => 'Add folder';

  @override
  String get rescanLibrary => 'Rescan library';

  @override
  String lastScanNewChangedRemovedIn(
    Object added,
    Object updated,
    Object removed,
    Object s,
  ) {
    return 'Last scan: $added new, $updated changed, $removed removed in $s s';
  }

  @override
  String get onlyNewOrChangedFilesAre =>
      'Only new or changed files are read again';

  @override
  String get findDuplicates => 'Find duplicates';

  @override
  String get theSameSongInSeveralFiles => 'The same song in several files';

  @override
  String get sound => 'Sound';

  @override
  String get crossfade => 'Crossfade';

  @override
  String get blendTheEndOfASong => 'Blend the end of a song into the next one';

  @override
  String get offGapless => 'Off, gapless';

  @override
  String get sendsOnlyTitleArtistAlbumAnd =>
      'Sends only title, artist, album and length to lrclib.net. Local .lrc files always work.';

  @override
  String get findLyricsOnline => 'Find lyrics online';

  @override
  String get theme => 'Theme';

  @override
  String get matrixConstellationRippleReactsToThe =>
      'Matrix, Constellation, Ripple. Reacts to the mouse and the music';

  @override
  String get shownInTheFullPlayer => 'Shown in the full player';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get turnsOffDecorativeAnimations => 'Turns off decorative animations';

  @override
  String get seekBar => 'Seek bar';

  @override
  String get rightClickTheSeekBarTo =>
      'Right-click the seek bar to switch any time.';

  @override
  String get movesWithTheMusic => 'Moves with the music';

  @override
  String get everyStyleReactsToTheSong =>
      'Every style reacts to the song. Analyses each song once, the first time it plays';

  @override
  String get fromALinkAFileOr => 'From a link, a file or your accounts';

  @override
  String get spotifyYoutubeSoundcloudDeezerAppleMusic =>
      'Spotify, YouTube, SoundCloud, Deezer, Apple Music';

  @override
  String get sessionsOnTheSameWiFi =>
      'Sessions on the same Wi-Fi connect directly and show up in a list. Over the internet, messages go through a free public server (HiveMQ, EMQX or Mosquitto): song names, length and position, scrambled with the session code. Never any audio.';

  @override
  String get sessionsOverTheInternet => 'Sessions over the internet';

  @override
  String get offSameWiFiOnlyNothing =>
      'Off: same Wi-Fi only, nothing leaves your network';

  @override
  String get yourNameInASession => 'Your name in a session';

  @override
  String get theNameOfThisDevice => 'The name of this device';

  @override
  String get ownServerOptional => 'Own server (optional)';

  @override
  String get ifYouWouldRatherNotUse =>
      'If you would rather not use the public server: someone runs \"dart run tool/relay.dart\" on a reachable computer and everyone enters its address here.';

  @override
  String get closeToTray => 'Close to tray';

  @override
  String get keepPlayingInTheTrayWhen =>
      'Keep playing in the tray when the window is closed';

  @override
  String get settingsEqThemesPlaylistsFavoritesSmart =>
      'Settings, EQ, themes, playlists, favorites, smart playlists and edits. Songs are matched by path or by title and artist, so a backup also works on another device.';

  @override
  String get backUpToAFile => 'Back up to a file';

  @override
  String get restoreFromAFile => 'Restore from a file';

  @override
  String get aMusicPlayerForYourOwn =>
      'A music player for your own songs, made for me and a few friends. Windows and Android.';

  @override
  String lookingOfSongsFound(Object done, Object total, Object found) {
    return 'Looking… $done of $total songs, found $found';
  }

  @override
  String get nothingFoundYet => 'Nothing found yet';

  @override
  String get missingInfo => 'Missing info';

  @override
  String get sendsOnlyTitleAndArtistTo =>
      'Sends only title and artist to Apple\'s and Deezer\'s public search. Your files are never changed and your own tags are never replaced. A song without tags only gets info when its file name clearly matches.';

  @override
  String get findCoversAndArtistsOnline => 'Find covers and artists online';

  @override
  String get lookAgain => 'Look again';

  @override
  String get forSongsThatGotNothingSo => 'For songs that got nothing so far';

  @override
  String get undoEverythingFound => 'Undo everything found';

  @override
  String get backToWhatYourFilesSay => 'Back to what your files say';

  @override
  String get loudness => 'Loudness';

  @override
  String get usesReplaygainTagsOrMeasuresSongs =>
      'Uses ReplayGain tags, or measures songs with FFmpeg (EBU R128, −18 LUFS).';

  @override
  String get evenOutLoudness => 'Even out loudness';

  @override
  String get song2 => 'Song';

  @override
  String get measureSongsAutomatically => 'Measure songs automatically';

  @override
  String get whenASongWithoutReplaygainTags =>
      'When a song without ReplayGain tags starts playing';

  @override
  String get measureTheWholeLibrary => 'Measure the whole library';

  @override
  String measuringOf(Object done, Object total) {
    return 'Measuring $done of $total';
  }

  @override
  String get ffmpegIsMissingOnThisDevice => 'FFmpeg is missing on this device';

  @override
  String get stop => 'Stop';

  @override
  String get exportTheme => 'Export theme';

  @override
  String get themeExported => 'Theme exported';

  @override
  String get importTheme => 'Import theme';

  @override
  String imported(Object name) {
    return 'Imported \"$name\"';
  }

  @override
  String couldNotImport(Object e) {
    return 'Could not import: $e';
  }

  @override
  String get saveAs => 'Save as…';

  @override
  String get saveThemeAs => 'Save theme as';

  @override
  String get myTheme => 'My theme';

  @override
  String saved(Object name) {
    return 'Saved \"$name\"';
  }

  @override
  String get presets => 'Presets';

  @override
  String get mode => 'Mode';

  @override
  String get auto => 'Auto';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get blackWhite => 'Black & white';

  @override
  String get greysOnlyCoversStayInColor => 'Greys only, covers stay in color';

  @override
  String get colorsFromAlbumArt => 'Colors from album art';

  @override
  String get primaryColorFollowsTheCurrentCover =>
      'Primary color follows the current cover';

  @override
  String get primary => 'Primary';

  @override
  String get accent => 'Accent';

  @override
  String get shapeSurfaces => 'Shape & surfaces';

  @override
  String get cornerRadius => 'Corner radius';

  @override
  String px(Object v) {
    return '$v px';
  }

  @override
  String get glassBlur => 'Glass / blur';

  @override
  String get textMotion => 'Text & motion';

  @override
  String get font => 'Font';

  @override
  String get system => 'System';

  @override
  String get animationSpeed => 'Animation speed';

  @override
  String fastX(Object v) {
    return 'Fast (${v}x)';
  }

  @override
  String slowX(Object v) {
    return 'Slow (${v}x)';
  }

  @override
  String normalX(Object v) {
    return 'Normal (${v}x)';
  }

  @override
  String get themeName => 'Theme name';

  @override
  String longPressToDelete(Object name) {
    return '$name (long-press to delete)';
  }

  @override
  String get previewSong => 'Preview song';

  @override
  String glassPanelPx(Object r) {
    return 'Glass panel · $r px';
  }

  @override
  String get search => 'Search';

  @override
  String get stats => 'Stats';

  @override
  String code(Object code) {
    return 'Code $code';
  }

  @override
  String xWith(Object name) {
    return 'With $name';
  }

  @override
  String get aFriend => 'a friend';

  @override
  String get rightClickNextBackground => 'Right-click: next background';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get allTime => 'All time';

  @override
  String get morning => 'Morning';

  @override
  String get x5To12 => '5 to 12';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get x12To18 => '12 to 18';

  @override
  String get evening => 'Evening';

  @override
  String get x18To23 => '18 to 23';

  @override
  String get night => 'Night';

  @override
  String get x23To5 => '23 to 5';

  @override
  String get mostPlayed => 'Most played';

  @override
  String get forgottenGems => 'Forgotten gems';

  @override
  String get smartPlaylistNotFound => 'Smart playlist not found';

  @override
  String get editRules => 'Edit rules';

  @override
  String get allSongs => 'all songs';

  @override
  String playedNPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'played $count+ times',
      one: 'played $count+ time',
    );
    return '$_temp0';
  }

  @override
  String inDays(Object days) {
    return 'in $days days';
  }

  @override
  String addedInTheLastDays(Object days) {
    return 'added in the last $days days';
  }

  @override
  String genre(Object genre) {
    return 'genre \"$genre\"';
  }

  @override
  String year2(Object from, Object to) {
    return 'year $from–$to';
  }

  @override
  String notPlayedForDays(Object days) {
    return 'not played for $days days';
  }

  @override
  String get mySmartPlaylist => 'My smart playlist';

  @override
  String get minPlays => 'min plays';

  @override
  String get inDays2 => 'in days';

  @override
  String get genre2 => 'Genre';

  @override
  String get notPlayedFor => 'Not played for';

  @override
  String get editSmartPlaylist => 'Edit smart playlist';

  @override
  String get newSmartPlaylist => 'New smart playlist';

  @override
  String get name => 'Name';

  @override
  String get songsThatMatchAllRules => 'Songs that match all rules:';

  @override
  String get addRule => 'Add rule';

  @override
  String get sortBy => 'Sort by  ';

  @override
  String get random => 'Random';

  @override
  String get maxSongs => 'max songs';

  @override
  String get smartPlaylist => 'Smart playlist';

  @override
  String get justNow => 'just now';

  @override
  String minAgo(Object m) {
    return '$m min ago';
  }

  @override
  String hAgo(Object h) {
    return '$h h ago';
  }

  @override
  String vsBefore(Object sign, Object pct) {
    return '$sign$pct % vs before';
  }

  @override
  String get atAGlance => 'At a glance';

  @override
  String get listeningTime => 'Listening time';

  @override
  String get plays => 'Plays';

  @override
  String get differentSongs => 'Different songs';

  @override
  String playedOnlyOnce(Object n) {
    return '$n played only once';
  }

  @override
  String get newToYou => 'New to you';

  @override
  String get daysWithMusic => 'Days with music';

  @override
  String aboutADay(Object t) {
    return 'about $t a day';
  }

  @override
  String get currentStreak => 'Current streak';

  @override
  String best(Object n) {
    return 'best: $n';
  }

  @override
  String get sessions => 'Sessions';

  @override
  String aboutEach(Object t) {
    return 'about $t each';
  }

  @override
  String get youHearOfASong => 'You hear of a song';

  @override
  String get onAverage => 'on average';

  @override
  String get minutesPerDay => 'Minutes per day';

  @override
  String get minutesPerMonth => 'Minutes per month';

  @override
  String min(Object when, Object m) {
    return '$when · $m min';
  }

  @override
  String get yourWeek => 'Your week';

  @override
  String get darkerMeansMoreMinutesHoverFor =>
      'Darker means more minutes. Hover for the numbers.';

  @override
  String get last6Months => 'Last 6 months';

  @override
  String get timeOfDay => 'Time of day';

  @override
  String ofYourListeningIsOnWeekends(Object pct) {
    return '$pct % of your listening is on weekends';
  }

  @override
  String get musicByDecade => 'Music by decade';

  @override
  String get songsNeedAYearTagFor => 'Songs need a year tag for this';

  @override
  String get howOldIsWhatYouPlay => 'How old is what you play?';

  @override
  String get records => 'Records';

  @override
  String get longestSession => 'Longest session';

  @override
  String nSongsOnDate(int count, Object date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs, $date',
      one: '$count song, $date',
    );
    return '$_temp0';
  }

  @override
  String get biggestDay => 'Biggest day';

  @override
  String onRepeat(Object title) {
    return 'On repeat: $title';
  }

  @override
  String xOn2(Object date) {
    return 'on $date';
  }

  @override
  String loyalTo(Object artist) {
    return 'Loyal to $artist';
  }

  @override
  String get ofYourPlays => 'of your plays';

  @override
  String get topSongs => 'Top songs';

  @override
  String get topArtists => 'Top artists';

  @override
  String get topAlbums => 'Top albums';

  @override
  String get topGenres => 'Top genres';

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get totalLength => 'Total length';

  @override
  String daysNonstop(Object d) {
    return '$d days nonstop';
  }

  @override
  String get averageSong => 'Average song';

  @override
  String get neverPlayed => 'Never played';

  @override
  String get withACover => 'With a cover';

  @override
  String fullyTagged(Object n) {
    return '$n fully tagged';
  }

  @override
  String get extremes => 'Extremes';

  @override
  String longest(Object title) {
    return 'Longest: $title';
  }

  @override
  String shortest(Object title) {
    return 'Shortest: $title';
  }

  @override
  String get fileTypes => 'File types';

  @override
  String get genres => 'Genres';

  @override
  String get decades => 'Decades';

  @override
  String get noListensYetInThisPeriod =>
      'No listens yet in this period.\nA song counts after 30 seconds, or half of it if it is short.';

  @override
  String get yourListening => 'Your listening';

  @override
  String get overview => 'Overview';

  @override
  String get xTop => 'Top';

  @override
  String get history => 'History';

  @override
  String get wrapped => 'Wrapped';

  @override
  String get aMorningListener => 'a morning listener';

  @override
  String get anAfternoonListener => 'an afternoon listener';

  @override
  String get anEveningListener => 'an evening listener';

  @override
  String get aNightOwl => 'a night owl';

  @override
  String get thisWeekYouListenedFor => 'This week you listened for';

  @override
  String get thisMonthYouListenedFor => 'This month you listened for';

  @override
  String get thisYearYouListenedFor => 'This year you listened for';

  @override
  String get inTotalYouListenedFor => 'In total you listened for';

  @override
  String nDifferentSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count different songs',
      one: '$count different song',
    );
    return '$_temp0';
  }

  @override
  String youAreMostPlaysAround00(Object who, Object hour) {
    return 'You are $who – most plays around $hour:00';
  }

  @override
  String get longestListeningStreak => 'Longest listening streak';

  @override
  String get daysInARow => 'days in a row';

  @override
  String get daysInARowWithAt => 'Days in a row with at least one song';

  @override
  String get yourTopSong => 'Your top song';

  @override
  String get whenYouListen => 'When you listen';

  @override
  String get someone => 'Someone';

  @override
  String get starting => 'Starting…';

  @override
  String get couldNotStartCheckYourNetwork =>
      'Could not start. Check your network connection.';

  @override
  String get waitingForFriends => 'Waiting for friends…';

  @override
  String get friend => 'Friend';

  @override
  String get listeningTogether => 'Listening together';

  @override
  String get thatCodeDoesNotLookRight => 'That code does not look right';

  @override
  String lookingFor(Object room) {
    return 'Looking for $room…';
  }

  @override
  String get onlineSessionsAreOffSettingsListen =>
      'Online sessions are off (Settings → Listen together)';

  @override
  String noSessionWithTheCodeCheck(Object room) {
    return 'No session with the code $room. Check the code, the host must keep Prism open.';
  }

  @override
  String get followingTheHost => 'Following the host';

  @override
  String get reconnecting => 'Reconnecting…';

  @override
  String get theHostIsGone => 'The host is gone';

  @override
  String get waitingForTheHost => 'Waiting for the host…';

  @override
  String get theHostEndedTheSession => 'The host ended the session';

  @override
  String get lookingForTheSongOnline => 'Looking for the song online…';

  @override
  String get theHostIsPlayingASong =>
      'The host is playing a song you don\'t have';

  @override
  String get everyonePlaysTheSameSongAt =>
      'Everyone plays the same song at the same moment.';

  @override
  String get sendThisCodeToYourFriends => 'Send this code to your friends';

  @override
  String get copied => 'Copied';

  @override
  String get worksFromAnywhere => 'Works from anywhere.';

  @override
  String get worksOnThisWiFiOnly => 'Works on this Wi-Fi only.';

  @override
  String get endSession => 'End session';

  @override
  String session(Object code) {
    return 'Session $code';
  }

  @override
  String missing(Object song) {
    return 'Missing: $song';
  }

  @override
  String get addTheSongToYourLibrary =>
      'Add the song to your library, or turn on YouTube or SoundCloud in Settings → Online & import.';

  @override
  String get justYouAndTheHost => 'Just you and the host';

  @override
  String get leave => 'Leave';

  @override
  String get friendSCode => 'Friend\'s code';

  @override
  String get join => 'Join';

  @override
  String get startASession => 'Start a session';

  @override
  String get eachPersonPlaysTheSongFrom =>
      'Each person plays the song from their own library. Song names pass through a free public server, scrambled with the code. You can turn that off in Settings → Listen together.';

  @override
  String get onThisNetwork => 'On this network';

  @override
  String backupSummary(
    Object playlists,
    Object playlistSongs,
    Object favorites,
    Object themes,
    Object smart,
    Object edits,
  ) {
    return '$playlists playlists ($playlistSongs songs), $favorites favorites, $themes themes, $smart smart playlists, $edits edits';
  }

  @override
  String get notAPrismBackupInvalidJson => 'Not a Prism backup (invalid JSON)';

  @override
  String get notAPrismBackup => 'Not a Prism backup';

  @override
  String get backupIsFromANewerPrism => 'Backup is from a newer Prism version';

  @override
  String restored(Object name) {
    return '$name (restored)';
  }

  @override
  String writingTagsIsNotSupportedFor(Object ext) {
    return 'Writing tags is not supported for $ext files';
  }

  @override
  String couldNotWriteTags(Object e) {
    return 'Could not write tags: $e';
  }

  @override
  String get tagsDidNotStickFileRestored =>
      'Tags did not stick (file restored)';

  @override
  String get duplicateFinder => 'Duplicate finder';

  @override
  String get noDuplicatesFound => 'No duplicates found 🎉';

  @override
  String nGroupsHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count groups. Keep the best copy; removing from the library leaves the file on disk.',
      one:
          '$count group. Keep the best copy; removing from the library leaves the file on disk.',
    );
    return '$_temp0';
  }

  @override
  String theFile(Object uri) {
    return 'the file\n$uri';
  }

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String get deleteFile => 'Delete file…';

  @override
  String mb(Object mb) {
    return '$mb MB';
  }

  @override
  String get chooseCoverImage => 'Choose cover image';

  @override
  String get tagsSavedABackupOfThe =>
      'Tags saved (a backup of the original was kept)';

  @override
  String get editTags2 => 'Edit tags';

  @override
  String get changeCover => 'Change cover…';

  @override
  String get removeCover => 'Remove cover';

  @override
  String get track => 'Track';

  @override
  String get thisFormatOggCanOnlyBe =>
      'This format (OGG) can only be read, not edited.';

  @override
  String get saveToFile => 'Save to file';

  @override
  String get savePrismBackup => 'Save Prism backup';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String backupFailed(Object e) {
    return 'Backup failed: $e';
  }

  @override
  String get restorePrismBackup => 'Restore Prism backup';

  @override
  String restored2(Object report) {
    return 'Restored: $report';
  }

  @override
  String restoreFailed(Object e) {
    return 'Restore failed: $e';
  }

  @override
  String get theVisualizerWorksWithSongsFrom =>
      'The visualizer works with songs from your library';

  @override
  String get analysingTheSong => 'Analysing the song';

  @override
  String get couldNotAnalyseThisSong => 'Could not analyse this song';

  @override
  String get theVisualizerNeedsFfmpegWhichIs =>
      'The visualizer needs FFmpeg, which is missing on this device';

  @override
  String get bars => 'Bars';

  @override
  String get mirror => 'Mirror';

  @override
  String get radial => 'Radial';

  @override
  String get wave => 'Wave';

  @override
  String get vuMeters => 'VU meters';

  @override
  String get waterfall => 'Waterfall';

  @override
  String get ledMatrix => 'LED matrix';

  @override
  String get low => 'Low';

  @override
  String thisDeviceSEqualizerHasBands(Object n, Object freqs, Object db) {
    return 'This device\'s Equalizer has $n bands ($freqs Hz, ±$db dB); the 10-band curve is sampled at those frequencies.Bass boost uses the system BassBoost effect; its exact curve depends on the phone.Some phones (or other EQ apps like Wavelet) can override or block audio effects.';
  }

  @override
  String get changingEqBandsRebuildsTheLibmpv =>
      'Changing EQ bands rebuilds the libmpv filter chain; fast slider drags are smoothed, but a very short click is possible.';

  @override
  String get livePitchShiftUsesResamplingTime =>
      'Live pitch shift uses resampling + time-stretch (WSOLA); exports use rubberband, which sounds a bit cleaner.';

  @override
  String get unknownSong => 'Unknown song';

  @override
  String paused(Object who) {
    return 'Paused · $who';
  }

  @override
  String get playingInPrism => 'Playing in Prism';

  @override
  String get paused2 => 'Paused';

  @override
  String get openInAppleMusic => 'Open in Apple Music';

  @override
  String get openOnDeezer => 'Open on Deezer';

  @override
  String get thisDevice => 'This device';

  @override
  String couldNotRead(Object path, Object e) {
    return 'Could not read $path: $e';
  }

  @override
  String get topLevelMustBeAnObject => 'top level must be an object';

  @override
  String noSongsFoundIn(Object file) {
    return 'No songs found in $file.';
  }

  @override
  String get theCsvFileHasNoSong => 'The CSV file has no song rows.';

  @override
  String get couldNotFindATitleColumn =>
      'Could not find a title column. Expected a header like \"Track name\" or \"Title\".';

  @override
  String notValidJson(Object e) {
    return 'Not valid JSON: $e';
  }

  @override
  String get unknownJsonLayout => 'Unknown JSON layout.';

  @override
  String get couldNotFindASongList =>
      'Could not find a song list in the JSON (expected \"tracks\", \"items\" or \"playlists\").';

  @override
  String onlineServicesUnavailable(Object e) {
    return 'Online services unavailable: $e';
  }

  @override
  String get dragOnTheWaveformToSelect =>
      'Drag on the waveform to select a part first';

  @override
  String get saveAsNewTrack => 'Save as new track';

  @override
  String get exportToFile => 'Export to file';

  @override
  String savedAndAddedToYourLibrary(Object path) {
    return 'Saved and added to your library:\n$path';
  }

  @override
  String get exportEdit => 'Export edit';

  @override
  String get exported => 'Exported';

  @override
  String exportFailed(Object e) {
    return 'Export failed: $e';
  }

  @override
  String get editor => 'Editor';

  @override
  String get readingWaveform => 'Reading waveform…';

  @override
  String get undoCtrlZ => 'Undo (Ctrl+Z)';

  @override
  String get redoCtrlY => 'Redo (Ctrl+Y)';

  @override
  String get saveExport => 'Save / export';

  @override
  String get saveAsNewTrack2 => 'Save as new track…';

  @override
  String get exportToFile2 => 'Export to file…';

  @override
  String get playThisEditInThePlayer => 'Play this edit in the player';

  @override
  String get livePresetTheOriginalFileIs =>
      'Live preset – the original file is never changed';

  @override
  String editedOriginal(Object a, Object b) {
    return 'Edited $a  ·  original $b';
  }

  @override
  String selection(Object a, Object b) {
    return 'Selection $a – $b';
  }

  @override
  String get xEdit3 => 'Edit';

  @override
  String get splitAtCursor => 'Split at cursor';

  @override
  String get cut => 'Cut';

  @override
  String get trimToSelection => 'Trim to selection';

  @override
  String get speed2 => 'Speed…';

  @override
  String get speedPitchKept => 'Speed (pitch kept)';

  @override
  String get pitch2 => 'Pitch…';

  @override
  String get pitchSpeedKept => 'Pitch (speed kept)';

  @override
  String get volume => 'Volume…';

  @override
  String get volumeOfSelection => 'Volume of selection';

  @override
  String get fadeIn => 'Fade in…';

  @override
  String get fadeIn2 => 'Fade in';

  @override
  String get fadeOut => 'Fade out…';

  @override
  String get fadeOut2 => 'Fade out';

  @override
  String get pausePreview => 'Pause preview';

  @override
  String get playPreview => 'Play preview';

  @override
  String get aOriginal => 'A  original';

  @override
  String get bEdited => 'B  edited';

  @override
  String get apply => 'Apply';

  @override
  String get dragToSelectTapToMove =>
      'Drag to select · tap to move the cursor · pinch or Ctrl+wheel to zoom · wheel to scroll · Space = play, Del = cut, Ctrl+Z / Ctrl+Y = undo / redo';

  @override
  String get keysLocalOnly =>
      'Keys are read only from this local file (never stored in the app or the repo). See README → Online services.';

  @override
  String boostMayClip(Object db) {
    return 'Boost of $db dB may clip – lower the preamp. ';
  }

  @override
  String get limiterNote => '(A limiter catches peaks on Windows.)';

  @override
  String editedVsOriginal(Object a, Object b) {
    return 'Edited $a  ·  original $b';
  }

  @override
  String oauthConnected(Object service) {
    return 'Connected to $service';
  }

  @override
  String get oauthFailed => 'Login failed';

  @override
  String get oauthCloseTab => 'You can close this tab and go back to Prism.';

  @override
  String get oauthWrongState => 'Wrong state';

  @override
  String decade(Object year) {
    return '${year}s';
  }

  @override
  String connectedAsWithDetail(Object name, Object detail) {
    return 'Connected as $name ($detail)';
  }

  @override
  String get langSystem => 'System language';

  @override
  String get langTitle => 'Language';

  @override
  String get langEnglish => 'English';

  @override
  String get langRussian => 'Русский';

  @override
  String get smartMostPlayed => 'Most played';

  @override
  String get smartRecentlyAdded => 'Recently added';

  @override
  String get smartForgottenGems => 'Forgotten gems';

  @override
  String get eqPresetFlat => 'Flat';

  @override
  String get eqPresetCustom => 'Custom';

  @override
  String get eqPresetBassBoost => 'Bass Boost';

  @override
  String get eqPresetVocal => 'Vocal';

  @override
  String get eqPresetTreble => 'Treble';

  @override
  String get eqPresetRock => 'Rock';

  @override
  String get eqPresetElectronic => 'Electronic';

  @override
  String get eqPresetPop => 'Pop';

  @override
  String get eqPresetHipHop => 'Hip-Hop';

  @override
  String get eqPresetJazz => 'Jazz';

  @override
  String get eqPresetClassical => 'Classical';

  @override
  String get eqPresetAcoustic => 'Acoustic';

  @override
  String get eqPresetSpeech => 'Speech';

  @override
  String get trayShow => 'Show Prism';

  @override
  String get trayQuit => 'Quit';

  @override
  String hoursValue(Object h) {
    return '$h h';
  }

  @override
  String get edTabEdit => 'Edit';

  @override
  String get edTabSegment => 'Segment';

  @override
  String get edTabQuick => 'Quick';

  @override
  String get edExport => 'Export';

  @override
  String get edRippleDelete => 'Ripple delete';

  @override
  String get edDeleteGap => 'Delete, leave a gap';

  @override
  String get edDuplicate => 'Duplicate';

  @override
  String get edLoopN => 'Loop…';

  @override
  String get edLoopTitle => 'Repeat the selection';

  @override
  String get edReverse => 'Reverse';

  @override
  String get edMerge => 'Merge songs…';

  @override
  String get edMergeTitle => 'Add to the end';

  @override
  String edAddN(Object n) {
    return 'Add $n';
  }

  @override
  String get edAutoTrim => 'Auto-trim silence';

  @override
  String get edRemoveSilence => 'Remove silence inside';

  @override
  String get edNormalize => 'Normalize peaks';

  @override
  String get edLoudness => 'Match loudness…';

  @override
  String get edLoudnessTitle => 'Loudness target';

  @override
  String get edNothingToDo => 'Nothing to do here';

  @override
  String get edRingtone => 'Save as ringtone';

  @override
  String get edRingtoneSet => 'Set as ringtone';

  @override
  String get edRingtoneDone => 'Ringtone set';

  @override
  String get edRingtoneAllow =>
      'Allow Prism to change system settings, then tap again';

  @override
  String get edRingtoneSave => 'Save ringtone';

  @override
  String get edMakingRingtone => 'Making the ringtone…';

  @override
  String get edRenderingPreset => 'Rendering the live preset…';

  @override
  String get edRenderingPreview => 'Rendering preview…';

  @override
  String get edLoopSel => 'Loop selection (L)';

  @override
  String get edFollow => 'Follow the playhead';

  @override
  String get edSnapZero => 'Snap to zero crossings';

  @override
  String get edSnapBeats => 'Snap to beats';

  @override
  String get edSnapSilence => 'Snap to silence';

  @override
  String get edZoomIn => 'Zoom in (+)';

  @override
  String get edZoomOut => 'Zoom out (-)';

  @override
  String edSegmentN(Object n, Object total) {
    return 'Segment $n of $total';
  }

  @override
  String get edRamp => 'Gradual speed change';

  @override
  String get edRampTo => 'Speed at the end';

  @override
  String get edVolume => 'Volume';

  @override
  String get edCrossfadeNext => 'Crossfade into the next';

  @override
  String get edCurve => 'Fade curve';

  @override
  String get edCurveLinear => 'Linear';

  @override
  String get edCurveSmooth => 'Smooth';

  @override
  String get edCurveS => 'S-curve';

  @override
  String get edCurveFast => 'Fast start';

  @override
  String get edCurveSlow => 'Slow start';

  @override
  String get edEq => 'Equalizer';

  @override
  String get edMid => 'Mid';

  @override
  String get edHigh => 'High';

  @override
  String get edGate => 'Noise gate';

  @override
  String get edGateHint => 'Mutes everything quieter than the level';

  @override
  String get edGateLevel => 'Level';

  @override
  String get edVbr => 'Variable bitrate (VBR)';

  @override
  String edVbrQuality(Object q) {
    return 'Quality $q (0 is best, 9 is smallest)';
  }

  @override
  String edBitrate(Object kbps) {
    return '$kbps kbps';
  }

  @override
  String edWavBits(Object bits) {
    return '$bits-bit';
  }

  @override
  String edFlacLevel(Object n) {
    return 'Compression $n';
  }

  @override
  String get edApplyEq => 'Apply the global equalizer';

  @override
  String get edKeepTags => 'Keep tags and cover';

  @override
  String get edKeepCover => 'Keep cover';

  @override
  String get edOverwrite => 'Overwrite the original (a backup is kept)';

  @override
  String edOverwriteDone(Object path) {
    return 'Original replaced. Backup: $path';
  }

  @override
  String edOverwriteUnsupported(Object ext) {
    return 'Can\'t overwrite $ext files, save as a new track instead';
  }

  @override
  String edOverwriteFailed(Object e) {
    return 'Could not replace the file, the original was put back: $e';
  }

  @override
  String get edHelpDesktop =>
      'Drag to select, drag an edge to adjust, click to move the cursor, double-click selects a segment. Wheel scrolls, Ctrl+wheel zooms. Space play, S split, Del ripple delete, Shift+Del delete with gap, T trim, R reverse, L loop, B A/B, Ctrl+D duplicate, Ctrl+A select all, Ctrl+E export, Ctrl+Z / Ctrl+Y undo / redo, arrows move the cursor, + - 0 zoom.';

  @override
  String get edHelpTouch =>
      'Drag to select, drag an edge to adjust, tap to move the cursor, double-tap selects a segment. Pinch to zoom, two fingers to scroll. Hold a block in the row below the waveform to move it.';

  @override
  String lyricsError(Object e) {
    return 'Lyrics error: $e';
  }

  @override
  String get lyricsOffsetTitle => 'Lyrics timing';

  @override
  String get lyricsOffsetHint =>
      'Plus shows the lines earlier, minus later. Saved for this song.';

  @override
  String get vizRibbon => 'Ribbon';

  @override
  String get vizParticles => 'Particles';

  @override
  String get vizGlow => 'Glow';

  @override
  String get vizSensitivity => 'Sensitivity';

  @override
  String get vizLowPower => 'Low-power visualizer';

  @override
  String get vizLowPowerHint => '30 frames per second and fewer details';

  @override
  String get vizLive => 'Live spectrum';

  @override
  String get vizLiveHint =>
      'Reacts to what is actually playing, also streams and EQ. Android asks for the microphone permission for this; Prism records nothing.';

  @override
  String get vizLiveRefused =>
      'Permission refused, the visualizer keeps analysing the file';

  @override
  String get metaTitle => 'Fix song info';

  @override
  String get metaFix => 'Fix info…';

  @override
  String get metaFixAlbum => 'Fix info of all these songs';

  @override
  String get metaSearchAll => 'Search all';

  @override
  String get metaSaveAll => 'Save all';

  @override
  String get metaSave => 'Save to file';

  @override
  String get metaResearch => 'Search again';

  @override
  String get metaNothingFound =>
      'Nothing found. Try other words above, or type the info by hand.';

  @override
  String get metaCandidates => 'Found';

  @override
  String get metaUseCover => 'Use this cover';

  @override
  String metaSavedN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count songs, backups of the originals were kept',
      one: 'Saved $count song, a backup of the original was kept',
    );
    return '$_temp0';
  }

  @override
  String metaSaveFailed(Object e) {
    return 'Could not save: $e';
  }

  @override
  String get yandexChanged =>
      'Yandex Music answered in an unexpected way. It has no official API, so this can break at any time. Export the playlist to CSV or JSON and import the file instead.';

  @override
  String get yandexNeedsToken =>
      'Yandex Music needs your token for this: Settings → Online services.';

  @override
  String get yandexPlaylist => 'Yandex Music playlist';

  @override
  String get yandexLikes => 'Liked songs (Yandex Music)';

  @override
  String get yandexLabel => 'Yandex Music';

  @override
  String get yandexDescribe =>
      'Experimental, no official API. Public links, your playlists and likes with your token. Song names only, no audio.';

  @override
  String get yandexTokenTitle => 'Your Yandex Music token';

  @override
  String get yandexTokenSteps =>
      'Only needed for your own playlists and likes; public links work without it.\n\n1. Open the guide below.\n2. Follow its browser steps while signed in to your Yandex account.\n3. Copy the token and paste it here.';

  @override
  String get yandexOpenGuide => 'Open the guide (community project)';

  @override
  String get yandexToken => 'Token';

  @override
  String get yandexTokenPrivate =>
      'The token gives access to your Yandex account: don\'t share it. Prism keeps it in the system\'s secure storage and sends it only to api.music.yandex.net.';

  @override
  String get yandexTermsTitle => 'Yandex Music – unofficial, import only';

  @override
  String get yandexTermsText =>
      'Yandex has no public API. Prism reads song names through the private one its apps use (documented by the community project yandex-music-api), which can change or stop without warning and answers only from some countries. Public links are read when you import them; your account stays off until you turn it on. For personal use. Prism never downloads or plays Yandex audio. If it stops working, import a CSV or JSON export instead.';

  @override
  String regionBlocked(Object service) {
    return '$service isn\'t available from your country or network (blocked by the service). Export the playlist to CSV or JSON and import the file instead.';
  }

  @override
  String get setUpYandexToken => 'Paste token';

  @override
  String get shareTitle => 'Share this playlist';

  @override
  String shareHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Send this code to a friend. It holds the names of $count songs, no audio and no file paths; Prism finds them in their library or enabled services.',
      one:
          'Send this code to a friend. It holds the name of $count song, no audio and no file paths; Prism finds it in their library or enabled services.',
    );
    return '$_temp0';
  }

  @override
  String get shareLong =>
      'This code is long and some chat apps may cut it. If so, send the file instead.';

  @override
  String get shareSaveFile => 'Save .liner file';

  @override
  String get shareSaved => 'File saved';

  @override
  String get shareButton => 'Share';

  @override
  String get shareBadCode =>
      'This code is damaged or incomplete. Ask for it again, or for the .liner file.';

  @override
  String get shareNewerVersion =>
      'This code was made by a newer Prism. Update the app to open it.';

  @override
  String get shareTooBig => 'This playlist is too big to open.';

  @override
  String get shareEmpty => 'There are no songs in this code.';

  @override
  String get shareDefaultName => 'Shared playlist';

  @override
  String get shareRecognized => 'A shared playlist';

  @override
  String orderSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get orderMoveTop => 'Move to top';

  @override
  String get orderMoveBottom => 'Move to bottom';

  @override
  String get orderSelect => 'Select several';

  @override
  String get orderSort => 'Sort';

  @override
  String get orderCustom => 'My order';

  @override
  String orderSortedHint(Object by) {
    return 'Sorted by: $by. Your own order is kept.';
  }

  @override
  String get orderBackToCustom => 'Back to my order';

  @override
  String get orderKeepThis => 'Make this my order';

  @override
  String get statsNewVsRepeat => 'New and repeat';

  @override
  String statsNewVsRepeatNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs heard for the first time',
      one: '$count song heard for the first time',
    );
    return '$_temp0';
  }

  @override
  String get statsNewPlays => 'Discoveries';

  @override
  String get statsRepeatPlays => 'Songs you knew';

  @override
  String get statsStoryPlay => 'Play as a story';

  @override
  String get statsSaveImage => 'Save this card as a picture';

  @override
  String get statsImageSaved => 'Picture saved';

  @override
  String statsMinutesUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$_temp0';
  }

  @override
  String statsDaysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days in a row',
      one: 'day in a row',
    );
    return '$_temp0';
  }

  @override
  String get statsWrappedNew => 'You discovered';

  @override
  String statsNewSongsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'new songs',
      one: 'new song',
    );
    return '$_temp0';
  }

  @override
  String get bgMesh => 'Mesh gradient';

  @override
  String get bgMeshDesc => 'Soft colors slowly flowing into each other.';

  @override
  String get bgAurora => 'Aurora';

  @override
  String get bgAuroraDesc => 'Curtains of light moving across a dark sky.';

  @override
  String get bgBlobs => 'Liquid blobs';

  @override
  String get bgBlobsDesc =>
      'Shapes that merge and split like a lava lamp, swelling with the bass.';

  @override
  String get bgGradient => 'Gradient';

  @override
  String get bgGradientDesc =>
      'A still gradient. Pick a preset below. Uses no power once drawn.';

  @override
  String get bgStarfield => 'Starfield';

  @override
  String get bgStarfieldDesc => 'Flying through the stars, faster on the bass.';

  @override
  String get bgRain => 'Rain';

  @override
  String get bgRainDesc => 'Thin falling rain. The mouse is the wind.';

  @override
  String get bgSnow => 'Snow';

  @override
  String get bgSnowDesc => 'Flakes drifting down in layers.';

  @override
  String get bgGrain => 'Film grain';

  @override
  String get bgGrainDesc => 'A quiet tinted gradient with moving film grain.';

  @override
  String get bgImage => 'My picture';

  @override
  String get bgImageDesc =>
      'Your own picture behind the app. Blur and darken it below.';

  @override
  String get bgVideo => 'My video';

  @override
  String get bgVideoDesc =>
      'The first 30 seconds of your video as a silent loop at 12 frames per second.';

  @override
  String get bgChooseImage => 'Choose a picture…';

  @override
  String get bgChooseVideo => 'Choose a video…';

  @override
  String get bgPreparingVideo => 'Preparing the video…';

  @override
  String get bgVideoFailed => 'Could not read this video on this device.';

  @override
  String get bgPresets => 'Presets';

  @override
  String get bgDim => 'Darken';

  @override
  String get bgParallax => 'Parallax';

  @override
  String get bgParallaxHint => 'The background shifts a little with the mouse';

  @override
  String get bgBatterySaver => 'Battery saver';

  @override
  String get bgBatterySaverHint =>
      '20 frames per second, fewer details, no blur or frosted panels';

  @override
  String get bgPresetDusk => 'Dusk';

  @override
  String get bgPresetOcean => 'Ocean';

  @override
  String get bgPresetForest => 'Forest';

  @override
  String get bgPresetEmber => 'Ember';

  @override
  String get bgPresetIce => 'Ice';

  @override
  String get bgPresetGraphite => 'Graphite';

  @override
  String get bgPresetRose => 'Rose';

  @override
  String get bgPresetNight => 'Night';

  @override
  String get bgDensity => 'Density';

  @override
  String get bgSize => 'Size';

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateAuto => 'Check when the app starts';

  @override
  String get updateAutoHint => 'Asks GitHub once a day for the latest version';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String updateNone(Object version) {
    return 'You have the latest version ($version)';
  }

  @override
  String updateFailed(Object reason) {
    return 'Could not check for updates: $reason';
  }

  @override
  String updateAvailable(Object version) {
    return 'Version $version is out';
  }

  @override
  String get updateHowTo =>
      'Download the new installer or APK and install it over this one. Your library and settings stay.';

  @override
  String get updateOpen => 'Open download page';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyNoLocationTitle => 'Prism does not read your location';

  @override
  String get privacyNoLocationText =>
      'No analytics, no telemetry, no ads, no crash reports. No device id. Prism has no account or server of its own.';

  @override
  String get privacyPermsTitle => 'Android permissions';

  @override
  String get privacyPermMusic => 'Music and audio files';

  @override
  String get privacyPermMusicWhy =>
      'Reads your music. Asked when you add a folder.';

  @override
  String get privacyPermPlayback => 'Background playback';

  @override
  String get privacyPermPlaybackWhy =>
      'Keeps music playing with the screen off.';

  @override
  String get privacyPermNotify => 'Notifications';

  @override
  String get privacyPermNotifyWhy =>
      'Only the player notification with its buttons.';

  @override
  String get privacyPermInternet => 'Internet and network state';

  @override
  String get privacyPermInternetWhy =>
      'For the requests listed below, and to know whether you are online.';

  @override
  String get privacyPermMic => 'Microphone (live visualizer only)';

  @override
  String get privacyPermMicWhy =>
      'Android files its visualizer under the microphone. Asked only when you turn it on. Prism records nothing.';

  @override
  String get privacyPermRingtone => 'Change system settings (ringtones only)';

  @override
  String get privacyPermRingtoneWhy =>
      'Sets a ringtone made in the editor. You allow it on a system screen when you use it.';

  @override
  String get privacyPermsFooter =>
      'Never asked for: location, Bluetooth, Wi-Fi details, phone state, contacts, accounts, advertising id.';

  @override
  String get privacyWindowsTitle => 'Windows';

  @override
  String get privacyWindowsText =>
      'Needs no special permissions and does not use the Windows location API. Before version 1.2 a library started the Windows location service at launch, so Windows could list Prism as using location. Prism never read or sent the result, and that library is gone.';

  @override
  String get privacySentTitle => 'What leaves this device';

  @override
  String get privacySentFooter =>
      'Every server sees your IP address, like with any internet request. Prism never looks up where that address is.';

  @override
  String get privacySentUpdates => 'Update check: GitHub';

  @override
  String get privacySentUpdatesWhat =>
      'Sends the app version. Automatic, can be turned off in About.';

  @override
  String get privacySentInfo => 'Missing info: Apple, Deezer';

  @override
  String get privacySentInfoWhat =>
      'Sends song title and artist. Automatic, can be turned off in Library.';

  @override
  String get privacySentLyrics => 'Lyrics: LRCLIB';

  @override
  String get privacySentLyricsWhat =>
      'Sends title, artist, album and length of the song you open lyrics for.';

  @override
  String get privacySentFonts => 'Font: Google Fonts';

  @override
  String get privacySentFontsWhat =>
      'Downloads the app font once. Sends nothing about you or your music.';

  @override
  String get privacySentImport =>
      'Import: Spotify, YouTube, SoundCloud, Deezer, Apple Music, Yandex Music';

  @override
  String get privacySentImportWhat =>
      'Only when you import: the link you gave. A copied link stays on this device until you tap Import.';

  @override
  String get privacySentOnline => 'Online songs: YouTube, SoundCloud';

  @override
  String get privacySentOnlineWhat =>
      'If you turn them on: song searches and the songs you play.';

  @override
  String get privacySentFixer =>
      'Song info fixer: MusicBrainz, Cover Art Archive, Apple, AcoustID';

  @override
  String get privacySentFixerWhat =>
      'When you use it: title, artist, album. AcoustID only with your own key.';

  @override
  String get privacySentTogether =>
      'Listen together: public servers or your Wi-Fi';

  @override
  String get privacySentTogetherWhat =>
      'While in a session: what is playing and the name you typed. Without a name you appear as “Someone”, never your computer name.';

  @override
  String get privacySentDiscord => 'Discord status';

  @override
  String get privacySentDiscordWhat =>
      'If Discord runs on this computer: the song you play.';

  @override
  String get privacyFullText => 'Read the full privacy notes';

  @override
  String get privacyContinue => 'Continue';

  @override
  String get vizLiveAskTitle => 'Android will ask about the microphone';

  @override
  String get vizLiveAskText =>
      'The live visualizer uses the Visualizer API, which Android files under the microphone. Prism only reads the sound it plays itself. It records nothing and sends nothing.';

  @override
  String get removeFromPrism => 'Remove from Prism';

  @override
  String get removeFromPrismHint => 'The file stays on your disk';

  @override
  String removeFromPrismAsk(String title) {
    return 'Remove “$title” from Prism?';
  }

  @override
  String get removeFromPrismText =>
      'It leaves your library, playlists, favorites and stats in Prism. The file stays on your disk and rescans skip it. You can bring it back in Settings → Library.';

  @override
  String get removeFromPrismDone =>
      'Removed from Prism. The file is still on your disk.';

  @override
  String get undoAction => 'Undo';

  @override
  String get removedSongs => 'Removed songs';

  @override
  String removedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs hidden from Prism',
      one: '$count song hidden from Prism',
      zero: 'Nothing removed',
    );
    return '$_temp0';
  }

  @override
  String get removedSongsHelp =>
      'Their files are still on your disk. Restore puts a song back in your library with a scan, which starts right away. Old stats and playlist places do not come back.';

  @override
  String get restoreAction => 'Restore';

  @override
  String get importSupported =>
      'Spotify, YouTube, SoundCloud, Yandex Music, Apple Music or Deezer. Public links work with no account.';

  @override
  String get importFileOrDrop => 'Or drop a file here: CSV, JSON, M3U, .liner';

  @override
  String get importFileHint => 'Or pick a file: CSV, JSON, M3U, .liner';

  @override
  String get importDropHere => 'Drop to import';

  @override
  String get importClipboardAsk => 'Import this playlist?';

  @override
  String get importRecent => 'Recent imports';

  @override
  String get importResync => 'Sync again';

  @override
  String get importSynced => 'Syncing with the source';

  @override
  String get importAccept => 'Right song';

  @override
  String importAcceptAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Accept all $count',
      one: 'Accept $count',
    );
    return '$_temp0';
  }

  @override
  String get importReview => 'Review';

  @override
  String get importReviewEmpty =>
      'Nothing to check. Songs Prism is unsure about will wait here.';

  @override
  String importReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs to check',
      one: '$count song to check',
    );
    return '$_temp0';
  }

  @override
  String get importReviewHint => 'One tap to accept or fix';

  @override
  String get importAdvanced => 'Advanced: connect an account';

  @override
  String get importAdvancedHint =>
      'Optional. Only for private playlists, liked songs and long Spotify lists.';

  @override
  String get importNotConnected => 'Not connected';

  @override
  String get importOneScreenHint => 'From a link or a file, on one screen';

  @override
  String get importOnlyLibrarySearched =>
      'Only your library was searched. Prism can look for the rest on YouTube if you turn it on.';

  @override
  String get importFindOnYoutube => 'Find the rest on YouTube';

  @override
  String get importSearchAgain => 'Search again for songs not found';

  @override
  String get importStepsSpotify =>
      'For your private playlists and liked songs. Public links already work.\n1. Open developer.spotify.com/dashboard and create an app with the Web API.\n2. Add the redirect URI http://127.0.0.1:43821/callback.\n3. Copy the Client ID.\n4. In Online services tap Create file, paste it as spotify.clientId, tap Reload, then Connect.';

  @override
  String get importStepsYoutube =>
      'For your private playlists and liked videos. Public links already work.\n1. Open console.cloud.google.com and make a project with the YouTube Data API v3.\n2. Add yourself as a test user on the OAuth consent screen.\n3. Create an OAuth client of type Desktop app.\n4. In Online services tap Create file, paste youtube.oauthClientId and youtube.oauthClientSecret, tap Reload, then Connect.';

  @override
  String get importStepsSoundcloud =>
      'SoundCloud links need this, or export the playlist to a file.\n1. Open soundcloud.com/you/apps and register an app. SoundCloud may need to approve it.\n2. Add the redirect URI http://127.0.0.1:43822/callback.\n3. In Online services tap Create file, paste soundcloud.clientId and soundcloud.clientSecret, tap Reload.';

  @override
  String get importStepsYandex =>
      'For your own playlists and liked songs. Public links already work where Yandex answers.\n1. Open Online services and turn on Yandex Music.\n2. Tap Connect and follow the steps to get your token.\n3. Paste the token. It stays in the secure storage of this device.';

  @override
  String get importErrorOffline =>
      'You seem to be offline. Check your connection and try again.';

  @override
  String importErrorSlowDown(String service) {
    return '$service is asking to slow down. Wait a few minutes and try again.';
  }

  @override
  String importErrorServer(String service) {
    return '$service has problems right now. Try again later.';
  }

  @override
  String get importErrorPrivate =>
      'This playlist is private or was deleted. Make it public, or export it to a file and import that.';

  @override
  String importErrorRegion(String service) {
    return '$service does not answer from your country or network. Export the playlist to a CSV or JSON file and import that.';
  }

  @override
  String importErrorAccount(String service) {
    return 'This list is private, so $service needs your account. Connect it, or export a file.';
  }

  @override
  String importErrorNeedsKey(String service) {
    return '$service links need a free key, or export the playlist to a file.';
  }

  @override
  String importErrorCantRead(String service) {
    return 'Could not read this $service page. It may have changed. Export the playlist to a file and import that.';
  }

  @override
  String importErrorFile(String problem) {
    return '$problem Prism reads CSV, JSON, M3U and .liner files.';
  }

  @override
  String importErrorFileGone(String path) {
    return 'The file is no longer at $path. Pick it again.';
  }

  @override
  String get importErrorUnknown =>
      'Something went wrong while reading this. Try exporting the playlist to a file.';

  @override
  String importSkipNotFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skip $count not found',
      one: 'Skip $count not found',
    );
    return '$_temp0';
  }
}
