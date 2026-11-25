# Music Player

A Flutter music player with a now-playing screen, a reorderable Up Next queue,
local audio import, and a three-band equalizer.

## Architecture

- `lib/main.dart` creates the audio and equalizer services and exposes them to
  the widget tree with Provider.
- `lib/services/audio_service.dart` owns the `just_audio` player and playlist.
  It handles playback controls, queue reordering, audio-session setup, local
  file import, saved-file restoration, metadata, and track durations.
- `lib/services/eq_service.dart` adapts the device equalizer to the app's
  three-band model.
- `lib/models/track.dart` describes tracks, including
  their metadata, embedded artwork, and fallback artwork gradients.
- `lib/screens/` contains the player and equalizer screens. Reusable playback,
  artwork, queue, and EQ controls live in `lib/widgets/`.
- `lib/theme.dart` contains the shared colors, theme extension, and slider
  styling.

The player screen keeps its playback controls in place while the Up Next list
scrolls and reorders independently. Imported audio files are copied into the
app's documents directory, and their paths are saved with `shared_preferences`
so the library can be restored on a later launch.

## Equalizer

The player attaches a `just_audio` `AndroidEqualizer` effect to its audio
pipeline. After the audio source loads, `EqService` enables the effect and
reads the device's available frequency bands and supported gain range.

The UI presents Low, Mid, and High sliders. Device bands are grouped by their
center frequencies: below 250 Hz is Low, 250 Hz through 4 kHz is Mid, and
above 4 kHz is High. Moving a slider applies its gain to every device band in
that group. The UI targets -12 to +12 dB and clamps this range to the
equalizer's supported limits. “Reset to Flat” sets all three gains to 0 dB.

Equalizer availability depends on the platform and device. If the native effect
is unavailable, the equalizer screen reports that state and disables the
sliders; audio playback remains separate from the EQ controls.

## Packages

| Package | Use |
| --- | --- |
| `provider` | Exposes the audio and equalizer services to widgets. |
| `just_audio` | Audio playback, playlists, position streams, and the Android equalizer effect. |
| `audio_session` | Configures the audio session for music playback. |
| `rxdart` | Combines playback position and duration streams for the seek bar. |
| `file_picker` | Lets the user select audio files from the device. |
| `path_provider` | Locates the app documents directory for imported audio. |
| `shared_preferences` | Persists imported audio file paths between launches. |
| `metatagger` | Reads local audio tags and embedded album artwork. |
| `palette_generator` | Derives fallback artwork colors from imported cover art. |
| `cupertino_icons` | Provides the Cupertino icon font dependency. |
| `flutter_test` | Widget testing. |
| `flutter_lints` | Dart and Flutter lint rules. |

Flutter's Material widgets provide the application UI.

## Run the app

Prerequisites: Flutter and the platform toolchain for the device or emulator.
The Dart SDK constraint is `^3.13.5` (see `pubspec.yaml`).

```sh
flutter pub get
flutter run
```

The app starts with an empty library; no sample or dummy tracks are included.
Use **Add songs** to import audio from the device. Imported files are copied to
the app's documents directory and restored on later launches.

The native equalizer is Android-specific. On platforms or devices where it
isn't available, playback controls remain usable and the EQ screen displays an
availability message.

## Validate

```sh
flutter analyze
flutter test
```

## Challenges and decisions

- **Device-specific EQ bands:** Devices may expose different band counts and
  gain limits. The service groups hardware bands by center frequency, clamps
  gain to the supported range, and handles unavailable effects without
  preventing playback.
- **Local file reliability:** Picker-provided paths may not be suitable for
  long-term use, so imported files are copied into app-managed storage and
  their paths are restored on startup.
- **Variable metadata and artwork:** Audio files may lack tags or cover art.
  The player uses filename-based title fallbacks and generated gradients when
  artwork is unavailable; embedded artwork is shown when present.
- **Queue and compact layouts:** Reordering updates the playback playlist
  while preserving the currently playing track. The queue has its own scroll
  area so it does not move the full player page.

## Use of AI tools

- **Figma** was used for design generation.
- **Claude** was used to generate the initial application code.
- **Copilot** was used for debugging and ongoing application development.
