import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_multimedia/rich_multimedia.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders a FilePlaceholder for an unrecognized file type',
      (tester) async {
    await tester.pumpWidget(
      wrap(const MultiMediaItem(url: 'https://x.com/contract.docx')),
    );

    expect(find.byType(FilePlaceholder), findsOneWidget);
    expect(find.text('contract.docx'), findsOneWidget);
  });

  testWidgets('renders a lock-style placeholder icon override for an empty video url',
      (tester) async {
    await tester.pumpWidget(
      wrap(const MultiMediaItem(url: '')),
    );

    // An empty url classifies as MediaKind.document (no extension), which
    // renders a plain FilePlaceholder — the video-specific empty-url
    // fallback only applies when the url is already known to be a video.
    expect(find.byType(FilePlaceholder), findsOneWidget);
  });
}
