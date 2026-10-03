import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_multimedia/rich_multimedia.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the file name and a type-matched icon', (tester) async {
    await tester.pumpWidget(
      wrap(const FilePlaceholder(url: 'https://x.com/report.pdf')),
    );

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
  });

  testWidgets('overrideIcon wins over the extension-derived icon', (tester) async {
    await tester.pumpWidget(
      wrap(const FilePlaceholder(
        url: 'https://x.com/clip.mp4',
        overrideIcon: Icons.play_circle_outline_rounded,
      )),
    );

    expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.insert_drive_file), findsNothing);
  });

  testWidgets('strips a query string from the displayed file name', (tester) async {
    await tester.pumpWidget(
      wrap(const FilePlaceholder(url: 'https://x.com/notes.txt?v=3')),
    );

    expect(find.text('notes.txt'), findsOneWidget);
  });
}
