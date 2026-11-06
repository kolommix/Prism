import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart' show Element, WidgetsBinding;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'gen/app_localizations.dart';
import 'gen/app_localizations_en.dart';

export 'gen/app_localizations.dart';

/// The app's strings in the current language. A plain global instead of
/// `AppLocalizations.of(context)` because plenty of text comes from code
/// without a context (errors from online services, enum labels, the player).
/// [applyAppLocale] rebuilds the whole tree when the language changes.
AppLocalizations l10n = AppLocalizationsEn();

/// Locale for a saved choice: '' = system language, else 'en' / 'ru'.
/// Anything that isn't supported falls back to English.
Locale resolveAppLocale(String code, [Locale? system]) {
  bool ok(String c) => AppLocalizations.supportedLocales.any((l) => l.languageCode == c);
  if (code.isNotEmpty && ok(code)) return Locale(code);
  final sys = system ?? PlatformDispatcher.instance.locale;
  return ok(sys.languageCode) ? Locale(sys.languageCode) : const Locale('en');
}

/// Makes [locale] current; returns true if it changed.
bool setAppLocale(Locale locale) {
  if (l10n.localeName == locale.languageCode) return false;
  l10n = lookupAppLocalizations(locale);
  Intl.defaultLocale = locale.languageCode;
  return true;
}

/// Loads date symbols for all languages (call once before `runApp`).
Future<void> initAppLocaleData() async {
  _dateDataReady = true;
  await initializeDateFormatting();
}

/// Rebuilds every widget (like a hot reload, keeps all state), so text that was
/// built before a language switch is built again.
void rebuildAllWidgets() {
  void visit(Element el) {
    el.markNeedsBuild();
    el.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
}

bool _dateDataReady = false;

String _safe(String pattern, DateTime d) {
  if (!_dateDataReady) {
    _dateDataReady = true;
    // Fills the tables synchronously (the Future is only there for the API).
    initializeDateFormatting();
  }
  return DateFormat(pattern, l10n.localeName).format(d);
}

String _clean(String s) => s.endsWith('.') ? s.substring(0, s.length - 1) : s;

/// "Jan" / "янв", [month] 1-12.
String monthShort(int month) => _clean(_safe('LLL', DateTime(2024, month.clamp(1, 12))));

/// "Mon" / "пн", [weekday] 1 = Monday.
String weekdayShort(int weekday) => _clean(_safe('E', DateTime(2024, 1, weekday.clamp(1, 7))));

/// "5 Mar" / "5 мар".
String dateShort(DateTime d) => '${d.day} ${_clean(_safe('MMM', d))}';

/// "Mar 2026" / "мар 2026".
String monthYear(DateTime d) => '${monthShort(d.month)} ${d.year}';

/// 24-hour "14:05".
String timeShort(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// A number with the language's decimal mark ("12.5" / "12,5").
String fmtNum(num value, [int digits = 0]) {
  try {
    return NumberFormat.decimalPatternDigits(locale: l10n.localeName, decimalDigits: digits).format(value);
  } on Object {
    return value.toStringAsFixed(digits);
  }
}

/// Built-in EQ presets are saved by their English name; this shows them in the
/// current language (the user's own presets stay as typed).
String eqPresetLabel(String name) => switch (name) {
      'Flat' => l10n.eqPresetFlat,
      'Custom' => l10n.eqPresetCustom,
      'Bass Boost' => l10n.eqPresetBassBoost,
      'Vocal' => l10n.eqPresetVocal,
      'Treble' => l10n.eqPresetTreble,
      'Rock' => l10n.eqPresetRock,
      'Electronic' => l10n.eqPresetElectronic,
      'Pop' => l10n.eqPresetPop,
      'Hip-Hop' => l10n.eqPresetHipHop,
      'Jazz' => l10n.eqPresetJazz,
      'Classical' => l10n.eqPresetClassical,
      'Acoustic' => l10n.eqPresetAcoustic,
      'Speech' => l10n.eqPresetSpeech,
      _ => name,
    };

/// The seeded smart playlists are saved by their English name.
String smartPlaylistLabel(String name) => switch (name) {
      'Most played' => l10n.smartMostPlayed,
      'Recently added' => l10n.smartRecentlyAdded,
      'Forgotten gems' => l10n.smartForgottenGems,
      _ => name,
    };

/// True for the placeholder name in any language: refs from a friend's device
/// may carry it in their language, and it must never be searched for as a name.
bool isUnknownArtist(String name) =>
    name.isEmpty || AppLocalizations.supportedLocales.any((l) => lookupAppLocalizations(l).unknownArtist == name);
