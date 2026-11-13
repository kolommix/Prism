# Privacy

**Prism does not read your location.** It has no analytics, no telemetry, no ads and no crash reporting. It sends no
device id or advertising id, and it has no account or server of its own.

The same text is in the app: Settings → Privacy. `tool/privacy_check.dart` fails the build if this list stops being true.

## The location report (fixed in 1.2.0)
Versions before 1.2.0 could show up in Windows as using location. The cause was a library, `permission_handler_windows`:
as soon as the app started, it created a Windows `Geolocator` and subscribed to its position updates. Prism never read
the result and never sent it anywhere, but Windows counted it as location use. Prism only needs that library's Android
half, so the Windows part is gone.

## Android permissions
| Permission | Why | When |
|---|---|---|
| `READ_MEDIA_AUDIO` (Android 13+), `READ_EXTERNAL_STORAGE` (Android 12 and older) | Reads your music files | Asked when you add a folder |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK` | Keeps music playing with the screen off | Granted at install |
| `POST_NOTIFICATIONS` | The player notification | Asked by Android |
| `INTERNET`, `ACCESS_NETWORK_STATE` | The requests listed below; the audio player and background work check whether you are online | Granted at install |
| `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS` | Live visualizer and audio effects. Android files its Visualizer API under the microphone. Prism records nothing | Asked, with an explanation, when you turn on the live visualizer |
| `WRITE_SETTINGS` | Sets a ringtone made in the editor | You allow it on a system screen when you use it |

Pictures for "import from a photo" come through the share sheet or the system picker, which hand over only the
pictures you chose: no storage or camera permission.

Removed on purpose, also if a library asks for them: all location permissions, Bluetooth, Wi-Fi state, phone state,
contacts, accounts, advertising id, start at boot.

## Windows
The installer asks for no capabilities and needs no admin rights. The app does not use the Windows location API.
Prism runs at "above normal" priority so music doesn't stutter on a busy PC (Settings → Windows → Smooth when the PC is
busy). That changes nothing about what Prism can read or send.
Hotkeys (Settings → Windows → Hotkeys) are registered with Windows one combination at a time: Prism hears only those
combinations, never other keys you type.

## What leaves the device
Every server below sees your IP address, as with any internet request. Prism never looks up where that address is and
never sends it anywhere itself.

### Automatic, can be turned off
| Where | What is sent | Why | Turn off |
|---|---|---|---|
| `api.github.com` | App version | Update check | Settings → About |
| `www.msftconnecttest.com`, `connectivitycheck.gstatic.com` | Nothing: the addresses Windows and Android themselves use for their own "am I online" check | Only after an online service failed, to say "the internet works, but this service can't be reached" instead of "offline". Both are asked, one answer is enough | Not switchable (only happens after a failure) |
| The failed service's own address (for YouTube also `redirector.googlevideo.com`) | Nothing: an empty request | Only after that service failed during an import, to see whether it is blocked on your network, so the import says so at once instead of after minutes | Not switchable (only happens after a failure) |
| `itunes.apple.com`, `api.deezer.com` | Song title and artist (Russian names also to Apple's Russian store) | Finds missing covers and artists | Settings → Library → Missing info |
| `lrclib.net` | Title, artist, album, length | Lyrics of the song you play | Don't open lyrics |
| `fonts.gstatic.com` (Google Fonts) | Nothing but the font request | Downloads the app font once | Not switchable |

### Only when you use the feature
| Feature | Where | What is sent |
|---|---|---|
| Import from a photo | Nothing: the song names are read on the device (Windows' own text recognition; on Android, Tesseract inside the app) | The names found are then matched like any import (see the next rows) |
| Import from a link | `open.spotify.com`, `api.spotify.com`, `youtube.com`, `googleapis.com`, `soundcloud.com`, `api.deezer.com`, `music.apple.com`, `api.music.yandex.net` | The link you import |
| Matching, playing and saving online songs (if you turn it on) | YouTube, SoundCloud | Song title and artist searches, the songs you play or save |
| Saving songs on Windows (if you turn it on) | `api.github.com`, `github.com` (yt-dlp's official release) | Nothing about you: Prism fetches a newer yt-dlp when there is none or saving fails and the copy is over a day old, and checks it against the release's SHA-256 list |
| Updating from inside Prism | `github.com` (Prism's own release) | Nothing about you: the installer or APK of the new version, checked against GitHub's size and SHA-256 before it runs |
| Accounts (optional) | Spotify, Google, SoundCloud, Yandex | Login through the service. Tokens stay in the system keychain |
| Song info fixer | `musicbrainz.org`, `coverartarchive.org`, `itunes.apple.com`, `api.acoustid.org` (only with your own key) | Title, artist, album; an audio fingerprint for AcoustID |
| Listen together, by code | `broker.emqx.io`, `broker.hivemq.com` (public servers) | Scrambled with the session code: what is playing (with its YouTube video id when known), position, the name you typed, whether you have the song, and what a friend asks the host to play. Without a name you appear as "Someone", never your computer's name. Never file paths |
| Listen together, same Wi-Fi | Your local network | Session code, name, song name |
| Discord status (if Discord runs) | Discord on this computer | The song you play |
| Shared playlists | Nothing is uploaded | The `liner://` link holds song names and public links, never file paths |

### Clipboard
The Import screen looks at your clipboard while it is open, on this device only, to offer a copied playlist link.
Nothing is sent until you tap Import. On Android, the system shows its usual "pasted" notice.
On Windows, when Prism comes to the front it also looks for a copied listen-together invite (a message with "Prism"
and a session code) and asks whether to join. Nothing is sent unless you click Join.

### Proxy
Prism's web requests go the way your browser's do: through the proxy set in Windows (Settings → Network → Proxy) or in
`HTTPS_PROXY`, if there is one. Home network addresses always go direct.

## Stored on your device
Library, playlists, settings and stats stay in the app's own folder. Keys you add stay in a local `online_config.json`.
