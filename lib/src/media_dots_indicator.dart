import 'package:flutter/material.dart';

/// Dot-indicator row for a media carousel — capped at 3 visible dots with
/// an ellipsis dot standing in for the rest once there are more pages than
/// that. Already model-agnostic in the app this was extracted from (it had
/// already been pulled out once there to stop a near-identical dot-drawing
/// loop from being reimplemented inline wherever a plain dot row — no
/// lock/download/caption bar — was needed), so it ports over unchanged
/// beyond the import.
class MediaDotsIndicator extends StatelessWidget {
  final int total;
  final int currentIndex;
  final void Function(int index) onDotTap;
  final Color activeColor;
  final Color inactiveColor;

  const MediaDotsIndicator({
    super.key,
    required this.total,
    required this.currentIndex,
    required this.onDotTap,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xFF3a3a3a),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _buildDots(),
    );
  }

  List<Widget> _buildDots() {
    final List<Widget> dots = [];

    if (total <= 3) {
      for (int i = 0; i < total; i++) {
        dots.add(_buildDot(i, i == currentIndex));
      }
    } else {
      dots.add(_buildDot(0, 0 == currentIndex));

      if (currentIndex <= 1) {
        dots.add(_buildDot(1, 1 == currentIndex));
        dots.add(_buildEllipsisDot());
        dots.add(_buildDot(total - 1, false));
      } else if (currentIndex >= total - 2) {
        dots.add(_buildEllipsisDot());
        dots.add(_buildDot(total - 2, total - 2 == currentIndex));
        dots.add(_buildDot(total - 1, total - 1 == currentIndex));
      } else {
        dots.add(_buildEllipsisDot());
        dots.add(_buildDot(currentIndex, true));
        dots.add(_buildEllipsisDot());
        dots.add(_buildDot(total - 1, false));
      }
    }

    return dots;
  }

  Widget _buildDot(int index, bool isActive) {
    return GestureDetector(
      onTap: () => onDotTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 5),
        width: isActive ? 18 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildEllipsisDot() {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: inactiveColor,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
