import 'package:flutter/material.dart';

import 'media_kind.dart';

/// Generic "this is a file" tile: an icon derived from the file's
/// extension plus its name, centered. Used as the fallback for any media
/// kind this package doesn't render inline (a `.docx`, `.zip`, etc.) and
/// as the error fallback when a PDF fails to load.
class FilePlaceholder extends StatelessWidget {
  final String url;
  final IconData? overrideIcon;
  final Color iconColor;
  final Color textColor;

  const FilePlaceholder({
    super.key,
    required this.url,
    this.overrideIcon,
    this.iconColor = Colors.blueGrey,
    this.textColor = const Color(0xFF888888),
  });

  @override
  Widget build(BuildContext context) {
    final fileName = MediaClassifier.getFileName(url);
    final icon = overrideIcon ?? MediaClassifier.getFileIcon(fileName);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 50, color: iconColor),
          const SizedBox(height: 10),
          Text(
            fileName,
            style: TextStyle(color: textColor, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
