import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_multimedia/rich_multimedia.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders one dot per page when total <= 3', (tester) async {
    await tester.pumpWidget(
      wrap(MediaDotsIndicator(total: 3, currentIndex: 1, onDotTap: (_) {})),
    );

    final dots = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(dots.length, 3);
  });

  testWidgets('caps visible dots with an ellipsis once total > 3', (tester) async {
    await tester.pumpWidget(
      wrap(MediaDotsIndicator(total: 10, currentIndex: 5, onDotTap: (_) {})),
    );

    // First dot + ellipsis + current dot + ellipsis + last dot = 3 real dots,
    // same capped-dots behavior as the app this was extracted from.
    final dots = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(dots.length, 3);
  });

  testWidgets('tapping a dot calls onDotTap with its index', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      wrap(MediaDotsIndicator(
        total: 2,
        currentIndex: 0,
        onDotTap: (i) => tapped = i,
      )),
    );

    final gestures = find.byType(GestureDetector);
    await tester.tap(gestures.last);
    expect(tapped, 1);
  });
}
