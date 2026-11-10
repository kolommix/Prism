PRISM
=====

English · Русский (README.ru.md)

Prism is a music player for your own music files, on Windows and Android. I made it for myself and a few friends. It's free, has no ads and needs no account.

Download the latest version (https://github.com/kolommix/Prism/releases/latest)

HOW TO INSTALL
--------------

On Windows 10 or 11:

1. Open the download page (https://github.com/kolommix/Prism/releases/latest) and download Prism-Setup-1.1.0.exe (the number may be higher).
2. Open the file.
3. Windows will probably say "Windows protected your PC". That's because the installer isn't paid-signed, not because something was found in it. Click More info, then Run anyway.
4. Click through the installer. You don't need admin rights.
5. Open Prism and choose the folder with your music. That's it.

On Android 7 or newer:

1. On your phone, open the download page (https://github.com/kolommix/Prism/releases/latest).
2. Download Prism-1.1.0-arm64-v8a.apk. This fits almost every phone from the last 8 years. If it won't install, use Prism-1.1.0.apk, which is bigger but works on everything.
3. Open the file. Android will ask if this app may install apps: allow it, go back, and tap Install.
4. Open Prism, allow access to music, and tap Add folder.

If Play Protect warns you, tap Install anyway. The app isn't on Google Play, so it warns about it.

Updating:

Prism tells you when there's a new version (you can also check in Settings → About). Download the new file and install it over the old one. Your music, playlists and settings stay.

Removing it:

- Windows: Settings → Apps → Prism → Uninstall. Your library data stays in %APPDATA%\com.kolommix\prism; delete that folder too if you want it gone.
- Android: remove it like any other app.

WHAT IT CAN DO
--------------

- Play your music: mp3, flac, m4a, ogg and wav, with covers, playlists, search and smart playlists
- Sound: 10-band equalizer, speed and pitch, crossfade, sleep timer
- Lyrics: synced lyrics that follow the song, found online or from your .lrc files
- Edit songs: cut, join, speed up, reverse, fade, and make ringtones. Your original file stays safe unless you choose to replace it
- Fix song info: look up the right title, artist, album and cover, one song or a whole album
- Listen together: share a short code and friends hear the same song at the same time, from their own files
- Bring your playlists: import from Spotify, YouTube, SoundCloud, Deezer, Apple Music, Yandex Music or a file
- Share playlists: send a friend a code or a .liner file
- See your stats: top songs, listening streaks and a yearly recap you can save as pictures
- Make it yours: themes, animated backgrounds, your own picture or video, visualizers, English or Russian

Online features are optional. Some need setup: see setting up online services (docs/ONLINE_SERVICES.md).

WHAT DOESN'T WORK PERFECTLY
---------------------------

- Android gets less testing than Windows, so you may find bugs there. Please tell me if you do.
- Yandex Music import has never been tried for real, because Yandex blocks the computer it was built on. There's no official way to connect to it, so it may just not work. Exporting your playlist to a CSV file and importing that is the backup plan.
- YouTube playback goes against YouTube's rules, so it's off by default. Use it only for yourself, and expect it to break sometimes.
- Spotify only gives song names, never audio. Prism looks for those songs in your files or on other services.
- Listen together needs everyone to have the song, or an online service turned on. Song names go through a free public server, scrambled. You can turn that off.
- The visualizer on Windows doesn't react to the equalizer or speed, and doesn't work on streamed songs.
- On Android, the live visualizer asks for microphone permission, because Android requires it for that feature. Nothing is recorded, and it's off unless you turn it on.
- Video backgrounds are silent and loop the first 30 seconds.
- It's big: about 260 MB on Windows, because the audio tools come with it.

FOR DEVELOPERS
--------------

- Build: Flutter 3.47, then powershell -File tool\fetch_windows_deps.ps1 and flutter build windows --release
- How it's built: docs/ARCHITECTURE.md
- Publishing a version: docs/RELEASING.md

License: GPL-3.0, see LICENSE. Bundled tools keep their own licenses, see third_party/README.md.
