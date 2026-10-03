// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'file_placeholder.dart';
import 'in_memory_audio_player.dart';
import 'in_memory_pdf_viewer.dart';
import 'media_full_viewer.dart';
import 'media_kind.dart';
import 'screenshot_protection.dart';
import 'video_preview_widget.dart';

/// A single media tile that renders the right preview for whatever
/// [url] is (image / video / audio / pdf / other file), and opens
/// [MediaFullViewer] on tap — the one widget most apps actually reach for.
///
/// Pass [mediaUrls] + [index] when this tile is one of several (e.g. a
/// carousel page) so tapping it opens the full viewer already positioned
/// on the right item with the rest swipeable; omit them for a standalone
/// tile and the viewer opens with just this one media item.
class MultiMediaItem extends StatelessWidget {
  final String url;
  final List<String>? mediaUrls;
  final int? index;
  final double? playBtnSize;

  /// Whether tapping through to the full viewer should also turn on
  /// screenshot/screen-recording protection for as long as it's open.
  /// Defaults to true, matching the app this was extracted from, since a
  /// media viewer showing someone else's content (reviews, bookings,
  /// portfolios) is a reasonable default to protect; set to false if your
  /// use case doesn't need it or you'd rather not pull in the
  /// `no_screenshot` plugin's platform permissions.
  final bool protectFromScreenshots;

  /// Accent color used by the full viewer's video scrub bar when this tile
  /// opens it.
  final Color accentColor;

  const MultiMediaItem({
    super.key,
    required this.url,
    this.mediaUrls,
    this.index,
    this.playBtnSize = 70,
    this.protectFromScreenshots = true,
    this.accentColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: () async {
        if (protectFromScreenshots) await ScreenshotProtection.enable();

        await MediaFullViewer.show(
          context: context,
          mediaUrls: mediaUrls ?? [url],
          initialIndex: index ?? 0,
          accentColor: accentColor,
          protectFromScreenshots: false, // already enabled above
        );

        if (protectFromScreenshots) await ScreenshotProtection.disable();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (MediaClassifier.classify(url)) {
      case MediaKind.image:
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorWidget: (_, __, ___) => FilePlaceholder(url: url),
          progressIndicatorBuilder: (context, url, progress) =>
              Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: const Color(0xFFEEEEEE),
            child: Container(color: Colors.white),
          ),
        );

      case MediaKind.video:
        return url.isNotEmpty
            ? IgnorePointer(
                child: VideoPreviewWidget(
                  videoUrl: url,
                  onTap: () {},
                  showbtn: false,
                  playBtnSize: playBtnSize,
                ),
              )
            : FilePlaceholder(
                url: url,
                overrideIcon: Icons.play_circle_outline_rounded,
              );

      case MediaKind.audio:
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: InMemoryAudioPlayer(
            url: url,
            autoPlayOnVisible: false,
            hideControls: true,
          ),
        );

      case MediaKind.pdf:
        return IgnorePointer(child: InMemoryPdfViewer(url: url));

      case MediaKind.document:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: FilePlaceholder(url: url),
        );
    }
  }
}
