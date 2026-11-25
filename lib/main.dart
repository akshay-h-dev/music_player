import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/player_screen.dart';
import 'services/audio_service.dart';
import 'services/eq_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final audio = AudioService(tracks: const []);
  final eq = EqService(audio.equalizer);

  runApp(MusicPlayerApp(audio: audio, eq: eq));

  // The equalizer needs a loaded player, so init it after the tracks.
  await audio.init();
  await eq.init();
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key, required this.audio, required this.eq});
  final AudioService audio;
  final EqService eq;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioService>.value(value: audio),
        ChangeNotifierProvider<EqService>.value(value: eq),
      ],
      child: const _MusicPlayerAppView(),
    );
  }
}

class _MusicPlayerAppView extends StatelessWidget {
  const _MusicPlayerAppView();

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AudioService>().currentTrack.themeColor;
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(accent: accent),
      home: const PlayerScreen(),
    );
  }
}
