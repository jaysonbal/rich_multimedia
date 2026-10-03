import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_multimedia/rich_multimedia.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows a download button and calls onDownload when unlocked',
      (tester) async {
    bool downloaded = false;
    await tester.pumpWidget(
      wrap(MediaCarouselFooter(
        total: 3,
        currentIndex: 0,
        currentFileName: 'a.jpg',
        onDotTap: (_) {},
        onDownload: () => downloaded = true,
        downloadLocked: false,
      )),
    );

    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.download_rounded));
    expect(downloaded, isTrue);
  });

  testWidgets('shows a locked placeholder with a tooltip instead, when locked',
      (tester) async {
    await tester.pumpWidget(
      wrap(MediaCarouselFooter(
        total: 3,
        currentIndex: 0,
        currentFileName: 'a.jpg',
        onDotTap: (_) {},
        onDownload: () {},
        downloadLocked: true,
        lockedTooltip: 'Not yet available',
      )),
    );

    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsNothing);

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Not yet available');
  });

  testWidgets('hides the download affordance entirely when hideDownloadButton',
      (tester) async {
    await tester.pumpWidget(
      wrap(MediaCarouselFooter(
        total: 3,
        currentIndex: 0,
        currentFileName: 'a.jpg',
        onDotTap: (_) {},
        onDownload: () {},
        hideDownloadButton: true,
      )),
    );

    expect(find.byIcon(Icons.download_rounded), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });

  testWidgets('renders the caption only when non-empty', (tester) async {
    await tester.pumpWidget(
      wrap(MediaCarouselFooter(
        total: 1,
        currentIndex: 0,
        currentFileName: 'a.jpg',
        onDotTap: (_) {},
        onDownload: () {},
        caption: 'A real caption',
      )),
    );
    expect(find.text('A real caption'), findsOneWidget);

    await tester.pumpWidget(
      wrap(MediaCarouselFooter(
        total: 1,
        currentIndex: 0,
        currentFileName: 'a.jpg',
        onDotTap: (_) {},
        onDownload: () {},
        caption: '   ',
      )),
    );
    expect(find.text('   '), findsNothing);
  });
}
