import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'media_kind.dart';

/// One pinch-to-zoom image page inside [MediaFullViewer]. Renders from the
/// local filesystem when [mediaUrl] is a local path, otherwise loads it as
/// a cached network image with a shimmer placeholder.
class ImageItemWidget extends StatelessWidget {
  const ImageItemWidget({
    super.key,
    required this.mediaUrl,
    required this.onTap,
  });

  final String mediaUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocal = MediaClassifier.isLocalPath(mediaUrl);

    return GestureDetector(
      onTap: onTap,
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 3.0,
        child: Center(
          child: isLocal
              ? Image.file(
                  File(mediaUrl),
                  fit: BoxFit.contain,
                )
              : CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.contain,
                  progressIndicatorBuilder: (context, url, progress) =>
                      Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: const Color(0xFFEEEEEE),
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
        ),
      ),
    );
  }
}
