import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/widgets/cover_urls.dart';

void main() {
  test('YouTube: the largest picture, the middle one as the fallback', () {
    const mq = 'https://i.ytimg.com/vi/jbZT-bwZD3c/mqdefault.jpg';
    expect(sharperCoverUrl(mq), 'https://i.ytimg.com/vi/jbZT-bwZD3c/maxresdefault.jpg');
    expect(fallbackCoverUrl(mq), mq);
    expect(sharperCoverUrl('https://i9.ytimg.com/vi/abc/hqdefault.jpg'), 'https://i9.ytimg.com/vi/abc/maxresdefault.jpg');
    expect(fallbackCoverUrl('https://i.ytimg.com/vi/abc/hqdefault.jpg'), 'https://i.ytimg.com/vi/abc/mqdefault.jpg',
        reason: 'the 4:3 sizes have black bars');
  });

  test('Deezer, iTunes and SoundCloud: their largest sizes', () {
    expect(
      sharperCoverUrl('https://e-cdns-images.dzcdn.net/images/cover/0a1b2c/250x250-000000-80-0-0.jpg'),
      'https://e-cdns-images.dzcdn.net/images/cover/0a1b2c/1000x1000-000000-80-0-0.jpg',
    );
    expect(
      sharperCoverUrl('https://is1-ssl.mzstatic.com/image/thumb/Music/v4/aa/bb/source/100x100bb.jpg'),
      'https://is1-ssl.mzstatic.com/image/thumb/Music/v4/aa/bb/source/1200x1200bb.jpg',
    );
    expect(sharperCoverUrl('https://i1.sndcdn.com/artworks-000123-abc-large.jpg'),
        'https://i1.sndcdn.com/artworks-000123-abc-t500x500.jpg');
  });

  test('links it does not know stay as they are', () {
    for (final u in [
      'https://i.scdn.co/image/ab67616d0000b273abc',
      'https://example.com/250x250-cover.jpg',
      r'C:\covers\a.jpg',
    ]) {
      expect(sharperCoverUrl(u), u);
      expect(fallbackCoverUrl(u), isNull);
    }
  });
}
