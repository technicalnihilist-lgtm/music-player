# Glass Player

A frosted-glass music player for Android. Play the songs already on your phone inside a liquid
glass card that floats over animated colour blobs — with spring physics on every tap, a live
colour shift tied to the current track, and a playlist that slides with the album art.

The whole interface is one self-contained HTML file rendered in a full-screen Android WebView,
so what you see here is exactly what runs on the device.

**[Download the APK](https://github.com/technicalnihilist-lgtm/music-player/releases/latest)** · Requires Android 7.0 (API 24) or newer

## Screenshots

| Now playing | Playlist | Glass options |
|:---:|:---:|:---:|
| <img src="screenshots/01-now-playing.webp" width="250"> | <img src="screenshots/02-playlist.webp" width="250"> | <img src="screenshots/03-glass-options.webp" width="250"> |

## Features

- **Liquid glass card** — layered translucency, 28px backdrop blur, saturate boost, inset
  highlights and a diagonal sheen, all sitting on three drifting colour blobs.
- **Colour follows the song** — every track carries a hue; the album art, the blob field and the
  glass tint shift together, and the hue is adjustable live from the options sheet.
- **Real audio** — pick any audio file from your phone with the system file picker. Nothing is
  uploaded anywhere; playback is local.
- **Spring animations** — the player pops in from the bottom, collapses into a floating bubble on
  close, and the album art wipes sideways with a blur when you change track.
- **Playlist** — tap a row to jump to a track, the current row shows an animated equaliser.
- **Glass options sheet** — drag transparency, blur radius and colour shift with live preview.
- **Light and dark** — follows the system theme, and the dark theme is the signature look.

## Install

1. Download `GlassPlayer.apk` from the [releases page](https://github.com/technicalnihilist-lgtm/music-player/releases/latest).
2. On your phone, open the file and allow "install from unknown sources" for your browser or file manager.
3. Launch **Glass Player**, tap **Add songs** and pick audio files from your device.

The APK is signed with a self-signed debug key, so Play Protect may ask you to confirm the install.

## Project layout

```
source/index.html                 the entire player UI (HTML + CSS + JS)
android/app/src/main/assets/      the same file, shipped inside the APK
android/app/src/main/java/         MainActivity: full-screen WebView host
android/app/src/main/res/          manifest resources, layout, launcher icon
android/build.sh                   builds and signs the APK without Gradle
```

## Build it yourself

You need JDK 17 and the Android SDK (platform 34 + build-tools 34.0.0). No Gradle required —
the build script drives `aapt2`, `javac`, `d8`, `zipalign` and `apksigner` directly.

```bash
export ANDROID_SDK_ROOT=/path/to/android-sdk
bash android/build.sh
# -> android/app/build/GlassPlayer.apk
```

To change the UI, edit `source/index.html`, copy it to
`android/app/src/main/assets/index.html`, and rebuild.

## Notes

- Package name: `com.glassplayer.app` · version 1.0 · minSdk 24 · targetSdk 34
- The app requests no permissions and has no network access; audio is read only through the
  system file picker you invoke yourself.
- `source/index.html` also runs in any browser if you want to try the UI without installing.
