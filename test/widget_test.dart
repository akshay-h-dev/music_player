// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:music_player/main.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/services/eq_service.dart';

void main() {
  testWidgets('app starts with an empty library', (WidgetTester tester) async {
    final audio = AudioService(tracks: const []);
    addTearDown(audio.dispose);
    final eq = EqService(audio.equalizer);
    addTearDown(eq.dispose);

    await tester.pumpWidget(MusicPlayerApp(audio: audio, eq: eq));

    expect(find.text('No tracks'), findsOneWidget);
    expect(find.text('Up Next'), findsOneWidget);
    expect(find.text('No tracks in queue'), findsOneWidget);
  });
}
