// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String nSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      many: '$count песен',
      few: '$count песни',
      one: '$count песня',
    );
    return '$_temp0';
  }

  @override
  String nAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count альбома',
      many: '$count альбомов',
      few: '$count альбома',
      one: '$count альбом',
    );
    return '$_temp0';
  }

  @override
  String nPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count плейлиста',
      many: '$count плейлистов',
      few: '$count плейлиста',
      one: '$count плейлист',
    );
    return '$_temp0';
  }

  @override
  String nFolders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count папки',
      many: '$count папок',
      few: '$count папки',
      one: '$count папка',
    );
    return '$_temp0';
  }

  @override
  String nDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String nTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раза',
      many: '$count раз',
      few: '$count раза',
      one: '$count раз',
    );
    return '$_temp0';
  }

  @override
  String nPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count прослушивания',
      many: '$count прослушиваний',
      few: '$count прослушивания',
      one: '$count прослушивание',
    );
    return '$_temp0';
  }

  @override
  String nDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дубликата',
      many: '$count дубликатов',
      few: '$count дубликата',
      one: '$count дубликат',
    );
    return '$_temp0';
  }

  @override
  String nGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count группы',
      many: '$count групп',
      few: '$count группы',
      one: '$count группа',
    );
    return '$_temp0';
  }

  @override
  String nCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count копии',
      many: '$count копий',
      few: '$count копии',
      one: '$count копия',
    );
    return '$_temp0';
  }

  @override
  String nNewArtists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новых исполнителя',
      many: '$count новых исполнителей',
      few: '$count новых исполнителя',
      one: '$count новый исполнитель',
    );
    return '$_temp0';
  }

  @override
  String nListening(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слушают',
      many: '$count слушают',
      few: '$count слушают',
      one: '$count слушает',
    );
    return '$_temp0';
  }

  @override
  String undoFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Вернуть $count песни как было',
      many: 'Вернуть $count песен как было',
      few: 'Вернуть $count песни как было',
      one: 'Вернуть $count песню как было',
    );
    return '$_temp0';
  }

  @override
  String foundInfoFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдены данные для $count песни',
      many: 'Найдены данные для $count песен',
      few: 'Найдены данные для $count песен',
      one: 'Найдены данные для $count песни',
    );
    return '$_temp0';
  }

  @override
  String skipDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пропустить $count дубликата',
      many: 'Пропустить $count дубликатов',
      few: 'Пропустить $count дубликата',
      one: 'Пропустить $count дубликат',
    );
    return '$_temp0';
  }

  @override
  String matchNSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сопоставить $count песни',
      many: 'Сопоставить $count песен',
      few: 'Сопоставить $count песни',
      one: 'Сопоставить $count песню',
    );
    return '$_temp0';
  }

  @override
  String createPlaylistN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создать плейлист ($count песни)',
      many: 'Создать плейлист ($count песен)',
      few: 'Создать плейлист ($count песни)',
      one: 'Создать плейлист ($count песня)',
    );
    return '$_temp0';
  }

  @override
  String notMeasuredYet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни ещё не измерены',
      many: '$count песен ещё не измерены',
      few: '$count песни ещё не измерены',
      one: '$count песня ещё не измерена',
    );
    return '$_temp0';
  }

  @override
  String songsNotInLibrary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни нет в этой библиотеке',
      many: '$count песен нет в этой библиотеке',
      few: '$count песен нет в этой библиотеке',
      one: '$count песни нет в этой библиотеке',
    );
    return '$_temp0';
  }

  @override
  String readingNAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Чтение $count альбома…',
      many: 'Чтение $count альбомов…',
      few: 'Чтение $count альбомов…',
      one: 'Чтение $count альбома…',
    );
    return '$_temp0';
  }

  @override
  String readingNPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Чтение $count плейлиста…',
      many: 'Чтение $count плейлистов…',
      few: 'Чтение $count плейлистов…',
      one: 'Чтение $count плейлиста…',
    );
    return '$_temp0';
  }

  @override
  String previewNPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Просмотр · $count плейлиста',
      many: 'Просмотр · $count плейлистов',
      few: 'Просмотр · $count плейлиста',
      one: 'Просмотр · $count плейлист',
    );
    return '$_temp0';
  }

  @override
  String songsFromOrigin(int count, Object origin) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни из $origin',
      many: '$count песен из $origin',
      few: '$count песни из $origin',
      one: '$count песня из $origin',
    );
    return '$_temp0';
  }

  @override
  String musicFoldersIntro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count песни. Prism читает файлы mp3, flac, m4a, ogg и wav в этих папках.',
      many:
          '$count песен. Prism читает файлы mp3, flac, m4a, ogg и wav в этих папках.',
      few:
          '$count песни. Prism читает файлы mp3, flac, m4a, ogg и wav в этих папках.',
      one:
          '$count песня. Prism читает файлы mp3, flac, m4a, ogg и wav в этих папках.',
    );
    return '$_temp0';
  }

  @override
  String versionAndSongs(int count, Object version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Версия $version · $count песни в библиотеке',
      many: 'Версия $version · $count песен в библиотеке',
      few: 'Версия $version · $count песни в библиотеке',
      one: 'Версия $version · $count песня в библиотеке',
    );
    return '$_temp0';
  }

  @override
  String minutesValue(Object m) {
    return '$m мин';
  }

  @override
  String hoursMinutesValue(Object h, Object m) {
    return '$h ч $m мин';
  }

  @override
  String secondsValue(Object s) {
    return '$s с';
  }

  @override
  String dbValue(Object sign, Object value) {
    return '$sign$value дБ';
  }

  @override
  String stValue(Object sign, Object value) {
    return '$sign$value пт';
  }

  @override
  String get notAValidJsonFile => 'Файл не в формате JSON';

  @override
  String get themeFileMustContainAJson =>
      'В файле темы должен быть объект JSON';

  @override
  String unknownFileFormat(Object format) {
    return 'Неизвестный формат файла «$format»';
  }

  @override
  String themeWasMadeWithANewer(Object v) {
    return 'Тема создана в более новой версии Prism (v$v)';
  }

  @override
  String get missingThemeObject => 'Нет объекта «theme»';

  @override
  String invalidThemeValues(Object e) {
    return 'Неверные значения темы: $e';
  }

  @override
  String get audioEffectsAreNotAvailableOn =>
      'Звуковые эффекты недоступны на этой платформе.';

  @override
  String get equalizer => 'Эквалайзер';

  @override
  String get resetToFlat => 'Сбросить';

  @override
  String get saveAsPreset => 'Сохранить как пресет';

  @override
  String get saveEqPreset => 'Сохранить пресет эквалайзера';

  @override
  String get myPreset => 'Мой пресет';

  @override
  String boostOfDbMayClipLower(Object db) {
    return 'Усиление на $db дБ может вызвать перегруз — уменьшите предусиление.';
  }

  @override
  String get aLimiterCatchesPeaksOnWindows =>
      '(В Windows пики срезает лимитер.)';

  @override
  String preset(Object name) {
    return 'пресет «$name»';
  }

  @override
  String get preamp => 'Предусиление';

  @override
  String get bassBoost => 'Усиление басов';

  @override
  String get xOff => 'Выкл.';

  @override
  String get xOn => 'Вкл.';

  @override
  String get cover => 'Обложка';

  @override
  String get theCurrentCoverBlurredAndGrey =>
      'Текущая обложка, размытая и серая. Почти не тратит энергию.';

  @override
  String get matrix => 'Матрица';

  @override
  String get fallingSymbolsTheyLightUpAnd =>
      'Падающие символы. Загораются и огибают курсор, клик запускает ударную волну.';

  @override
  String get constellation => 'Созвездие';

  @override
  String get driftingStarsJoinedByLinesThe =>
      'Плывущие звёзды, соединённые линиями. Курсор притягивает их, клик разбрасывает.';

  @override
  String get ripple => 'Рябь';

  @override
  String get aGridOfDotsLikeA =>
      'Сетка точек как поверхность воды. Курсор оставляет волны, басы создают капли.';

  @override
  String get katakana => 'Катакана';

  @override
  String get x0And1 => '0 и 1';

  @override
  String get hex => 'Hex';

  @override
  String get letters => 'Буквы';

  @override
  String get musicNotes => 'Ноты';

  @override
  String get myOwnText => 'Свой текст';

  @override
  String get dots => 'Точки';

  @override
  String get dashes => 'Чёрточки';

  @override
  String get plusSigns => 'Плюсы';

  @override
  String get trailLength => 'Длина следа';

  @override
  String get lineLength => 'Длина линий';

  @override
  String get waveWidth => 'Ширина волны';

  @override
  String get amountOfRain => 'Плотность дождя';

  @override
  String get numberOfStars => 'Число звёзд';

  @override
  String get dotsPerArea => 'Плотность точек';

  @override
  String get symbolSize => 'Размер символов';

  @override
  String get starSize => 'Размер звёзд';

  @override
  String get dotSize => 'Размер точек';

  @override
  String get background => 'Фон';

  @override
  String get tryIt => 'Попробовать';

  @override
  String get symbols => 'Символы';

  @override
  String get yourSymbols => 'Ваши символы';

  @override
  String get anyLettersOrSymbolsEG =>
      'Любые буквы или символы, например ваше имя';

  @override
  String get shape => 'Форма';

  @override
  String get colors => 'Цвета';

  @override
  String get useTheThemeColors => 'Цвета темы';

  @override
  String get mainColor => 'Основной цвет';

  @override
  String get highlightColor => 'Цвет подсветки';

  @override
  String get look => 'Вид';

  @override
  String get brightness => 'Яркость';

  @override
  String get speed => 'Скорость';

  @override
  String get reactions => 'Реакции';

  @override
  String get clicksAlsoSendAWaveMusic =>
      'Клики тоже запускают волну. Для реакции на музыку каждая песня анализируется один раз, при первом запуске.';

  @override
  String get mouse => 'Мышь';

  @override
  String get music => 'Музыка';

  @override
  String get forEveryAnimatedBackground => 'Для всех анимированных фонов';

  @override
  String get strength => 'Сила';

  @override
  String get outOfFocus => 'Расфокус';

  @override
  String get frostedPanels => 'Матовые панели';

  @override
  String get panelsBlurWhatIsBehindThem => 'Панели размывают то, что под ними';

  @override
  String get solidPanels => 'Плотность панелей';

  @override
  String get keepTheCoverUnderneath => 'Оставить обложку под фоном';

  @override
  String get stopWhileTheMusicIsPaused => 'Останавливать на паузе';

  @override
  String get savesPower => 'Экономит энергию';

  @override
  String get framesPerSecond => 'Кадров в секунду';

  @override
  String get lowerSavesPower => 'Меньше — экономнее';

  @override
  String get screen => 'Экран';

  @override
  String reset(Object style) {
    return 'Сбросить: $style';
  }

  @override
  String get closeEsc => 'Закрыть (Esc)';

  @override
  String get moveTheMouseAndClick => 'Двигайте мышью и кликайте';

  @override
  String get watchOnYoutube => 'Смотреть на YouTube';

  @override
  String get openOnSoundcloud => 'Открыть в SoundCloud';

  @override
  String get findOnYoutube => 'Найти на YouTube';

  @override
  String get connectedToDiscord => 'Подключено к Discord';

  @override
  String connectedAs(Object user) {
    return 'Подключено: $user';
  }

  @override
  String get discordIsnTRunningItConnects =>
      'Discord не запущен. Подключится сам, когда вы его откроете.';

  @override
  String get discordDidnTAcceptThisApplication =>
      'Discord не принял этот Application ID.';

  @override
  String get oneSetupStepLeft => 'Остался один шаг настройки';

  @override
  String get connecting => 'Подключение…';

  @override
  String get discordStatus => 'Статус в Discord';

  @override
  String get songAlbumArtProgressLinksAnd =>
      'Песня, обложка, прогресс, ссылки и с кем вы слушаете';

  @override
  String get findAlbumArt => 'Искать обложки';

  @override
  String get sendsTitleAndArtistToApple =>
      'Отправляет название и исполнителя в открытый поиск Apple и Deezer. Discord не умеет показывать обложки с вашего ПК.';

  @override
  String get discordNeedsAnApplicationToShow =>
      'Для статуса Discord нужно приложение, и создать его может только вошедший пользователь. Один раз, 30 секунд: New Application → назовите Prism → Create → скопируйте Application ID. Prism сам возьмёт его из буфера обмена.';

  @override
  String get openTheDiscordPage => 'Открыть страницу Discord';

  @override
  String get applicationId => 'Application ID';

  @override
  String get useMyOwnApplication => 'Своё приложение';

  @override
  String get nothingPlaying => 'Ничего не играет';

  @override
  String get backToFullWindow => 'Вернуться в полное окно';

  @override
  String get miniPlayerAlwaysOnTop => 'Мини-плеер (поверх окон)';

  @override
  String get trackNotFound => 'Трек не найден';

  @override
  String get ffmpegIsNotAvailableWaveformAnd =>
      'FFmpeg недоступен — волна и экспорт отключены.';

  @override
  String get savingNewTrack => 'Сохранение нового трека…';

  @override
  String get exporting => 'Экспорт…';

  @override
  String get ffmpegIsNotAvailableOnThis => 'На этом устройстве нет FFmpeg';

  @override
  String ffmpegFailed(Object code, Object tail) {
    return 'Ошибка FFmpeg ($code):\n$tail';
  }

  @override
  String xEdit(Object title) {
    return '$title (правка)';
  }

  @override
  String couldNotDecodeAudio(Object tail) {
    return 'Не удалось декодировать звук:\n$tail';
  }

  @override
  String get pausedTheSearchServicesAreNot =>
      'Пауза: сервисы поиска не отвечают';

  @override
  String get prismNeedsPermissionToReadYour =>
      'Prism нужно разрешение на чтение музыки';

  @override
  String get settings => 'Настройки';

  @override
  String get chooseAMusicFolder => 'Выберите папку с музыкой';

  @override
  String get unknownArtist => 'Неизвестный исполнитель';

  @override
  String get unknownAlbum => 'Неизвестный альбом';

  @override
  String get xLibrary => 'Библиотека';

  @override
  String get sortSongs => 'Сортировка песен';

  @override
  String get title => 'Название';

  @override
  String get artist => 'Исполнитель';

  @override
  String get album => 'Альбом';

  @override
  String get recentlyAdded => 'Недавно добавленные';

  @override
  String get longestFirst => 'Сначала длинные';

  @override
  String get songs => 'Песни';

  @override
  String get albums => 'Альбомы';

  @override
  String get artists => 'Исполнители';

  @override
  String get folders => 'Папки';

  @override
  String get songsArtistsAlbums => 'Песни, исполнители, альбомы';

  @override
  String get songsArtistsAlbumsHereAndOnline =>
      'Песни, исполнители, альбомы — здесь и в сети';

  @override
  String get typeToSearchYourLibrary =>
      'Введите запрос для поиска в библиотеке';

  @override
  String get typeToSearchYourLibraryAnd =>
      'Введите запрос для поиска в библиотеке и в сети';

  @override
  String get yourLibrary => 'Ваша библиотека';

  @override
  String get nothingFoundInYourLibrary => 'В библиотеке ничего не найдено';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get play => 'Играть';

  @override
  String get shuffle => 'Перемешать';

  @override
  String get yourLibraryIsEmpty => 'Библиотека пуста';

  @override
  String get addAFolderWithMusicMp3 =>
      'Добавьте папку с музыкой (mp3, flac, m4a, ogg, wav).';

  @override
  String add(Object name) {
    return 'Добавить $name';
  }

  @override
  String get chooseFolder => 'Выбрать папку…';

  @override
  String lookingForMusicFiles(Object found) {
    return 'Поиск музыки… файлов: $found';
  }

  @override
  String readingTags(Object done, Object total) {
    return 'Чтение тегов $done / $total';
  }

  @override
  String error(Object e) {
    return 'Ошибка: $e';
  }

  @override
  String get playNext => 'Играть следующей';

  @override
  String get playingNext => 'Будет следующей';

  @override
  String get addToQueue => 'В очередь';

  @override
  String get addedToQueue => 'Добавлено в очередь';

  @override
  String get removeFromFavorites => 'Убрать из избранного';

  @override
  String get addToFavorites => 'В избранное';

  @override
  String get addToPlaylist => 'В плейлист…';

  @override
  String get removeOfflineCopy => 'Удалить офлайн-копию';

  @override
  String get saveForOffline => 'Сохранить офлайн';

  @override
  String get personalUseOnlySeeSettingsOnline =>
      'Только для личного использования — см. Настройки → Онлайн-сервисы';

  @override
  String get offlineCopyRemoved => 'Офлайн-копия удалена';

  @override
  String get savingForOffline => 'Сохранение офлайн…';

  @override
  String openOn(Object service) {
    return 'Открыть в $service';
  }

  @override
  String get theWeb => 'браузере';

  @override
  String get xEdit2 => 'Редактировать…';

  @override
  String get trimCutSpeedPitchFadesOriginal =>
      'Обрезка, вырезание, скорость, тон, фейды — оригинал не меняется';

  @override
  String get editTags => 'Изменить теги…';

  @override
  String get removeFromThisPlaylist => 'Убрать из этого плейлиста';

  @override
  String get goToAlbum => 'К альбому';

  @override
  String get goToArtist => 'К исполнителю';

  @override
  String get more => 'Ещё';

  @override
  String notSynced(Object source) {
    return 'Без синхронизации · $source';
  }

  @override
  String get sameFile => 'тот же файл';

  @override
  String get linkedVideo => 'привязанное видео';

  @override
  String get notInYourLibraryTurnOn =>
      'Нет в библиотеке. Включите воспроизведение YouTube или SoundCloud, чтобы искать в сети.';

  @override
  String isMissingIn(Object what, Object path, Object error) {
    return 'В $path не хватает: $what.$error';
  }

  @override
  String get youtubeApikeyOrTurnOnThe =>
      'youtube.apiKey (или включите YouTube-экстрактор)';

  @override
  String pausedSongsLeft(Object left) {
    return 'Пауза — осталось песен: $left.';
  }

  @override
  String get importedPlaylist => 'Импортированный плейлист';

  @override
  String portIsBusyCloseTheOther(Object port) {
    return 'Порт $port занят. Закройте программу, которая его использует, или измените redirectPort в файле настроек.';
  }

  @override
  String get couldNotOpenTheBrowser => 'Не удалось открыть браузер.';

  @override
  String loginTimedOut(Object service) {
    return 'Время входа в $service истекло.';
  }

  @override
  String get loginWasCancelled => 'Вход отменён.';

  @override
  String loginFailed(Object service, Object error) {
    return 'Не удалось войти в $service: $error';
  }

  @override
  String connectFirstSettingsOnlineServices(Object service) {
    return 'Сначала подключите $service (Настройки → Онлайн-сервисы).';
  }

  @override
  String didNotAnswerInTimeCheck(Object service) {
    return '$service не ответил вовремя. Проверьте подключение.';
  }

  @override
  String secureConnectionToFailedCheckThe(Object service) {
    return 'Не удалось защищённое подключение к $service (проверьте часы на ПК или прокси).';
  }

  @override
  String get xFile => 'Файл';

  @override
  String get high => 'Высокая';

  @override
  String get medium => 'Средняя';

  @override
  String get lowCheckIt => 'Низкая — проверьте';

  @override
  String get noMatch => 'Нет совпадения';

  @override
  String notThe(Object v) {
    return 'не $v';
  }

  @override
  String get theService => 'Сервис';

  @override
  String get youSeemToBeOfflineLocal =>
      'Похоже, нет интернета. Локальные песни играют; онлайн-функции вернутся вместе со связью.';

  @override
  String isLimitingRequestsRightNowTry(Object name) {
    return '$name сейчас ограничивает запросы. Повторите через несколько минут.';
  }

  @override
  String yourLoginExpiredConnectTheAccount(Object name) {
    return 'Вход в $name истёк. Подключите аккаунт заново: Настройки → Онлайн-сервисы.';
  }

  @override
  String refusedTheRequest(Object name) {
    return '$name отклонил запрос.';
  }

  @override
  String notFoundOnDeletedPrivateOr(Object name) {
    return 'Не найдено в $name (удалено, закрыто или неверная ссылка).';
  }

  @override
  String hasServerProblemsTryAgainLater(Object name) {
    return 'У $name проблемы с сервером. Повторите позже.';
  }

  @override
  String needsAnApiKeyInThe(Object name) {
    return 'Для $name нужен API-ключ в файле настроек (Настройки → Онлайн-сервисы).';
  }

  @override
  String isTurnedOffInSettingsOnline(Object name) {
    return '$name выключен: Настройки → Онлайн-сервисы.';
  }

  @override
  String canNotDoThis(Object name) {
    return '$name этого не умеет.';
  }

  @override
  String sentSomethingUnexpectedItMayHave(Object name) {
    return '$name вернул неожиданный ответ (возможно, сервис изменился). Повторите позже.';
  }

  @override
  String somethingWentWrong(Object e) {
    return 'Что-то пошло не так: $e';
  }

  @override
  String get youtube => 'YouTube';

  @override
  String get playlistCreated => 'Плейлист создан';

  @override
  String get playlistUpdated => 'Плейлист обновлён';

  @override
  String get open => 'Открыть';

  @override
  String get thisImportWasDeleted => 'Этот импорт удалён';

  @override
  String get openPlaylist => 'Открыть плейлист';

  @override
  String matchedOf(Object matched, Object total) {
    return 'совпало $matched из $total';
  }

  @override
  String nToCheck(Object n) {
    return 'проверить: $n';
  }

  @override
  String nNotFound(Object n) {
    return 'не найдено: $n';
  }

  @override
  String matchingLocalFilesFirstThenOnline(Object done, Object total) {
    return 'Сопоставление $done / $total… (сначала локальные файлы, потом сеть)';
  }

  @override
  String get pause => 'Пауза';

  @override
  String resumeMatchingLeft(Object left) {
    return 'Продолжить сопоставление (осталось $left)';
  }

  @override
  String get updatePlaylistWithFixes => 'Обновить плейлист с исправлениями';

  @override
  String xAll(Object n) {
    return 'Все $n';
  }

  @override
  String check(Object n) {
    return 'Проверить $n';
  }

  @override
  String notFound(Object n) {
    return 'Не найдено $n';
  }

  @override
  String matched(Object n) {
    return 'Совпало $n';
  }

  @override
  String duplicates(Object n) {
    return 'Дубликаты $n';
  }

  @override
  String get waiting => 'Ожидание…';

  @override
  String duplicateOfSkipped(Object n) {
    return 'Дубликат №$n — пропущен';
  }

  @override
  String get skipped => 'Пропущено';

  @override
  String get noGoodMatchFound => 'Хорошего совпадения нет';

  @override
  String get fix => 'Исправить';

  @override
  String get fixMatch => 'Исправить совпадение';

  @override
  String get markedAsNoMatch => 'Помечено: нет совпадения';

  @override
  String get nothingFoundTryOtherWords =>
      'Ничего не найдено — попробуйте другие слова';

  @override
  String get listen => 'Слушать';

  @override
  String get pasteAPlaylistAlbumOrLikes =>
      'Вставьте ссылку на плейлист, альбом или лайки из Spotify, YouTube, SoundCloud, Apple Music или Deezer';

  @override
  String isTurnedOff(Object service) {
    return '$service выключен';
  }

  @override
  String get notAvailable => 'недоступно';

  @override
  String get setUp => 'Настроить';

  @override
  String reading(Object service) {
    return 'Чтение $service…';
  }

  @override
  String get importAPlaylistFile => 'Импорт файла плейлиста';

  @override
  String get playlist => 'плейлист';

  @override
  String get album2 => 'альбом';

  @override
  String get song => 'песня';

  @override
  String get likes => 'лайки';

  @override
  String get link => 'ссылка';

  @override
  String get playlistAlbumAndLikesLinksWork =>
      'Работают ссылки на плейлисты, альбомы и лайки';

  @override
  String get notALinkPrismCanRead => 'Prism не может прочитать эту ссылку';

  @override
  String needsToBeSetUpFirst(Object what, Object service) {
    return '$what · сначала настройте $service';
  }

  @override
  String get fromYourClipboard => ' · из буфера обмена';

  @override
  String get importPlaylists => 'Импорт плейлистов';

  @override
  String get bringYourPlaylistsFromSpotifyYoutube =>
      'Перенесите плейлисты из Spotify, YouTube и других приложений. Prism сначала ищет каждую песню в библиотеке, потом в сети, и показывает, насколько уверен в совпадении.';

  @override
  String get pasteALink => 'Вставьте ссылку';

  @override
  String get clear => 'Очистить';

  @override
  String get xImport => 'Импорт';

  @override
  String get orAFileCsvFromExportify =>
      'Или файл: CSV из Exportify или TuneMyMusic, JSON, M3U';

  @override
  String get chooseFile => 'Выбрать файл';

  @override
  String get setUpServices => 'Настроить сервисы';

  @override
  String get fromYourAccounts => 'Из ваших аккаунтов';

  @override
  String get yourImports => 'Ваши импорты';

  @override
  String loading(Object service) {
    return 'Загрузка $service…';
  }

  @override
  String get notConnectedSettingsOnlineServices =>
      'Не подключено — Настройки → Онлайн-сервисы';

  @override
  String get likedVideos => 'Понравившиеся видео';

  @override
  String get likedSongs => 'Любимые песни';

  @override
  String get readingLikes => 'Чтение лайков…';

  @override
  String get savedAlbums => 'Сохранённые альбомы…';

  @override
  String get savedAlbums2 => 'Сохранённые альбомы';

  @override
  String get playlists => 'Плейлисты…';

  @override
  String get playlists2 => 'Плейлисты';

  @override
  String xImport2(Object n) {
    return 'Импортировать $n';
  }

  @override
  String get nothingHere => 'Здесь пусто';

  @override
  String matching(Object done, Object total) {
    return 'Сопоставление $done / $total…';
  }

  @override
  String pausedLeft(Object n) {
    return 'Пауза · осталось $n';
  }

  @override
  String stoppedLeftTapToResume(Object n) {
    return 'Остановлено · осталось $n — нажмите, чтобы продолжить';
  }

  @override
  String ofMatchedReadyToSave(Object matched, Object total) {
    return 'совпало $matched из $total · можно сохранить';
  }

  @override
  String ofMatchedSaved(Object matched, Object total) {
    return 'совпало $matched из $total · сохранено';
  }

  @override
  String get thisImportThePlaylistStays => 'этот импорт (плейлист останется)';

  @override
  String get deleteImport => 'Удалить импорт';

  @override
  String get preview => 'Просмотр';

  @override
  String get onlyYourLibraryWillBeSearched => 'Поиск будет только в библиотеке';

  @override
  String get turnOnYoutubePlaybackOrSoundcloud =>
      'Включите воспроизведение YouTube или SoundCloud в Настройки → Онлайн-сервисы, чтобы находить песни, которых у вас нет.';

  @override
  String get sameSongTwiceInOneList =>
      'Одна песня дважды в списке (в том числе с разными пометками «remaster»)';

  @override
  String get playlistName => 'Название плейлиста';

  @override
  String get importedBefore => 'Уже импортировалось';

  @override
  String ofMatchedImportingAgainMakesA(
    Object name,
    Object matched,
    Object total,
  ) {
    return '«$name» — совпало $matched из $total. Повторный импорт создаст новый плейлист.';
  }

  @override
  String duplicateOf(Object n) {
    return 'дубликат №$n';
  }

  @override
  String get onlineServices => 'Онлайн-сервисы';

  @override
  String get apiKeysFile => 'Файл API-ключей';

  @override
  String get keysAreReadOnlyFromThis =>
      'Ключи читаются только из этого локального файла (не хранятся ни в приложении, ни в репозитории). См. README → Online services.';

  @override
  String get createFile => 'Создать файл';

  @override
  String templateAtFillInYourKeys(Object path) {
    return 'Шаблон: $path — впишите ключи и нажмите «Перечитать».';
  }

  @override
  String get openFolder => 'Открыть папку';

  @override
  String get reload => 'Перечитать';

  @override
  String get configReloaded => 'Настройки перечитаны';

  @override
  String get services => 'Сервисы';

  @override
  String get offline => 'Офлайн';

  @override
  String get terms => 'Условия';

  @override
  String get importPlaylistsLikedSongsAndSaved =>
      'Импорт плейлистов, лайков и альбомов (без аудио)';

  @override
  String get searchPlaylistsPlaybackYoutubeYoutubeMusic =>
      'Поиск, плейлисты, воспроизведение (ссылки YouTube и YouTube Music)';

  @override
  String get searchLikesAndPlaylistsPlaybackWhere =>
      'Поиск, лайки и плейлисты, воспроизведение где разрешено';

  @override
  String get importPublicPlaylistAlbumLinksNo =>
      'Импорт публичных ссылок на плейлисты и альбомы (без входа)';

  @override
  String get importPublicPlaylistAlbumLinksReads =>
      'Импорт публичных ссылок на плейлисты и альбомы (читает веб-страницу)';

  @override
  String finishTheLoginInYourBrowser(Object service) {
    return 'Завершите вход в $service в браузере…';
  }

  @override
  String get turnOnTheYoutubeExtractor => 'Включить YouTube-экстрактор?';

  @override
  String get thisPlaysYoutubeAudioInsidePrism =>
      'Он воспроизводит звук YouTube прямо в Prism, ищет без API-ключа и сохраняет офлайн-копии. Это неофициальный экстрактор, условия YouTube такое не разрешают.\n\nИспользуйте только для себя, не раздавайте сохранённые файлы и будьте готовы, что иногда он будет ломаться.';

  @override
  String get cancel => 'Отмена';

  @override
  String get iUnderstandTurnOn => 'Понятно, включить';

  @override
  String needsSetup(Object msg) {
    return 'Нужна настройка: $msg';
  }

  @override
  String notWorking(Object msg) {
    return 'Не работает: $msg';
  }

  @override
  String get ready => 'Готово';

  @override
  String redirectUriToRegister(Object uri) {
    return 'Redirect URI для регистрации: $uri';
  }

  @override
  String get copy => 'Копировать';

  @override
  String get youtubeExtractor => 'YouTube-экстрактор';

  @override
  String get playbackOfflineCopiesSearchWithoutAn =>
      'Воспроизведение, офлайн-копии, поиск без API-ключа';

  @override
  String get checking => 'Проверка…';

  @override
  String get notConnected => 'Не подключено';

  @override
  String get disconnect => 'Отключить';

  @override
  String get connect => 'Подключить';

  @override
  String get keepPlayedSongsOffline => 'Сохранять прослушанное офлайн';

  @override
  String get savesACopyOfYoutubeSongs =>
      'Сохраняет копии песен с YouTube, чтобы они работали без интернета';

  @override
  String get needsTheYoutubeExtractor => 'Нужен YouTube-экстрактор';

  @override
  String offlineCopiesMbOfGb(Object mb, Object gb) {
    return 'Офлайн-копии: $mb МБ из $gb ГБ';
  }

  @override
  String gb(Object gb) {
    return '$gb ГБ';
  }

  @override
  String get spotifyImportOnlyNeverAudio =>
      'Spotify — только импорт, никакого аудио';

  @override
  String get usesTheOfficialWebApiTo =>
      'Официальный Web API читает ваши плейлисты, лайки и альбомы как текст (название, исполнитель, длина). Prism никогда не скачивает, не записывает и не играет аудио Spotify: песни сопоставляются с вашими файлами или другими сервисами. Условия для разработчиков Spotify разрешают некоммерческие приложения; приложение в Development Mode работает максимум для 5 человек, добавленных в панели Spotify, и читает только ваши или совместные плейлисты.';

  @override
  String get youtubeDataApiOfficial => 'YouTube Data API — официально';

  @override
  String get searchPlaylistsAndWithGoogleLogin =>
      'Поиск, плейлисты и (при входе в Google) ваши плейлисты и понравившиеся видео через официальный API с вашим ключом. Ограничен дневной квотой (примерно 100 поисков в день). Аудио в официальном API нет.';

  @override
  String get youtubeExtractorPlaybackAndOfflineCopies =>
      'YouTube-экстрактор — воспроизведение и офлайн-копии';

  @override
  String get playsYoutubeAudioInsidePrismSearches =>
      'Воспроизводит звук YouTube в Prism, ищет без ключа и сохраняет офлайн-копии с помощью неофициального экстрактора (youtube_explode_dart). Условия YouTube этого не разрешают (доступ только через их плеер, скачивание только кнопкой скачивания). По умолчанию выключен; включайте только для себя, не раздавайте сохранённые файлы и будьте готовы к поломкам при изменениях YouTube.';

  @override
  String get soundcloudOfficialApi => 'SoundCloud — официальный API';

  @override
  String get searchYourLikesAndPlaylistsThrough =>
      'Поиск, ваши лайки и плейлисты через официальный API с вашим зарегистрированным приложением. Играют только треки, для которых автор разрешил стриминг, всегда со ссылкой на SoundCloud. Офлайн-копий нет (условия API запрещают хранить аудио).';

  @override
  String get deezerPublicPlaylistLinks =>
      'Deezer — публичные ссылки на плейлисты';

  @override
  String get readsPublicPlaylistsAlbumsAndSongs =>
      'Читает публичные плейлисты, альбомы и песни через открытый API Deezer (только текст, без входа и аудио). Условия API Deezer — для некоммерческого использования.';

  @override
  String get appleMusicPublicPageReading =>
      'Apple Music — чтение публичных страниц';

  @override
  String get appleHasNoFreeApiSo =>
      'У Apple нет бесплатного API, поэтому при импорте ссылки Prism читает список песен с публичной веб-страницы плейлиста или альбома. Без гарантий: может перестать работать, когда Apple изменит страницу. Для личного использования.';

  @override
  String get personalUseOnly => 'Только для личного использования';

  @override
  String get whatEachServiceAllows => 'Что разрешает каждый сервис';

  @override
  String get termsOfServiceLimitsInPlain =>
      'Ограничения условий сервисов простыми словами';

  @override
  String get prismIsAPersonalPlayerFor =>
      'Prism — личный плеер для вас и друзей. Он не связан ни с одним из этих сервисов. API-ключи и входы — ваши: ключи лежат в локальном файле настроек, входы — в системном хранилище.';

  @override
  String deezer(Object msg) {
    return 'Deezer: $msg';
  }

  @override
  String get couldNotOpenThisDeezerShort =>
      'Не удалось открыть эту короткую ссылку Deezer.';

  @override
  String get deezerPlaylist => 'Плейлист Deezer';

  @override
  String get openThisLink => 'открыть эту ссылку';

  @override
  String get couldNotReadSongsFromThis =>
      'Не удалось прочитать песни с этой страницы Apple Music (закрытый плейлист или Apple изменил страницу). Используйте экспорт CSV из TuneMyMusic.';

  @override
  String get appleMusicPlaylist => 'Плейлист Apple Music';

  @override
  String canNot(Object service, Object what) {
    return '$service: действие недоступно — $what.';
  }

  @override
  String get logIn => 'вход';

  @override
  String get listYourPlaylists => 'список ваших плейлистов';

  @override
  String get listSavedAlbums => 'список сохранённых альбомов';

  @override
  String get readLikedSongs => 'чтение лайков';

  @override
  String get openPlaylists => 'открытие плейлистов';

  @override
  String get openLinks => 'открытие ссылок';

  @override
  String get playAudio => 'воспроизведение';

  @override
  String get saveSongsOffline => 'сохранение офлайн';

  @override
  String get soundcloudLogInOrAddThe =>
      'SoundCloud: войдите или добавьте client secret приложения в файл настроек для поиска без входа.';

  @override
  String get soundcloudUser => 'Пользователь SoundCloud';

  @override
  String get connected => 'Подключено';

  @override
  String get playlist2 => 'Плейлист';

  @override
  String get likesSoundcloud => 'Лайки (SoundCloud)';

  @override
  String get soundcloudPlaylist => 'Плейлист SoundCloud';

  @override
  String likesOf(Object user) {
    return 'Лайки $user';
  }

  @override
  String get theUploaderDoesNotAllowStreaming =>
      'Автор не разрешает слушать этот трек вне SoundCloud.';

  @override
  String get spotifyUser => 'Пользователь Spotify';

  @override
  String get likedSongsSpotify => 'Любимые песни (Spotify)';

  @override
  String get openTheSpotifyLinkInA =>
      'Откройте spotify.link в браузере и вставьте полную ссылку open.spotify.com.';

  @override
  String get spotifyPlaylist => 'Плейлист Spotify';

  @override
  String get spotifyOnlyLetsSmallDevelopmentMode =>
      'Spotify разрешает небольшим приложениям (Development Mode) читать только ваши или совместные плейлисты. Для остальных: экспортируйте через Exportify или TuneMyMusic и импортируйте CSV.';

  @override
  String get youtubeDataApiOfficial2 => 'YouTube Data API (официальный)';

  @override
  String get youtubePlaylist => 'Плейлист YouTube';

  @override
  String get youtubeExplodeUnofficial => 'youtube_explode (неофициальный)';

  @override
  String get youtubeAsksToSlowDownToo =>
      'YouTube просит притормозить (слишком много поисков с этого подключения). Подождите и продолжите.';

  @override
  String get youtubeDidNotAnswerInTime => 'YouTube не ответил вовремя.';

  @override
  String thisYoutubeVideoIsUnavailableRemoved(Object e) {
    return 'Это видео YouTube недоступно (удалено, закрыто или заблокировано в регионе). $e';
  }

  @override
  String youtubeExtractorFailedYoutubeMayHave(Object e) {
    return 'Сбой YouTube-экстрактора — возможно, YouTube изменился. $e';
  }

  @override
  String notAValidYoutubeId(Object e) {
    return 'Неверный id YouTube: $e';
  }

  @override
  String get noAudioStreamForThisVideo => 'У этого видео нет аудиопотока.';

  @override
  String canNotStreamAudio(Object name) {
    return '$name не умеет передавать аудио';
  }

  @override
  String canNotDownloadAudio(Object name) {
    return '$name не умеет скачивать аудио';
  }

  @override
  String get addAYoutubeDataApiKey =>
      'Добавьте ключ YouTube Data API в файл настроек или включите YouTube-экстрактор.';

  @override
  String get searchAndImportWorkPlaybackNeeds =>
      'Поиск и импорт работают. Для воспроизведения нужен YouTube-экстрактор (только для личного использования).';

  @override
  String get googleAccount => 'Аккаунт Google';

  @override
  String get logInNoGoogleOauthClient =>
      'вход (нет Google OAuth client id в файле настроек)';

  @override
  String get listYourPlaylistsWithoutAGoogle =>
      'список ваших плейлистов без входа в Google';

  @override
  String get readLikedVideosWithoutAGoogle =>
      'чтение понравившихся видео без входа в Google';

  @override
  String get likedVideosYoutube => 'Понравившиеся видео (YouTube)';

  @override
  String get openThisKindOfLink => 'открытие такой ссылки';

  @override
  String get youtubePlaybackIsOffTurnOn =>
      'Воспроизведение YouTube выключено. Включите «YouTube-экстрактор»: Настройки → Онлайн-сервисы (только для личного использования).';

  @override
  String get saveSongsOfflineWithoutTheExtractor =>
      'сохранение офлайн без экстрактора';

  @override
  String get waveform => 'Волна';

  @override
  String get barsWithABrightTrailBehind =>
      'Столбики с ярким следом за курсором';

  @override
  String get ribbon => 'Лента';

  @override
  String get aLineThatWavesWhileThe =>
      'Линия колышется, пока играет песня, и выпрямляется на паузе';

  @override
  String get ledBlocks => 'LED-блоки';

  @override
  String get aHiFiMeterMadeOf =>
      'Индикатор из мелких блоков с горящим столбцом на месте курсора';

  @override
  String get tuner => 'Тюнер';

  @override
  String get aRadioDialWithANeedle =>
      'Шкала радио со стрелкой, вокруг неё шкала вздувается';

  @override
  String get liveSpectrum => 'Живой спектр';

  @override
  String get theWholeBarIsASpectrum =>
      'Вся полоса — анализатор спектра, всегда в движении';

  @override
  String get fullScreen => 'Во весь экран';

  @override
  String get endOfSong => 'Конец песни';

  @override
  String get x1Min => '< 1 мин';

  @override
  String get normal => 'Обычная';

  @override
  String get sleepTimer => 'Таймер сна';

  @override
  String get speedPitch => 'Скорость и тон';

  @override
  String get aBLoop => 'Петля A-B';

  @override
  String get setB => 'Поставить B';

  @override
  String get listenTogether => 'Слушать вместе';

  @override
  String get miniPlayer => 'Мини-плеер';

  @override
  String get leaveFullScreenF11 => 'Выйти из полноэкранного (F11)';

  @override
  String get fullScreenF11 => 'Во весь экран (F11)';

  @override
  String get next => 'Следующая';

  @override
  String get upNext => 'Далее';

  @override
  String get close => 'Закрыть';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get editThisSong => 'Редактировать песню';

  @override
  String get queue => 'Очередь';

  @override
  String get lyrics => 'Текст';

  @override
  String get visualizer => 'Визуализатор';

  @override
  String get expand => 'Развернуть';

  @override
  String get unmute => 'Включить звук';

  @override
  String mute(Object v) {
    return 'Без звука ($v %)';
  }

  @override
  String get queueIsEmpty => 'Очередь пуста';

  @override
  String get stopsAfterThisSong => 'Остановится после этой песни';

  @override
  String stopsIn(Object t) {
    return 'Остановится через $t';
  }

  @override
  String get musicFadesOutAndPauses => 'Музыка плавно затихнет и остановится';

  @override
  String get turnOff => 'Выключить';

  @override
  String loopingTapToClear(Object a, Object b) {
    return 'Петля $a–$b (нажмите, чтобы снять)';
  }

  @override
  String get tapAgainToSetB => 'Нажмите ещё раз, чтобы поставить B';

  @override
  String get aBLoopTapToSet => 'Петля A-B: нажмите, чтобы поставить A';

  @override
  String xPitchKept(Object v) {
    return '${v}x  (тон сохраняется)';
  }

  @override
  String get pitch => 'Тон';

  @override
  String semitonesSpeedKept(Object sign, Object v) {
    return '$sign$v пт  (скорость сохраняется)';
  }

  @override
  String get reset2 => 'Сбросить';

  @override
  String get shuffleOn => 'Перемешивание вкл.';

  @override
  String get shuffleOff => 'Перемешивание выкл.';

  @override
  String get previous => 'Предыдущая';

  @override
  String get repeatOff => 'Повтор выкл.';

  @override
  String get repeatAll => 'Повтор всех';

  @override
  String get repeatOne => 'Повтор одной';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get favorites => 'Избранное';

  @override
  String get yourListeningStats => 'Ваша статистика';

  @override
  String get topSongsArtistsAndStreaks => 'Топ песен, исполнителей и серии';

  @override
  String get fromSpotifyYoutubeSoundcloudDeezerApple =>
      'Из ссылки или файла. Spotify, YouTube, SoundCloud, Яндекс Музыка, Apple Music, Deezer';

  @override
  String get smartPlaylists => 'Умные плейлисты';

  @override
  String get xNew => 'Новый';

  @override
  String get renamePlaylist => 'Переименовать плейлист';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String delete2(Object what) {
    return 'Удалить $what?';
  }

  @override
  String get thisCannotBeUndone => 'Это нельзя отменить.';

  @override
  String get addToPlaylist2 => 'В плейлист';

  @override
  String get newPlaylist2 => 'Новый плейлист…';

  @override
  String get addedToPlaylist => 'Добавлено в плейлист';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String get emptyPlaylistLongPressASong =>
      'Плейлист пуст.\nЗажмите песню → «В плейлист».';

  @override
  String get hue => 'Оттенок';

  @override
  String get saturation => 'Насыщенность';

  @override
  String get lightness => 'Яркость';

  @override
  String get noLyricsPlain =>
      'Текст не найден.\nПоложите рядом с песней файл .lrc с тем же именем.';

  @override
  String get noLyricsHint =>
      'Текст не найден.\nПоложите рядом с песней файл .lrc с тем же именем или включите онлайн-поиск текстов в настройках.';

  @override
  String get playback => 'Воспроизведение';

  @override
  String get appearance => 'Оформление';

  @override
  String get onlineImport => 'Сеть и импорт';

  @override
  String get windows => 'Windows';

  @override
  String get backup => 'Резервная копия';

  @override
  String get about => 'О программе';

  @override
  String crossfadeN(Object s) {
    return 'Кроссфейд $s с';
  }

  @override
  String get gapless => 'Без пауз';

  @override
  String get eqOn => 'Эквалайзер вкл.';

  @override
  String get eqOff => 'Эквалайзер выкл.';

  @override
  String get importPlaylistsAccountsOfflineCopies =>
      'Импорт плейлистов, аккаунты, офлайн-копии';

  @override
  String get anywhere => 'Откуда угодно';

  @override
  String get sameWiFiOnly => 'Только в той же сети Wi-Fi';

  @override
  String get closesToTheTray => 'Сворачивается в трей';

  @override
  String get saveOrRestoreEverythingInOne =>
      'Сохранить или восстановить всё одним файлом';

  @override
  String get musicFolders => 'Папки с музыкой';

  @override
  String get removeFolder => 'Убрать папку';

  @override
  String get addFolder => 'Добавить папку';

  @override
  String get rescanLibrary => 'Пересканировать библиотеку';

  @override
  String lastScanNewChangedRemovedIn(
    Object added,
    Object updated,
    Object removed,
    Object s,
  ) {
    return 'Последнее сканирование: новых $added, изменённых $updated, удалённых $removed, за $s с';
  }

  @override
  String get onlyNewOrChangedFilesAre =>
      'Заново читаются только новые и изменённые файлы';

  @override
  String get findDuplicates => 'Найти дубликаты';

  @override
  String get theSameSongInSeveralFiles => 'Одна песня в нескольких файлах';

  @override
  String get sound => 'Звук';

  @override
  String get crossfade => 'Кроссфейд';

  @override
  String get blendTheEndOfASong => 'Плавно смешивать конец песни со следующей';

  @override
  String get offGapless => 'Выкл., без пауз';

  @override
  String get sendsOnlyTitleArtistAlbumAnd =>
      'На lrclib.net отправляются только название, исполнитель, альбом и длина. Локальные файлы .lrc работают всегда.';

  @override
  String get findLyricsOnline => 'Искать тексты в сети';

  @override
  String get theme => 'Тема';

  @override
  String get matrixConstellationRippleReactsToThe =>
      'Матрица, Созвездие, Рябь. Реагируют на мышь и музыку';

  @override
  String get shownInTheFullPlayer => 'Показывается в полном плеере';

  @override
  String get reduceMotion => 'Меньше анимации';

  @override
  String get turnsOffDecorativeAnimations => 'Отключает декоративные анимации';

  @override
  String get seekBar => 'Полоса перемотки';

  @override
  String get rightClickTheSeekBarTo =>
      'Правый клик по полосе переключает стиль в любой момент.';

  @override
  String get movesWithTheMusic => 'Двигается с музыкой';

  @override
  String get everyStyleReactsToTheSong =>
      'Все стили реагируют на песню. Каждая песня анализируется один раз, при первом запуске';

  @override
  String get fromALinkAFileOr => 'По ссылке, из файла или из аккаунтов';

  @override
  String get spotifyYoutubeSoundcloudDeezerAppleMusic =>
      'Spotify, YouTube, SoundCloud, Deezer, Apple Music';

  @override
  String get sessionsOnTheSameWiFi =>
      'Сеансы в одной сети Wi-Fi соединяются напрямую и видны в списке. Через интернет сообщения идут через бесплатный публичный сервер (HiveMQ, EMQX или Mosquitto): названия песен, длина и позиция, зашифрованные кодом сеанса. Аудио не передаётся никогда.';

  @override
  String get sessionsOverTheInternet => 'Сеансы через интернет';

  @override
  String get offSameWiFiOnlyNothing =>
      'Выкл.: только в той же сети Wi-Fi, ничего не выходит за её пределы';

  @override
  String get yourNameInASession => 'Ваше имя в сеансе';

  @override
  String get theNameOfThisDevice => 'Имя этого устройства';

  @override
  String get ownServerOptional => 'Свой сервер (необязательно)';

  @override
  String get ifYouWouldRatherNotUse =>
      'Если не хотите использовать публичный сервер: кто-то запускает «dart run tool/relay.dart» на доступном компьютере, и все вписывают сюда его адрес.';

  @override
  String get closeToTray => 'Сворачивать в трей';

  @override
  String get keepPlayingInTheTrayWhen =>
      'Продолжать играть в трее после закрытия окна';

  @override
  String get settingsEqThemesPlaylistsFavoritesSmart =>
      'Настройки, эквалайзер, темы, плейлисты, избранное, умные плейлисты и правки. Песни сопоставляются по пути или по названию и исполнителю, поэтому копия работает и на другом устройстве.';

  @override
  String get backUpToAFile => 'Сохранить в файл';

  @override
  String get restoreFromAFile => 'Восстановить из файла';

  @override
  String get aMusicPlayerForYourOwn =>
      'Плеер для своей музыки, сделанный для себя и пары друзей. Windows и Android.';

  @override
  String lookingOfSongsFound(Object done, Object total, Object found) {
    return 'Поиск… $done из $total песен, найдено $found';
  }

  @override
  String get nothingFoundYet => 'Пока ничего не найдено';

  @override
  String get missingInfo => 'Недостающие данные';

  @override
  String get sendsOnlyTitleAndArtistTo =>
      'В открытый поиск Apple и Deezer отправляются только название и исполнитель. Файлы не меняются, ваши теги не заменяются. Песня без тегов получает данные, только если имя файла явно совпадает.';

  @override
  String get findCoversAndArtistsOnline =>
      'Искать обложки и исполнителей в сети';

  @override
  String get lookAgain => 'Поискать снова';

  @override
  String get forSongsThatGotNothingSo =>
      'Для песен, где пока ничего не нашлось';

  @override
  String get undoEverythingFound => 'Отменить всё найденное';

  @override
  String get backToWhatYourFilesSay => 'Вернуться к данным из файлов';

  @override
  String get loudness => 'Громкость';

  @override
  String get usesReplaygainTagsOrMeasuresSongs =>
      'Использует теги ReplayGain или измеряет песни через FFmpeg (EBU R128, −18 LUFS).';

  @override
  String get evenOutLoudness => 'Выравнивать громкость';

  @override
  String get song2 => 'Песня';

  @override
  String get measureSongsAutomatically => 'Измерять песни автоматически';

  @override
  String get whenASongWithoutReplaygainTags =>
      'Когда запускается песня без тегов ReplayGain';

  @override
  String get measureTheWholeLibrary => 'Измерить всю библиотеку';

  @override
  String measuringOf(Object done, Object total) {
    return 'Измерение $done из $total';
  }

  @override
  String get ffmpegIsMissingOnThisDevice => 'На этом устройстве нет FFmpeg';

  @override
  String get stop => 'Стоп';

  @override
  String get exportTheme => 'Экспорт темы';

  @override
  String get themeExported => 'Тема экспортирована';

  @override
  String get importTheme => 'Импорт темы';

  @override
  String imported(Object name) {
    return 'Импортировано: «$name»';
  }

  @override
  String couldNotImport(Object e) {
    return 'Не удалось импортировать: $e';
  }

  @override
  String get saveAs => 'Сохранить как…';

  @override
  String get saveThemeAs => 'Сохранить тему как';

  @override
  String get myTheme => 'Моя тема';

  @override
  String saved(Object name) {
    return 'Сохранено: «$name»';
  }

  @override
  String get presets => 'Пресеты';

  @override
  String get mode => 'Режим';

  @override
  String get auto => 'Авто';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get blackWhite => 'Чёрно-белая';

  @override
  String get greysOnlyCoversStayInColor =>
      'Только серые оттенки, обложки остаются цветными';

  @override
  String get colorsFromAlbumArt => 'Цвета из обложки';

  @override
  String get primaryColorFollowsTheCurrentCover =>
      'Основной цвет следует за текущей обложкой';

  @override
  String get primary => 'Основной';

  @override
  String get accent => 'Акцент';

  @override
  String get shapeSurfaces => 'Форма и поверхности';

  @override
  String get cornerRadius => 'Скругление углов';

  @override
  String px(Object v) {
    return '$v пкс';
  }

  @override
  String get glassBlur => 'Стекло / размытие';

  @override
  String get textMotion => 'Текст и движение';

  @override
  String get font => 'Шрифт';

  @override
  String get system => 'Системный';

  @override
  String get animationSpeed => 'Скорость анимации';

  @override
  String fastX(Object v) {
    return 'Быстрая (${v}x)';
  }

  @override
  String slowX(Object v) {
    return 'Медленная (${v}x)';
  }

  @override
  String normalX(Object v) {
    return 'Обычная (${v}x)';
  }

  @override
  String get themeName => 'Название темы';

  @override
  String longPressToDelete(Object name) {
    return '$name (зажмите, чтобы удалить)';
  }

  @override
  String get previewSong => 'Песня для примера';

  @override
  String glassPanelPx(Object r) {
    return 'Стеклянная панель · $r пкс';
  }

  @override
  String get search => 'Поиск';

  @override
  String get stats => 'Статистика';

  @override
  String code(Object code) {
    return 'Код $code';
  }

  @override
  String xWith(Object name) {
    return 'С $name';
  }

  @override
  String get aFriend => 'другом';

  @override
  String get rightClickNextBackground => 'Правый клик: следующий фон';

  @override
  String get week => 'Неделя';

  @override
  String get month => 'Месяц';

  @override
  String get year => 'Год';

  @override
  String get allTime => 'За всё время';

  @override
  String get morning => 'Утро';

  @override
  String get x5To12 => 'с 5 до 12';

  @override
  String get afternoon => 'День';

  @override
  String get x12To18 => 'с 12 до 18';

  @override
  String get evening => 'Вечер';

  @override
  String get x18To23 => 'с 18 до 23';

  @override
  String get night => 'Ночь';

  @override
  String get x23To5 => 'с 23 до 5';

  @override
  String get mostPlayed => 'Самые прослушиваемые';

  @override
  String get forgottenGems => 'Забытые жемчужины';

  @override
  String get smartPlaylistNotFound => 'Умный плейлист не найден';

  @override
  String get editRules => 'Изменить правила';

  @override
  String get allSongs => 'все песни';

  @override
  String playedNPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'сыграно от $count раза',
      many: 'сыграно от $count раз',
      few: 'сыграно от $count раз',
      one: 'сыграно от $count раза',
    );
    return '$_temp0';
  }

  @override
  String inDays(Object days) {
    return 'за $days дн.';
  }

  @override
  String addedInTheLastDays(Object days) {
    return 'добавлено за последние $days дн.';
  }

  @override
  String genre(Object genre) {
    return 'жанр «$genre»';
  }

  @override
  String year2(Object from, Object to) {
    return 'год $from–$to';
  }

  @override
  String notPlayedForDays(Object days) {
    return 'не игралось $days дн.';
  }

  @override
  String get mySmartPlaylist => 'Мой умный плейлист';

  @override
  String get minPlays => 'мин. запусков';

  @override
  String get inDays2 => 'за дней';

  @override
  String get genre2 => 'Жанр';

  @override
  String get notPlayedFor => 'Не игралось';

  @override
  String get editSmartPlaylist => 'Изменить умный плейлист';

  @override
  String get newSmartPlaylist => 'Новый умный плейлист';

  @override
  String get name => 'Название';

  @override
  String get songsThatMatchAllRules => 'Песни, подходящие под все правила:';

  @override
  String get addRule => 'Добавить правило';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get random => 'Случайно';

  @override
  String get maxSongs => 'макс. песен';

  @override
  String get smartPlaylist => 'Умный плейлист';

  @override
  String get justNow => 'только что';

  @override
  String minAgo(Object m) {
    return '$m мин назад';
  }

  @override
  String hAgo(Object h) {
    return '$h ч назад';
  }

  @override
  String vsBefore(Object sign, Object pct) {
    return '$sign$pct % к прошлому периоду';
  }

  @override
  String get atAGlance => 'Коротко';

  @override
  String get listeningTime => 'Время прослушивания';

  @override
  String get plays => 'Запуски';

  @override
  String get differentSongs => 'Разных песен';

  @override
  String playedOnlyOnce(Object n) {
    return 'один раз сыграно: $n';
  }

  @override
  String get newToYou => 'Новое для вас';

  @override
  String get daysWithMusic => 'Дней с музыкой';

  @override
  String aboutADay(Object t) {
    return 'примерно $t в день';
  }

  @override
  String get currentStreak => 'Текущая серия';

  @override
  String best(Object n) {
    return 'рекорд: $n';
  }

  @override
  String get sessions => 'Сеансы';

  @override
  String aboutEach(Object t) {
    return 'примерно $t каждый';
  }

  @override
  String get youHearOfASong => 'Вы дослушиваете песню на';

  @override
  String get onAverage => 'в среднем';

  @override
  String get minutesPerDay => 'Минут в день';

  @override
  String get minutesPerMonth => 'Минут в месяц';

  @override
  String min(Object when, Object m) {
    return '$when · $m мин';
  }

  @override
  String get yourWeek => 'Ваша неделя';

  @override
  String get darkerMeansMoreMinutesHoverFor =>
      'Темнее — больше минут. Наведите, чтобы увидеть числа.';

  @override
  String get last6Months => 'Последние 6 месяцев';

  @override
  String get timeOfDay => 'Время суток';

  @override
  String ofYourListeningIsOnWeekends(Object pct) {
    return '$pct % прослушиваний приходится на выходные';
  }

  @override
  String get musicByDecade => 'Музыка по десятилетиям';

  @override
  String get songsNeedAYearTagFor => 'Для этого у песен должен быть тег года';

  @override
  String get howOldIsWhatYouPlay => 'Насколько стара ваша музыка?';

  @override
  String get records => 'Рекорды';

  @override
  String get longestSession => 'Самый долгий сеанс';

  @override
  String nSongsOnDate(int count, Object date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни, $date',
      many: '$count песен, $date',
      few: '$count песни, $date',
      one: '$count песня, $date',
    );
    return '$_temp0';
  }

  @override
  String get biggestDay => 'Самый большой день';

  @override
  String onRepeat(Object title) {
    return 'На повторе: $title';
  }

  @override
  String xOn2(Object date) {
    return '$date';
  }

  @override
  String loyalTo(Object artist) {
    return 'Верны исполнителю $artist';
  }

  @override
  String get ofYourPlays => 'ваших прослушиваний';

  @override
  String get topSongs => 'Топ песен';

  @override
  String get topArtists => 'Топ исполнителей';

  @override
  String get topAlbums => 'Топ альбомов';

  @override
  String get topGenres => 'Топ жанров';

  @override
  String get nothingHereYet => 'Пока здесь пусто';

  @override
  String get totalLength => 'Общая длина';

  @override
  String daysNonstop(Object d) {
    return '$d дн. без остановки';
  }

  @override
  String get averageSong => 'Средняя песня';

  @override
  String get neverPlayed => 'Ни разу не играли';

  @override
  String get withACover => 'С обложкой';

  @override
  String fullyTagged(Object n) {
    return 'с полными тегами: $n';
  }

  @override
  String get extremes => 'Крайности';

  @override
  String longest(Object title) {
    return 'Самая длинная: $title';
  }

  @override
  String shortest(Object title) {
    return 'Самая короткая: $title';
  }

  @override
  String get fileTypes => 'Типы файлов';

  @override
  String get genres => 'Жанры';

  @override
  String get decades => 'Десятилетия';

  @override
  String get noListensYetInThisPeriod =>
      'За этот период прослушиваний нет.\nПесня засчитывается после 30 секунд или половины, если она короткая.';

  @override
  String get yourListening => 'Ваши прослушивания';

  @override
  String get overview => 'Обзор';

  @override
  String get xTop => 'Топ';

  @override
  String get history => 'История';

  @override
  String get wrapped => 'Итоги';

  @override
  String get aMorningListener => 'утренний слушатель';

  @override
  String get anAfternoonListener => 'дневной слушатель';

  @override
  String get anEveningListener => 'вечерний слушатель';

  @override
  String get aNightOwl => 'ночная сова';

  @override
  String get thisWeekYouListenedFor => 'На этой неделе вы слушали';

  @override
  String get thisMonthYouListenedFor => 'В этом месяце вы слушали';

  @override
  String get thisYearYouListenedFor => 'В этом году вы слушали';

  @override
  String get inTotalYouListenedFor => 'Всего вы слушали';

  @override
  String nDifferentSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count разные песни',
      many: '$count разных песен',
      few: '$count разные песни',
      one: '$count разная песня',
    );
    return '$_temp0';
  }

  @override
  String youAreMostPlaysAround00(Object who, Object hour) {
    return 'Вы — $who: больше всего прослушиваний около $hour:00';
  }

  @override
  String get longestListeningStreak => 'Самая длинная серия';

  @override
  String get daysInARow => 'дней подряд';

  @override
  String get daysInARowWithAt => 'Дней подряд хотя бы с одной песней';

  @override
  String get yourTopSong => 'Ваша главная песня';

  @override
  String get whenYouListen => 'Когда вы слушаете';

  @override
  String get someone => 'Кто-то';

  @override
  String get starting => 'Запуск…';

  @override
  String get couldNotStartCheckYourNetwork =>
      'Не удалось запустить. Проверьте подключение к сети.';

  @override
  String get waitingForFriends => 'Ждём друзей…';

  @override
  String get friend => 'Друг';

  @override
  String get listeningTogether => 'Слушаем вместе';

  @override
  String get thatCodeDoesNotLookRight => 'Этот код выглядит неправильно';

  @override
  String lookingFor(Object room) {
    return 'Поиск $room…';
  }

  @override
  String get onlineSessionsAreOffSettingsListen =>
      'Онлайн-сеансы выключены (Настройки → Слушать вместе)';

  @override
  String noSessionWithTheCodeCheck(Object room) {
    return 'Нет сеанса с кодом $room. Проверьте код: у ведущего должен быть открыт Prism.';
  }

  @override
  String get followingTheHost => 'Следуем за ведущим';

  @override
  String get reconnecting => 'Переподключение…';

  @override
  String get theHostIsGone => 'Ведущий пропал';

  @override
  String get waitingForTheHost => 'Ждём ведущего…';

  @override
  String get theHostEndedTheSession => 'Ведущий завершил сеанс';

  @override
  String get lookingForTheSongOnline => 'Ищем песню в сети…';

  @override
  String get theHostIsPlayingASong => 'Ведущий играет песню, которой у вас нет';

  @override
  String get everyonePlaysTheSameSongAt =>
      'Все слушают одну песню в один момент.';

  @override
  String get sendThisCodeToYourFriends => 'Отправьте этот код друзьям';

  @override
  String get copied => 'Скопировано';

  @override
  String get worksFromAnywhere => 'Работает откуда угодно.';

  @override
  String get worksOnThisWiFiOnly => 'Работает только в этой сети Wi-Fi.';

  @override
  String get endSession => 'Завершить сеанс';

  @override
  String session(Object code) {
    return 'Сеанс $code';
  }

  @override
  String missing(Object song) {
    return 'Нет песни: $song';
  }

  @override
  String get addTheSongToYourLibrary =>
      'Добавьте песню в библиотеку или включите YouTube либо SoundCloud: Настройки → Сеть и импорт.';

  @override
  String get justYouAndTheHost => 'Только вы и ведущий';

  @override
  String get leave => 'Выйти';

  @override
  String get friendSCode => 'Код друга';

  @override
  String get join => 'Присоединиться';

  @override
  String get startASession => 'Начать сеанс';

  @override
  String get eachPersonPlaysTheSongFrom =>
      'Каждый играет песню из своей библиотеки. Названия песен идут через бесплатный публичный сервер, зашифрованные кодом. Это можно выключить: Настройки → Слушать вместе.';

  @override
  String get onThisNetwork => 'В этой сети';

  @override
  String backupSummary(
    Object playlists,
    Object playlistSongs,
    Object favorites,
    Object themes,
    Object smart,
    Object edits,
  ) {
    return 'плейлистов: $playlists (песен: $playlistSongs), избранного: $favorites, тем: $themes, умных плейлистов: $smart, правок: $edits';
  }

  @override
  String get notAPrismBackupInvalidJson =>
      'Это не резервная копия Prism (неверный JSON)';

  @override
  String get notAPrismBackup => 'Это не резервная копия Prism';

  @override
  String get backupIsFromANewerPrism =>
      'Копия создана в более новой версии Prism';

  @override
  String restored(Object name) {
    return '$name (восстановлен)';
  }

  @override
  String writingTagsIsNotSupportedFor(Object ext) {
    return 'Запись тегов в файлы $ext не поддерживается';
  }

  @override
  String couldNotWriteTags(Object e) {
    return 'Не удалось записать теги: $e';
  }

  @override
  String get tagsDidNotStickFileRestored =>
      'Теги не сохранились (файл восстановлен)';

  @override
  String get duplicateFinder => 'Поиск дубликатов';

  @override
  String get noDuplicatesFound => 'Дубликатов нет 🎉';

  @override
  String nGroupsHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count группы. Оставьте лучшую копию; удаление из библиотеки не трогает файл на диске.',
      many:
          '$count групп. Оставьте лучшую копию; удаление из библиотеки не трогает файл на диске.',
      few:
          '$count группы. Оставьте лучшую копию; удаление из библиотеки не трогает файл на диске.',
      one:
          '$count группа. Оставьте лучшую копию; удаление из библиотеки не трогает файл на диске.',
    );
    return '$_temp0';
  }

  @override
  String theFile(Object uri) {
    return 'файл\n$uri';
  }

  @override
  String get removeFromLibrary => 'Убрать из библиотеки';

  @override
  String get deleteFile => 'Удалить файл…';

  @override
  String mb(Object mb) {
    return '$mb МБ';
  }

  @override
  String get chooseCoverImage => 'Выберите изображение обложки';

  @override
  String get tagsSavedABackupOfThe =>
      'Теги сохранены (копия оригинала оставлена)';

  @override
  String get editTags2 => 'Изменить теги';

  @override
  String get changeCover => 'Сменить обложку…';

  @override
  String get removeCover => 'Убрать обложку';

  @override
  String get track => 'Трек';

  @override
  String get thisFormatOggCanOnlyBe =>
      'Этот формат (OGG) можно только читать, но не изменять.';

  @override
  String get saveToFile => 'Сохранить в файл';

  @override
  String get savePrismBackup => 'Сохранить копию Prism';

  @override
  String get backupSaved => 'Копия сохранена';

  @override
  String backupFailed(Object e) {
    return 'Не удалось сохранить копию: $e';
  }

  @override
  String get restorePrismBackup => 'Восстановить копию Prism';

  @override
  String restored2(Object report) {
    return 'Восстановлено: $report';
  }

  @override
  String restoreFailed(Object e) {
    return 'Не удалось восстановить: $e';
  }

  @override
  String get theVisualizerWorksWithSongsFrom =>
      'Визуализатор работает с песнями из библиотеки';

  @override
  String get analysingTheSong => 'Анализ песни';

  @override
  String get couldNotAnalyseThisSong => 'Не удалось проанализировать песню';

  @override
  String get theVisualizerNeedsFfmpegWhichIs =>
      'Визуализатору нужен FFmpeg, которого нет на этом устройстве';

  @override
  String get bars => 'Столбцы';

  @override
  String get mirror => 'Зеркало';

  @override
  String get radial => 'Круг';

  @override
  String get wave => 'Волна';

  @override
  String get vuMeters => 'VU-метры';

  @override
  String get waterfall => 'Водопад';

  @override
  String get ledMatrix => 'LED-матрица';

  @override
  String get low => 'НЧ';

  @override
  String thisDeviceSEqualizerHasBands(Object n, Object freqs, Object db) {
    return 'Эквалайзер устройства имеет полос: $n ($freqs Гц, ±$db дБ); кривая из 10 полос считывается на этих частотах. Усиление басов — системный эффект BassBoost, его кривая зависит от телефона. Некоторые телефоны и другие приложения-эквалайзеры (например, Wavelet) могут блокировать эффекты.';
  }

  @override
  String get changingEqBandsRebuildsTheLibmpv =>
      'Изменение полос эквалайзера перестраивает цепочку фильтров libmpv; быстрые движения сглаживаются, но возможен короткий щелчок.';

  @override
  String get livePitchShiftUsesResamplingTime =>
      'Живой сдвиг тона — это ресемплинг + растяжение (WSOLA); при экспорте используется rubberband, он звучит чище.';

  @override
  String get unknownSong => 'Неизвестная песня';

  @override
  String paused(Object who) {
    return 'Пауза · $who';
  }

  @override
  String get playingInPrism => 'Играет в Prism';

  @override
  String get paused2 => 'Пауза';

  @override
  String get openInAppleMusic => 'Открыть в Apple Music';

  @override
  String get openOnDeezer => 'Открыть в Deezer';

  @override
  String get thisDevice => 'Это устройство';

  @override
  String couldNotRead(Object path, Object e) {
    return 'Не удалось прочитать $path: $e';
  }

  @override
  String get topLevelMustBeAnObject => 'верхний уровень должен быть объектом';

  @override
  String noSongsFoundIn(Object file) {
    return 'В $file не найдено песен.';
  }

  @override
  String get theCsvFileHasNoSong => 'В файле CSV нет строк с песнями.';

  @override
  String get couldNotFindATitleColumn =>
      'Не найден столбец с названием. Ожидается заголовок вроде «Track name» или «Title».';

  @override
  String notValidJson(Object e) {
    return 'Неверный JSON: $e';
  }

  @override
  String get unknownJsonLayout => 'Неизвестная структура JSON.';

  @override
  String get couldNotFindASongList =>
      'Список песен в JSON не найден (ожидается «tracks», «items» или «playlists»).';

  @override
  String onlineServicesUnavailable(Object e) {
    return 'Онлайн-сервисы недоступны: $e';
  }

  @override
  String get dragOnTheWaveformToSelect => 'Сначала выделите часть на волне';

  @override
  String get saveAsNewTrack => 'Сохранить как новый трек';

  @override
  String get exportToFile => 'Экспорт в файл';

  @override
  String savedAndAddedToYourLibrary(Object path) {
    return 'Сохранено и добавлено в библиотеку:\n$path';
  }

  @override
  String get exportEdit => 'Экспорт правки';

  @override
  String get exported => 'Экспортировано';

  @override
  String exportFailed(Object e) {
    return 'Ошибка экспорта: $e';
  }

  @override
  String get editor => 'Редактор';

  @override
  String get readingWaveform => 'Чтение волны…';

  @override
  String get undoCtrlZ => 'Отменить (Ctrl+Z)';

  @override
  String get redoCtrlY => 'Повторить (Ctrl+Y)';

  @override
  String get saveExport => 'Сохранить / экспорт';

  @override
  String get saveAsNewTrack2 => 'Сохранить как новый трек…';

  @override
  String get exportToFile2 => 'Экспорт в файл…';

  @override
  String get playThisEditInThePlayer => 'Играть эту правку в плеере';

  @override
  String get livePresetTheOriginalFileIs =>
      'Живой пресет — исходный файл не меняется';

  @override
  String editedOriginal(Object a, Object b) {
    return 'Правка $a  ·  оригинал $b';
  }

  @override
  String selection(Object a, Object b) {
    return 'Выделение $a – $b';
  }

  @override
  String get xEdit3 => 'Правка';

  @override
  String get splitAtCursor => 'Разрезать у курсора';

  @override
  String get cut => 'Вырезать';

  @override
  String get trimToSelection => 'Обрезать по выделению';

  @override
  String get speed2 => 'Скорость…';

  @override
  String get speedPitchKept => 'Скорость (тон сохраняется)';

  @override
  String get pitch2 => 'Тон…';

  @override
  String get pitchSpeedKept => 'Тон (скорость сохраняется)';

  @override
  String get volume => 'Громкость…';

  @override
  String get volumeOfSelection => 'Громкость выделения';

  @override
  String get fadeIn => 'Нарастание…';

  @override
  String get fadeIn2 => 'Нарастание';

  @override
  String get fadeOut => 'Затухание…';

  @override
  String get fadeOut2 => 'Затухание';

  @override
  String get pausePreview => 'Остановить просмотр';

  @override
  String get playPreview => 'Прослушать';

  @override
  String get aOriginal => 'A  оригинал';

  @override
  String get bEdited => 'B  правка';

  @override
  String get apply => 'Применить';

  @override
  String get dragToSelectTapToMove =>
      'Тяните — выделить · нажатие — курсор · щипок или Ctrl+колесо — масштаб · колесо — прокрутка · Пробел — играть, Del — вырезать, Ctrl+Z / Ctrl+Y — отмена / повтор';

  @override
  String get keysLocalOnly =>
      'Ключи читаются только из этого локального файла (не хранятся ни в приложении, ни в репозитории). См. README → Online services.';

  @override
  String boostMayClip(Object db) {
    return 'Усиление на $db дБ может вызвать перегруз — уменьшите предусиление.';
  }

  @override
  String get limiterNote => '(В Windows пики срезает лимитер.)';

  @override
  String editedVsOriginal(Object a, Object b) {
    return 'Правка $a  ·  оригинал $b';
  }

  @override
  String oauthConnected(Object service) {
    return 'Подключено к $service';
  }

  @override
  String get oauthFailed => 'Не удалось войти';

  @override
  String get oauthCloseTab => 'Можно закрыть эту вкладку и вернуться в Prism.';

  @override
  String get oauthWrongState => 'Неверный state';

  @override
  String decade(Object year) {
    return '$year-е';
  }

  @override
  String connectedAsWithDetail(Object name, Object detail) {
    return 'Подключено: $name ($detail)';
  }

  @override
  String get langSystem => 'Как в системе';

  @override
  String get langTitle => 'Язык';

  @override
  String get langEnglish => 'English';

  @override
  String get langRussian => 'Русский';

  @override
  String get smartMostPlayed => 'Самые прослушиваемые';

  @override
  String get smartRecentlyAdded => 'Недавно добавленные';

  @override
  String get smartForgottenGems => 'Забытые жемчужины';

  @override
  String get eqPresetFlat => 'Ровно';

  @override
  String get eqPresetCustom => 'Свой';

  @override
  String get eqPresetBassBoost => 'Басы';

  @override
  String get eqPresetVocal => 'Вокал';

  @override
  String get eqPresetTreble => 'Высокие';

  @override
  String get eqPresetRock => 'Рок';

  @override
  String get eqPresetElectronic => 'Электроника';

  @override
  String get eqPresetPop => 'Поп';

  @override
  String get eqPresetHipHop => 'Хип-хоп';

  @override
  String get eqPresetJazz => 'Джаз';

  @override
  String get eqPresetClassical => 'Классика';

  @override
  String get eqPresetAcoustic => 'Акустика';

  @override
  String get eqPresetSpeech => 'Речь';

  @override
  String get trayShow => 'Открыть Prism';

  @override
  String get trayQuit => 'Выход';

  @override
  String hoursValue(Object h) {
    return '$h ч';
  }

  @override
  String get edTabEdit => 'Правка';

  @override
  String get edTabSegment => 'Фрагмент';

  @override
  String get edTabQuick => 'Быстро';

  @override
  String get edExport => 'Экспорт';

  @override
  String get edRippleDelete => 'Вырезать со сдвигом';

  @override
  String get edDeleteGap => 'Удалить, оставить паузу';

  @override
  String get edDuplicate => 'Дублировать';

  @override
  String get edLoopN => 'Повторить…';

  @override
  String get edLoopTitle => 'Повторить выделение';

  @override
  String get edReverse => 'Задом наперёд';

  @override
  String get edMerge => 'Склеить песни…';

  @override
  String get edMergeTitle => 'Добавить в конец';

  @override
  String edAddN(Object n) {
    return 'Добавить $n';
  }

  @override
  String get edAutoTrim => 'Убрать тишину по краям';

  @override
  String get edRemoveSilence => 'Убрать тишину внутри';

  @override
  String get edNormalize => 'Нормализовать пики';

  @override
  String get edLoudness => 'Выровнять громкость…';

  @override
  String get edLoudnessTitle => 'Целевая громкость';

  @override
  String get edNothingToDo => 'Здесь нечего делать';

  @override
  String get edRingtone => 'Сохранить как рингтон';

  @override
  String get edRingtoneSet => 'Поставить на звонок';

  @override
  String get edRingtoneDone => 'Рингтон установлен';

  @override
  String get edRingtoneAllow =>
      'Разрешите Prism менять системные настройки и нажмите ещё раз';

  @override
  String get edRingtoneSave => 'Сохранить рингтон';

  @override
  String get edMakingRingtone => 'Создание рингтона…';

  @override
  String get edRenderingPreset => 'Подготовка живого пресета…';

  @override
  String get edRenderingPreview => 'Подготовка прослушивания…';

  @override
  String get edLoopSel => 'Петля по выделению (L)';

  @override
  String get edFollow => 'Следовать за курсором';

  @override
  String get edSnapZero => 'Привязка к нулю сигнала';

  @override
  String get edSnapBeats => 'Привязка к долям';

  @override
  String get edSnapSilence => 'Привязка к тишине';

  @override
  String get edZoomIn => 'Приблизить (+)';

  @override
  String get edZoomOut => 'Отдалить (-)';

  @override
  String edSegmentN(Object n, Object total) {
    return 'Фрагмент $n из $total';
  }

  @override
  String get edRamp => 'Плавное изменение скорости';

  @override
  String get edRampTo => 'Скорость в конце';

  @override
  String get edVolume => 'Громкость';

  @override
  String get edCrossfadeNext => 'Кроссфейд со следующим';

  @override
  String get edCurve => 'Кривая';

  @override
  String get edCurveLinear => 'Линейная';

  @override
  String get edCurveSmooth => 'Плавная';

  @override
  String get edCurveS => 'S-образная';

  @override
  String get edCurveFast => 'Быстрый старт';

  @override
  String get edCurveSlow => 'Медленный старт';

  @override
  String get edEq => 'Эквалайзер';

  @override
  String get edMid => 'СЧ';

  @override
  String get edHigh => 'ВЧ';

  @override
  String get edGate => 'Шумовой гейт';

  @override
  String get edGateHint => 'Глушит всё, что тише заданного уровня';

  @override
  String get edGateLevel => 'Уровень';

  @override
  String get edVbr => 'Переменный битрейт (VBR)';

  @override
  String edVbrQuality(Object q) {
    return 'Качество $q (0 лучшее, 9 самый маленький файл)';
  }

  @override
  String edBitrate(Object kbps) {
    return '$kbps кбит/с';
  }

  @override
  String edWavBits(Object bits) {
    return '$bits бит';
  }

  @override
  String edFlacLevel(Object n) {
    return 'Сжатие $n';
  }

  @override
  String get edApplyEq => 'Применить общий эквалайзер';

  @override
  String get edKeepTags => 'Сохранить теги и обложку';

  @override
  String get edKeepCover => 'Оставить обложку';

  @override
  String get edOverwrite => 'Заменить оригинал (копия сохранится)';

  @override
  String edOverwriteDone(Object path) {
    return 'Оригинал заменён. Копия: $path';
  }

  @override
  String edOverwriteUnsupported(Object ext) {
    return 'Файлы $ext нельзя заменить, сохраните как новый трек';
  }

  @override
  String edOverwriteFailed(Object e) {
    return 'Не удалось заменить файл, оригинал возвращён: $e';
  }

  @override
  String get edHelpDesktop =>
      'Тяните — выделить, тяните край — подправить, клик — курсор, двойной клик выделяет фрагмент. Колесо — прокрутка, Ctrl+колесо — масштаб. Пробел — играть, S — разрезать, Del — вырезать со сдвигом, Shift+Del — удалить с паузой, T — обрезать, R — задом наперёд, L — петля, B — A/B, Ctrl+D — дублировать, Ctrl+A — выделить всё, Ctrl+E — экспорт, Ctrl+Z / Ctrl+Y — отмена / повтор, стрелки — курсор, + - 0 — масштаб.';

  @override
  String get edHelpTouch =>
      'Тяните — выделить, тяните край — подправить, нажатие — курсор, двойное нажатие выделяет фрагмент. Щипок — масштаб, двумя пальцами — прокрутка. Зажмите блок под волной, чтобы переместить его.';

  @override
  String lyricsError(Object e) {
    return 'Ошибка текста: $e';
  }

  @override
  String get lyricsOffsetTitle => 'Смещение текста';

  @override
  String get lyricsOffsetHint =>
      'Плюс показывает строки раньше, минус позже. Сохраняется для этой песни.';

  @override
  String get vizRibbon => 'Лента';

  @override
  String get vizParticles => 'Частицы';

  @override
  String get vizGlow => 'Свечение';

  @override
  String get vizSensitivity => 'Чувствительность';

  @override
  String get vizLowPower => 'Экономный визуализатор';

  @override
  String get vizLowPowerHint => '30 кадров в секунду и меньше деталей';

  @override
  String get vizLive => 'Живой спектр';

  @override
  String get vizLiveHint =>
      'Реагирует на то, что реально играет, включая стримы и эквалайзер. Android требует для этого разрешение на микрофон; Prism ничего не записывает.';

  @override
  String get vizLiveRefused =>
      'Разрешение не выдано, визуализатор продолжит анализировать файл';

  @override
  String get metaTitle => 'Исправить данные песни';

  @override
  String get metaFix => 'Исправить данные…';

  @override
  String get metaFixAlbum => 'Исправить данные этих песен';

  @override
  String get metaSearchAll => 'Найти для всех';

  @override
  String get metaSaveAll => 'Сохранить всё';

  @override
  String get metaSave => 'Сохранить в файл';

  @override
  String get metaResearch => 'Искать снова';

  @override
  String get metaNothingFound =>
      'Ничего не найдено. Попробуйте другие слова выше или введите данные вручную.';

  @override
  String get metaCandidates => 'Найдено';

  @override
  String get metaUseCover => 'Использовать эту обложку';

  @override
  String metaSavedN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сохранено $count песни, копии оригиналов оставлены',
      many: 'Сохранено $count песен, копии оригиналов оставлены',
      few: 'Сохранено $count песни, копии оригиналов оставлены',
      one: 'Сохранена $count песня, копия оригинала оставлена',
    );
    return '$_temp0';
  }

  @override
  String metaSaveFailed(Object e) {
    return 'Не удалось сохранить: $e';
  }

  @override
  String get yandexChanged =>
      'Яндекс Музыка ответила неожиданно. Официального API у неё нет, поэтому это может сломаться в любой момент. Экспортируйте плейлист в CSV или JSON и импортируйте файл.';

  @override
  String get yandexNeedsToken =>
      'Для этого нужен ваш токен Яндекс Музыки: Настройки → Онлайн-сервисы.';

  @override
  String get yandexPlaylist => 'Плейлист Яндекс Музыки';

  @override
  String get yandexLikes => 'Любимые песни (Яндекс Музыка)';

  @override
  String get yandexLabel => 'Яндекс Музыка';

  @override
  String get yandexDescribe =>
      'Экспериментально, официального API нет. Публичные ссылки, ваши плейлисты и лайки по вашему токену. Только названия песен, без аудио.';

  @override
  String get yandexTokenTitle => 'Ваш токен Яндекс Музыки';

  @override
  String get yandexTokenSteps =>
      'Нужен только для ваших плейлистов и лайков; публичные ссылки работают без него.\n\n1. Откройте инструкцию ниже.\n2. Выполните шаги для браузера, войдя в свой аккаунт Яндекса.\n3. Скопируйте токен и вставьте сюда.';

  @override
  String get yandexOpenGuide => 'Открыть инструкцию (сообщество)';

  @override
  String get yandexToken => 'Токен';

  @override
  String get yandexTokenPrivate =>
      'Токен даёт доступ к вашему аккаунту Яндекса: никому его не передавайте. Prism хранит его в защищённом хранилище системы и отправляет только на api.music.yandex.net.';

  @override
  String get yandexTermsTitle => 'Яндекс Музыка — неофициально, только импорт';

  @override
  String get yandexTermsText =>
      'Публичного API у Яндекса нет. Prism читает названия песен через закрытый API его приложений (описан сообществом в проекте yandex-music-api), который может измениться или перестать работать без предупреждения и отвечает только из некоторых стран. Публичные ссылки читаются при импорте, аккаунт остаётся выключенным, пока вы его не включите. Для личного использования. Prism никогда не скачивает и не воспроизводит аудио Яндекса. Если перестанет работать, импортируйте экспорт в CSV или JSON.';

  @override
  String regionBlocked(Object service) {
    return '$service недоступен из вашей страны или сети (блокирует сам сервис). Экспортируйте плейлист в CSV или JSON и импортируйте файл.';
  }

  @override
  String get setUpYandexToken => 'Вставить токен';

  @override
  String get shareTitle => 'Поделиться плейлистом';

  @override
  String shareHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Отправьте этот код другу. В нём названия $count песни, без аудио и путей к файлам; Prism найдёт их в его библиотеке или подключённых сервисах.',
      many:
          'Отправьте этот код другу. В нём названия $count песен, без аудио и путей к файлам; Prism найдёт их в его библиотеке или подключённых сервисах.',
      few:
          'Отправьте этот код другу. В нём названия $count песен, без аудио и путей к файлам; Prism найдёт их в его библиотеке или подключённых сервисах.',
      one:
          'Отправьте этот код другу. В нём название $count песни, без аудио и путей к файлам; Prism найдёт её в его библиотеке или подключённых сервисах.',
    );
    return '$_temp0';
  }

  @override
  String get shareLong =>
      'Код длинный, некоторые мессенджеры могут его обрезать. Если так, отправьте файл.';

  @override
  String get shareSaveFile => 'Сохранить файл .liner';

  @override
  String get shareSaved => 'Файл сохранён';

  @override
  String get shareButton => 'Поделиться';

  @override
  String get shareBadCode =>
      'Код повреждён или обрезан. Попросите его ещё раз или файл .liner.';

  @override
  String get shareNewerVersion =>
      'Этот код создан более новой версией Prism. Обновите приложение, чтобы открыть его.';

  @override
  String get shareTooBig => 'Этот плейлист слишком большой.';

  @override
  String get shareEmpty => 'В этом коде нет песен.';

  @override
  String get shareDefaultName => 'Плейлист от друга';

  @override
  String get shareRecognized => 'Плейлист от друга';

  @override
  String orderSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано $count',
      many: 'Выбрано $count',
      few: 'Выбрано $count',
      one: 'Выбрана $count',
    );
    return '$_temp0';
  }

  @override
  String get orderMoveTop => 'В начало';

  @override
  String get orderMoveBottom => 'В конец';

  @override
  String get orderSelect => 'Выбрать несколько';

  @override
  String get orderSort => 'Сортировка';

  @override
  String get orderCustom => 'Мой порядок';

  @override
  String orderSortedHint(Object by) {
    return 'Сортировка: $by. Ваш порядок сохранён.';
  }

  @override
  String get orderBackToCustom => 'Вернуть мой порядок';

  @override
  String get orderKeepThis => 'Сделать моим порядком';

  @override
  String get statsNewVsRepeat => 'Новое и повторы';

  @override
  String statsNewVsRepeatNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни услышаны впервые',
      many: '$count песен услышаны впервые',
      few: '$count песни услышаны впервые',
      one: '$count песня услышана впервые',
    );
    return '$_temp0';
  }

  @override
  String get statsNewPlays => 'Открытия';

  @override
  String get statsRepeatPlays => 'Знакомые песни';

  @override
  String get statsStoryPlay => 'Показать как историю';

  @override
  String get statsSaveImage => 'Сохранить карточку как картинку';

  @override
  String get statsImageSaved => 'Картинка сохранена';

  @override
  String statsMinutesUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'минуты',
      many: 'минут',
      few: 'минуты',
      one: 'минута',
    );
    return '$_temp0';
  }

  @override
  String statsDaysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дня подряд',
      many: 'дней подряд',
      few: 'дня подряд',
      one: 'день подряд',
    );
    return '$_temp0';
  }

  @override
  String get statsWrappedNew => 'Вы открыли для себя';

  @override
  String statsNewSongsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'новые песни',
      many: 'новых песен',
      few: 'новые песни',
      one: 'новую песню',
    );
    return '$_temp0';
  }

  @override
  String get bgMesh => 'Сетка цветов';

  @override
  String get bgMeshDesc => 'Мягкие цвета медленно перетекают друг в друга.';

  @override
  String get bgAurora => 'Северное сияние';

  @override
  String get bgAuroraDesc => 'Занавеси света плывут по тёмному небу.';

  @override
  String get bgBlobs => 'Жидкие капли';

  @override
  String get bgBlobsDesc =>
      'Формы сливаются и делятся, как в лавовой лампе, и надуваются от басов.';

  @override
  String get bgGradient => 'Градиент';

  @override
  String get bgGradientDesc =>
      'Неподвижный градиент. Выберите пресет ниже. После отрисовки не тратит энергию.';

  @override
  String get bgStarfield => 'Звёздное поле';

  @override
  String get bgStarfieldDesc => 'Полёт сквозь звёзды, быстрее на басах.';

  @override
  String get bgRain => 'Дождь';

  @override
  String get bgRainDesc => 'Тонкий падающий дождь. Мышь работает как ветер.';

  @override
  String get bgSnow => 'Снег';

  @override
  String get bgSnowDesc => 'Снежинки падают слоями.';

  @override
  String get bgGrain => 'Плёночное зерно';

  @override
  String get bgGrainDesc => 'Тихий цветной градиент с подвижным зерном.';

  @override
  String get bgImage => 'Моя картинка';

  @override
  String get bgImageDesc =>
      'Ваша картинка за приложением. Ниже можно размыть и затемнить.';

  @override
  String get bgVideo => 'Моё видео';

  @override
  String get bgVideoDesc =>
      'Первые 30 секунд вашего видео как беззвучная петля, 12 кадров в секунду.';

  @override
  String get bgChooseImage => 'Выбрать картинку…';

  @override
  String get bgChooseVideo => 'Выбрать видео…';

  @override
  String get bgPreparingVideo => 'Подготовка видео…';

  @override
  String get bgVideoFailed =>
      'Не удалось прочитать это видео на этом устройстве.';

  @override
  String get bgPresets => 'Пресеты';

  @override
  String get bgDim => 'Затемнение';

  @override
  String get bgParallax => 'Параллакс';

  @override
  String get bgParallaxHint => 'Фон немного сдвигается вслед за мышью';

  @override
  String get bgBatterySaver => 'Экономия батареи';

  @override
  String get bgBatterySaverHint =>
      '20 кадров в секунду, меньше деталей, без размытия и матовых панелей';

  @override
  String get bgPresetDusk => 'Сумерки';

  @override
  String get bgPresetOcean => 'Океан';

  @override
  String get bgPresetForest => 'Лес';

  @override
  String get bgPresetEmber => 'Угли';

  @override
  String get bgPresetIce => 'Лёд';

  @override
  String get bgPresetGraphite => 'Графит';

  @override
  String get bgPresetRose => 'Роза';

  @override
  String get bgPresetNight => 'Ночь';

  @override
  String get bgDensity => 'Плотность';

  @override
  String get bgSize => 'Размер';

  @override
  String get updateCheck => 'Проверить обновления';

  @override
  String get updateAuto => 'Проверять при запуске';

  @override
  String get updateAutoHint =>
      'Раз в день спрашивает у GitHub последнюю версию';

  @override
  String get updateChecking => 'Проверка обновлений…';

  @override
  String updateNone(Object version) {
    return 'У вас последняя версия ($version)';
  }

  @override
  String updateFailed(Object reason) {
    return 'Не удалось проверить обновления: $reason';
  }

  @override
  String updateAvailable(Object version) {
    return 'Вышла версия $version';
  }

  @override
  String get updateHowTo =>
      'Скачайте новый установщик или APK и установите поверх этой версии. Библиотека и настройки сохранятся.';

  @override
  String get updateOpen => 'Открыть страницу загрузки';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get privacyNoLocationTitle =>
      'Prism не определяет ваше местоположение';

  @override
  String get privacyNoLocationText =>
      'Нет аналитики, телеметрии, рекламы и отчётов о сбоях. Нет идентификатора устройства. У Prism нет своих аккаунтов и серверов.';

  @override
  String get privacyPermsTitle => 'Разрешения Android';

  @override
  String get privacyPermMusic => 'Музыка и аудиофайлы';

  @override
  String get privacyPermMusicWhy =>
      'Чтобы читать вашу музыку. Запрашивается, когда вы добавляете папку.';

  @override
  String get privacyPermPlayback => 'Воспроизведение в фоне';

  @override
  String get privacyPermPlaybackWhy =>
      'Чтобы музыка играла при выключенном экране.';

  @override
  String get privacyPermNotify => 'Уведомления';

  @override
  String get privacyPermNotifyWhy => 'Только уведомление плеера с кнопками.';

  @override
  String get privacyPermInternet => 'Интернет и состояние сети';

  @override
  String get privacyPermInternetWhy =>
      'Для запросов из списка ниже и чтобы знать, есть ли сеть.';

  @override
  String get privacyPermMic => 'Микрофон (только живой визуализатор)';

  @override
  String get privacyPermMicWhy =>
      'Android относит свой визуализатор к микрофону. Запрашивается, только когда вы его включаете. Prism ничего не записывает.';

  @override
  String get privacyPermRingtone =>
      'Изменение системных настроек (только рингтон)';

  @override
  String get privacyPermRingtoneWhy =>
      'Чтобы поставить рингтон из редактора. Вы разрешаете это на системном экране, когда пользуетесь функцией.';

  @override
  String get privacyPermsFooter =>
      'Никогда не запрашиваются: местоположение, Bluetooth, данные Wi-Fi, состояние телефона, контакты, аккаунты, рекламный идентификатор.';

  @override
  String get privacyWindowsTitle => 'Windows';

  @override
  String get privacyWindowsText =>
      'Не требует особых разрешений и не использует службу определения местоположения Windows. До версии 1.2 одна библиотека запускала её при старте, поэтому Windows могла показывать, что Prism использует местоположение. Prism не читал и не отправлял результат, эта библиотека удалена.';

  @override
  String get privacySentTitle => 'Что покидает устройство';

  @override
  String get privacySentFooter =>
      'Каждый сервер видит ваш IP-адрес, как при любом запросе в интернет. Prism никогда не выясняет, где находится этот адрес.';

  @override
  String get privacySentUpdates => 'Проверка обновлений: GitHub';

  @override
  String get privacySentUpdatesWhat =>
      'Отправляется версия приложения. Автоматически, отключается в разделе «О программе».';

  @override
  String get privacySentInfo => 'Недостающие данные: Apple, Deezer';

  @override
  String get privacySentInfoWhat =>
      'Отправляются название и исполнитель. Автоматически, отключается в разделе «Библиотека».';

  @override
  String get privacySentLyrics => 'Тексты песен: LRCLIB';

  @override
  String get privacySentLyricsWhat =>
      'Отправляются название, исполнитель, альбом и длина песни, для которой вы открыли текст.';

  @override
  String get privacySentFonts => 'Шрифт: Google Fonts';

  @override
  String get privacySentFontsWhat =>
      'Шрифт приложения скачивается один раз. Ничего о вас и вашей музыке не отправляется.';

  @override
  String get privacySentImport =>
      'Импорт: Spotify, YouTube, SoundCloud, Deezer, Apple Music, Яндекс Музыка';

  @override
  String get privacySentImportWhat =>
      'Только при импорте: ссылка, которую вы указали. Скопированная ссылка остаётся на устройстве, пока вы не нажмёте «Импорт».';

  @override
  String get privacySentOnline => 'Онлайн-песни: YouTube, SoundCloud';

  @override
  String get privacySentOnlineWhat =>
      'Если вы их включили: поиск песен и то, что вы слушаете.';

  @override
  String get privacySentFixer =>
      'Исправление данных: MusicBrainz, Cover Art Archive, Apple, AcoustID';

  @override
  String get privacySentFixerWhat =>
      'Когда вы им пользуетесь: название, исполнитель, альбом. AcoustID только с вашим ключом.';

  @override
  String get privacySentTogether =>
      'Совместное прослушивание: публичные серверы или ваш Wi-Fi';

  @override
  String get privacySentTogetherWhat =>
      'Во время сеанса: что играет и имя, которое вы указали. Без имени вы показываетесь как «Кто-то», а не именем компьютера.';

  @override
  String get privacySentDiscord => 'Статус в Discord';

  @override
  String get privacySentDiscordWhat =>
      'Если Discord запущен на этом компьютере: песня, которую вы слушаете.';

  @override
  String get privacyFullText => 'Подробнее о конфиденциальности';

  @override
  String get privacyContinue => 'Продолжить';

  @override
  String get vizLiveAskTitle => 'Android спросит про микрофон';

  @override
  String get vizLiveAskText =>
      'Живой визуализатор использует Visualizer API, который Android относит к микрофону. Prism читает только звук, который играет сам. Ничего не записывается и не отправляется.';

  @override
  String get removeFromPrism => 'Убрать из Prism';

  @override
  String get removeFromPrismHint => 'Файл останется на диске';

  @override
  String removeFromPrismAsk(String title) {
    return 'Убрать «$title» из Prism?';
  }

  @override
  String get removeFromPrismText =>
      'Песня исчезнет из библиотеки, плейлистов, избранного и статистики Prism. Файл останется на диске, и при сканировании она больше не появится. Вернуть её можно в Настройках → Библиотека.';

  @override
  String get removeFromPrismDone => 'Убрано из Prism. Файл остался на диске.';

  @override
  String get undoAction => 'Отменить';

  @override
  String get removedSongs => 'Убранные песни';

  @override
  String removedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песен скрыто в Prism',
      few: '$count песни скрыты в Prism',
      one: '$count песня скрыта в Prism',
      zero: 'Ничего не убрано',
    );
    return '$_temp0';
  }

  @override
  String get removedSongsHelp =>
      'Файлы этих песен остались на диске. «Вернуть» добавит песню в библиотеку при сканировании, которое запустится сразу. Старая статистика и места в плейлистах не вернутся.';

  @override
  String get restoreAction => 'Вернуть';

  @override
  String get importSupported =>
      'Spotify, YouTube, SoundCloud, Яндекс Музыка, Apple Music или Deezer. Публичные ссылки работают без аккаунта.';

  @override
  String get importFileOrDrop =>
      'Или перетащите сюда файл: CSV, JSON, M3U, .liner';

  @override
  String get importFileHint => 'Или выберите файл: CSV, JSON, M3U, .liner';

  @override
  String get importDropHere => 'Отпустите, чтобы импортировать';

  @override
  String get importClipboardAsk => 'Импортировать этот плейлист?';

  @override
  String get importRecent => 'Недавние импорты';

  @override
  String get importResync => 'Синхронизировать';

  @override
  String get importSynced => 'Синхронизация с источником';

  @override
  String get importAccept => 'Песня верная';

  @override
  String importAcceptAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Принять все $count',
      few: 'Принять все $count',
      one: 'Принять $count',
    );
    return '$_temp0';
  }

  @override
  String get importReview => 'Проверка';

  @override
  String get importReviewEmpty =>
      'Проверять нечего. Песни, в которых Prism не уверен, будут ждать здесь.';

  @override
  String importReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песен на проверку',
      few: '$count песни на проверку',
      one: '$count песня на проверку',
    );
    return '$_temp0';
  }

  @override
  String get importReviewHint => 'Одно нажатие, чтобы принять или исправить';

  @override
  String get importAdvanced => 'Дополнительно: подключить аккаунт';

  @override
  String get importAdvancedHint =>
      'Необязательно. Только для личных плейлистов, любимых треков и длинных списков Spotify.';

  @override
  String get importNotConnected => 'Не подключено';

  @override
  String get importOneScreenHint => 'Из ссылки или файла, на одном экране';

  @override
  String get importOnlyLibrarySearched =>
      'Поиск шёл только по вашей библиотеке. Если включить YouTube, Prism поищет остальное там.';

  @override
  String get importFindOnYoutube => 'Найти остальное на YouTube';

  @override
  String get importSearchAgain => 'Снова поискать ненайденные песни';

  @override
  String get importStepsSpotify =>
      'Для личных плейлистов и любимых треков. Публичные ссылки уже работают.\n1. Откройте developer.spotify.com/dashboard и создайте приложение с Web API.\n2. Добавьте redirect URI http://127.0.0.1:43821/callback.\n3. Скопируйте Client ID.\n4. В разделе «Онлайн-сервисы» нажмите «Создать файл», вставьте его как spotify.clientId, нажмите «Обновить», затем подключитесь.';

  @override
  String get importStepsYoutube =>
      'Для личных плейлистов и понравившихся видео. Публичные ссылки уже работают.\n1. Откройте console.cloud.google.com и создайте проект с YouTube Data API v3.\n2. Добавьте себя тестовым пользователем на экране согласия OAuth.\n3. Создайте OAuth-клиент типа Desktop app.\n4. В разделе «Онлайн-сервисы» нажмите «Создать файл», вставьте youtube.oauthClientId и youtube.oauthClientSecret, нажмите «Обновить», затем подключитесь.';

  @override
  String get importStepsSoundcloud =>
      'Ссылкам SoundCloud это нужно, либо экспортируйте плейлист в файл.\n1. Откройте soundcloud.com/you/apps и зарегистрируйте приложение. SoundCloud может потребоваться его одобрить.\n2. Добавьте redirect URI http://127.0.0.1:43822/callback.\n3. В разделе «Онлайн-сервисы» нажмите «Создать файл», вставьте soundcloud.clientId и soundcloud.clientSecret, нажмите «Обновить».';

  @override
  String get importStepsYandex =>
      'Для своих плейлистов и любимых треков. Публичные ссылки уже работают там, где отвечает Яндекс.\n1. Откройте «Онлайн-сервисы» и включите Яндекс Музыку.\n2. Нажмите «Подключить» и следуйте шагам, чтобы получить токен.\n3. Вставьте токен. Он хранится в защищённом хранилище этого устройства.';

  @override
  String get importErrorOffline =>
      'Похоже, нет интернета. Проверьте подключение и попробуйте снова.';

  @override
  String importErrorSlowDown(String service) {
    return '$service просит подождать. Подождите несколько минут и попробуйте снова.';
  }

  @override
  String importErrorServer(String service) {
    return 'У $service сейчас проблемы. Попробуйте позже.';
  }

  @override
  String get importErrorPrivate =>
      'Этот плейлист закрыт или удалён. Сделайте его публичным или экспортируйте в файл и импортируйте его.';

  @override
  String importErrorRegion(String service) {
    return '$service не отвечает из вашей страны или сети. Экспортируйте плейлист в файл CSV или JSON и импортируйте его.';
  }

  @override
  String importErrorAccount(String service) {
    return 'Этот список закрыт, поэтому $service нужен ваш аккаунт. Подключите его или экспортируйте файл.';
  }

  @override
  String importErrorNeedsKey(String service) {
    return 'Для ссылок $service нужен бесплатный ключ, либо экспортируйте плейлист в файл.';
  }

  @override
  String importErrorCantRead(String service) {
    return 'Не удалось прочитать страницу $service. Возможно, она изменилась. Экспортируйте плейлист в файл и импортируйте его.';
  }

  @override
  String importErrorFile(String problem) {
    return '$problem Prism читает файлы CSV, JSON, M3U и .liner.';
  }

  @override
  String importErrorFileGone(String path) {
    return 'Файла больше нет по адресу $path. Выберите его снова.';
  }

  @override
  String get importErrorUnknown =>
      'При чтении что-то пошло не так. Попробуйте экспортировать плейлист в файл.';

  @override
  String importSkipNotFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пропустить $count ненайденных',
      few: 'Пропустить $count ненайденные',
      one: 'Пропустить $count ненайденную',
    );
    return '$_temp0';
  }

  @override
  String get seekBarCustomize => 'Настроить полосу перемотки';

  @override
  String get seekBarOwnColor => 'Свой цвет';

  @override
  String get seekBarOwnColorHint => 'Выключено: полоса следует теме';

  @override
  String get seekBarColor => 'Цвет';

  @override
  String get seekBarSize => 'Высота';

  @override
  String get seekBarDensity => 'Количество полос';

  @override
  String get seekBarThickness => 'Толщина';

  @override
  String get seekBarDim => 'Яркость непроигранной части';

  @override
  String get seekBarReact => 'Реакция на музыку';

  @override
  String get seekBarHead => 'Показывать указатель';

  @override
  String get seekBarTimes => 'Показывать время';

  @override
  String get seekBarReset => 'Сбросить настройки полосы';

  @override
  String get importDownloadAsk => 'Скачать песни в Prism?';

  @override
  String get importDownloadTerms =>
      'Prism находит каждую песню на YouTube и сохраняет звук в файл внутри приложения, поэтому песня остаётся в библиотеке и играет без интернета. Это нарушает правила YouTube: только для себя, файлы никому не передавайте. Функция может перестать работать в любой момент.';

  @override
  String get importOnlyLibrary => 'Искать только в библиотеке';

  @override
  String get importDownloadSwitch => 'Скачивать песни в Prism';

  @override
  String get importDownloadSwitchHint =>
      'С YouTube, автоматически. Только для личного использования.';

  @override
  String get importDownloadSongs => 'Скачать песни';

  @override
  String get importTryAgainSongs => 'Повторить для несохранённых песен';

  @override
  String importDownloading(int done, String title) {
    return 'Сохранено: $done. Сейчас: $title';
  }

  @override
  String importDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песен сохранено в библиотеке',
      few: '$count песни сохранены в библиотеке',
      one: '$count песня сохранена в библиотеке',
      zero: 'Нечего сохранять',
    );
    return '$_temp0';
  }

  @override
  String importDownloadFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не удалось сохранить $count песен.',
      few: 'Не удалось сохранить $count песни.',
      one: 'Не удалось сохранить $count песню.',
    );
    return '$_temp0';
  }

  @override
  String get togetherFindOnYoutube => 'Найти недостающие песни на YouTube';

  @override
  String get togetherOr => 'или';

  @override
  String importRetryIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Сам попробует снова через $minutes минут.',
      few: 'Сам попробует снова через $minutes минуты.',
      one: 'Сам попробует снова через $minutes минуту.',
    );
    return '$_temp0';
  }
}
