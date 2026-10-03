import 'package:flutter/material.dart';

/// A small circular prev/next button used both inside [MediaCarousel] (over
/// the inline carousel) and inside [MediaFullViewer] (over the full-screen
/// pager) — the original app had two near-identical widgets for this
/// (`ArrowButton` and a second one used only by the full viewer); this is
/// the one shared version, with [size] exposed so each call site can pick
/// its own scale instead of needing a second class.
class MediaNavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const MediaNavArrow({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 35,
    this.backgroundColor = Colors.black54,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.68,
        ),
      ),
    );
  }
}
