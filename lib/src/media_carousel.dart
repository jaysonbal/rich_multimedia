import 'package:flutter/material.dart';

import 'media_carousel_footer.dart';
import 'media_kind.dart';
import 'media_nav_arrow.dart';
import 'multi_media_item.dart';

/// A dark, rounded media carousel — a swipeable page view of [mediaUrls]
/// (each rendered by [MultiMediaItem], so image/video/audio/pdf/other all
/// just work) with prev/next arrows and a footer bar (dot indicator,
/// counter, caption, download button).
///
/// This is the widget most apps drop in directly for "show this set of
/// attachments": a review's photos, a booking's proof-of-work uploads, a
/// portfolio item's media, etc.
class MediaCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final bool hideDownloadButton;
  final bool downloadLocked;
  final String lockedTooltip;
  final void Function(String url) onDownload;
  final String? caption;
  final double height;
  final bool protectFromScreenshots;
  final Color accentColor;

  const MediaCarousel({
    super.key,
    required this.mediaUrls,
    required this.onDownload,
    this.hideDownloadButton = false,
    this.downloadLocked = false,
    this.lockedTooltip = 'Not available yet',
    this.caption,
    this.height = 300,
    this.protectFromScreenshots = true,
    this.accentColor = Colors.white,
  });

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  int get _total => widget.mediaUrls.length;
  String get _currentUrl =>
      widget.mediaUrls.isNotEmpty ? widget.mediaUrls[_currentIndex] : '';

  @override
  void initState() {
    super.initState();
    if (widget.mediaUrls.isEmpty) _currentIndex = 0;
  }

  @override
  void didUpdateWidget(MediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaUrls.length != oldWidget.mediaUrls.length) {
      if (_currentIndex >= widget.mediaUrls.length) {
        _currentIndex =
            widget.mediaUrls.isEmpty ? 0 : widget.mediaUrls.length - 1;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2a2a2a)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _total,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) => MultiMediaItem(
                      url: widget.mediaUrls[index],
                      mediaUrls: widget.mediaUrls,
                      index: index,
                      protectFromScreenshots: widget.protectFromScreenshots,
                      accentColor: widget.accentColor,
                    ),
                  ),
                  if (_currentIndex > 0)
                    Positioned(
                      left: 30,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: MediaNavArrow(
                          icon: Icons.chevron_left,
                          onTap: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex < _total - 1)
                    Positioned(
                      right: 30,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: MediaNavArrow(
                          icon: Icons.chevron_right,
                          onTap: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            MediaCarouselFooter(
              total: _total,
              currentIndex: _currentIndex,
              currentFileName: MediaClassifier.getFileName(_currentUrl),
              onDotTap: (i) => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              ),
              hideDownloadButton: widget.hideDownloadButton,
              downloadLocked: widget.downloadLocked,
              lockedTooltip: widget.lockedTooltip,
              onDownload: () => widget.onDownload(_currentUrl),
              caption: widget.caption,
            ),
          ],
        ),
      ),
    );
  }
}
