import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_app/widgets/wes_app_bar.dart';

void main() {
  Widget buildApp({
    VoidCallback? onTapSettings,
    VoidCallback? onTapProfile,
  }) {
    return MaterialApp(
      home: Scaffold(
        appBar: WesAppBar(
          onTapSettings: onTapSettings,
          onTapProfile: onTapProfile,
        ),
      ),
    );
  }

  testWidgets('設定ボタンのタップを通知する', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      buildApp(onTapSettings: () => tapCount++),
    );

    await tester.tap(find.byTooltip('設定'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('プロフィールボタンのタップを通知する', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      buildApp(onTapProfile: () => tapCount++),
    );

    await tester.tap(find.byTooltip('プロフィール'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('設定ボタンから画面遷移できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            appBar: WesAppBar(
              onTapSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('設定画面')),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('設定'));
    await tester.pumpAndSettle();

    expect(find.text('設定画面'), findsOneWidget);
  });
}
