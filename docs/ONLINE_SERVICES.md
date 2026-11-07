# Setting up online services

All of this is optional. Prism works fine with only your own music files.

Settings → **Online services**. Every service has its own switch; if one is
broken or not set up, everything else keeps working.

| What | Needs | Status |
|---|---|---|
| Import from files: CSV (Exportify, TuneMyMusic, any title/artist columns), JSON, M3U/M3U8, `.liner` | nothing | ✅ |
| Import public Spotify links (the public embed page, about 100 songs at most) | nothing | ✅ best effort, *personal use* |
| Import public YouTube / YouTube Music links (playlist page, oEmbed for one video) | nothing | ✅ best effort, *personal use* |
| Import Deezer playlist/album links | nothing | ✅ |
| Import Apple Music playlist/album links (reads the public web page) | nothing | ✅ best effort, *personal use* |
| Import public Yandex Music links | nothing, only where Yandex answers (HTTP 451 elsewhere) | ✅ best effort, *personal use* |
| Save imported songs as files in Prism (from YouTube, asks first) | switch on the Import screen | ✅ *personal use*, against YouTube's Terms, don't share the files |
| Import SoundCloud links | `soundcloud.clientId` (its pages hold almost no songs without a key) or a file | needs your key |
| YouTube / YouTube Music: search, playlist links, **playback**, offline copies | switch on **YouTube extractor** | ✅ *personal use* |
| YouTube search/playlists via the official API | `youtube.apiKey` | needs your key |
| Your YouTube playlists + liked videos | Google OAuth client | needs your key |
| Spotify: your playlists, liked songs, saved albums (text only) | `spotify.clientId` | needs your key |
| SoundCloud: search, likes, playlists, playback | `soundcloud.clientId` (+ secret) | needs your key |

Prism **never plays Spotify, Deezer or Apple Music audio**. Imported songs are
matched: your own files first, then YouTube / SoundCloud (title + artist +
length). Each match shows a confidence (High / Medium / Low – check it) and
has a **Fix** button. Matching runs in the background, saves progress per song,
pauses when you go offline or a service limits you, and continues with
*Resume*. Duplicates inside one list are skipped (you can turn that off in
the preview).

### API keys
Keys live in a local file, never in the app or this repo. Settings → Online
services → **Create file** makes it (path shown there; template:
[`online_config.example.json`](online_config.example.json)), fill it in, tap **Reload**.
`online_config.json` is gitignored. Logins (tokens) are stored in the system
keychain (Windows Credential Manager / Android Keystore).

- **Spotify**: <https://developer.spotify.com/dashboard> → Create app → Web API,
  redirect URI `http://127.0.0.1:43821/callback` → copy the **Client ID**
  (no secret needed, Prism uses PKCE). Development Mode apps work for **at most
  5 people**: add your friends' Spotify e-mails under *User Management*. Spotify
  only lets such apps read playlists the user **owns or collaborates on** –
  for other playlists use Exportify / TuneMyMusic and import the CSV.
- **YouTube Data API** (optional, the extractor works without it):
  <https://console.cloud.google.com> → new project → enable *YouTube Data API v3*
  → Credentials → API key → `youtube.apiKey`. Free quota ≈ 100 searches/day.
  For your own playlists/likes: OAuth consent screen (External, Testing, add
  yourself as test user) → Credentials → OAuth client ID → *Desktop app* →
  `youtube.oauthClientId` + `youtube.oauthClientSecret`.
- **SoundCloud**: <https://soundcloud.com/you/apps> → register an app (SoundCloud
  may need to approve it), redirect URI `http://127.0.0.1:43822/callback` →
  `soundcloud.clientId` + `soundcloud.clientSecret`.

### Terms of service – what is allowed
| Service | What Prism does | Rules |
|---|---|---|
| Spotify | Web API, reads your library as text | Allowed for non-commercial apps; Development Mode = 5 users. No audio is ever taken from Spotify. **Personal use only.** |
| YouTube Data API | search, playlists, your likes (official) | Allowed with your key and quota. No audio in this API. |
| YouTube extractor | playback, keyless search, offline copies (youtube_explode_dart) | **Against YouTube's Terms** (no playback outside their player, no downloads). Off by default. **Personal use only** – don't share saved files; may break any time. |
| SoundCloud | official API: search, likes, playlists, streaming | Only tracks the uploader made streamable; credited and linked to SoundCloud; no offline copies. |
| Deezer | public API, playlist/album text | Non-commercial use. |
| Apple Music | reads the public playlist/album web page | No free API exists; scraping is a grey area. Off by default, best effort. **Personal use only.** |

The same notes are in the app (Settings → Online services → *What each service allows*).

### When something goes wrong
- *"YouTube asks to slow down"*: too many searches from your connection. Wait
  (minutes to an hour), then *Resume* the import. Prism already spaces searches out.
- *Offline*: local songs and offline copies still play; online search shows
  "offline" per service; imports pause and resume later.
- A streamed song that can't play (removed video, service switched off) is
  skipped with a short message.
