/// Online covers come in several sizes; links saved by Prism (or handed out by
/// a service) often point at a small one. These turn a link into the largest
/// version the same service offers. Links Prism doesn't know stay as they are.
library;

final _yt = RegExp(r'^(https?://i\d?\.ytimg\.com/vi(?:_webp)?/[\w-]+/)(default|mqdefault|hqdefault|sddefault)(\.\w+)');
final _deezer = RegExp(r'/(\d{2,4})x\d{2,4}-(\d{6}-\d{2}-\d-\d\.(?:jpg|png))$');
final _itunes = RegExp(r'/(\d{2,4})x(\d{2,4})(bb|bf|cc|-\d+)?\.(jpg|png|webp)$');
final _soundcloud = RegExp(r'-(large|t300x300|crop|t67x67|badge|small|tiny|mini)\.(jpg|png)$');

/// The largest cover behind [url]. YouTube's largest one is missing for some
/// videos: pair it with [fallbackCoverUrl].
String sharperCoverUrl(String url) {
  if (_yt.hasMatch(url)) return url.replaceFirstMapped(_yt, (m) => '${m[1]}maxresdefault${m[3]}');
  if (url.contains('dzcdn.net') && _deezer.hasMatch(url)) {
    return url.replaceFirstMapped(_deezer, (m) => '/1000x1000-${m[2]}');
  }
  if (url.contains('mzstatic.com') && _itunes.hasMatch(url)) {
    return url.replaceFirstMapped(_itunes, (m) => '/1200x1200${m[3] ?? 'bb'}.${m[4]}');
  }
  if (url.contains('sndcdn.com') && _soundcloud.hasMatch(url)) {
    return url.replaceFirstMapped(_soundcloud, (m) => '-t500x500.${m[2]}');
  }
  return url;
}

/// What to show when [sharperCoverUrl]'s link doesn't load: YouTube's middle
/// size always exists and has no black bars (the 4:3 sizes do). Null when
/// there's nothing better than the original link.
String? fallbackCoverUrl(String url) {
  final m = _yt.firstMatch(url);
  return m == null ? null : '${m[1]}mqdefault${m[3]}';
}
