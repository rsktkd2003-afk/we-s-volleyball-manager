import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/widgets/player_list.dart';
import 'support/fake_repositories.dart';

void main() {
  for (final count in [30, 300]) {
    testWidgets('roster layout measurement $count', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final players = List.generate(
        count,
        (i) => testPlayer(id: '$i', name: 'Player $i', number: i),
      );
      if (Platform.environment['CAPTURE_UI'] == '1') {
        await tester.runAsync(() async {
          for (final entry in {
            'Roboto': 'C:/Windows/Fonts/meiryo.ttc',
            'MaterialIcons':
                'C:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          }.entries) {
            final font = FontLoader(entry.key)
              ..addFont(
                File(
                  entry.value,
                ).readAsBytes().then((b) => ByteData.sublistView(b)),
              );
            await font.load();
          }
        });
      }
      final boundary = GlobalKey();
      final elapsed = Stopwatch()..start();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PlayerList(
                  players: players,
                  onTap: (_) {},
                  onAddPlayer: () {},
                ),
              ),
            ),
          ),
        ),
      );
      elapsed.stop();
      debugPrint(
        'ROSTER_LAYOUT count=$count elapsed_us=${elapsed.elapsedMicroseconds}',
      );
      expect(tester.takeException(), isNull);
      if (Platform.environment['CAPTURE_UI'] == '1' && count == 30) {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '../../outputs/roster-preview.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
