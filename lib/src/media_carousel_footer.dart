import 'package:flutter/material.dart';

import 'media_dots_indicator.dart';

/// The dark footer bar under [MediaCarousel]'s page view: dot indicator +
/// "X of N" counter, an optional caption line, and either a download
/// button or a locked (greyed-out, tooltip-explained) placeholder for it.
///
/// The locked state is generic on purpose — the app this was extracted
/// from used it to gate downloads until a booking's work was marked
/// complete, but the concept ("you can't download this yet, here's why")
/// applies to any gated-content flow, so it's just [downloadLocked] +
/// [lockedTooltip] here rather than anything booking-specific.
class MediaCarouselFooter extends StatelessWidget {
  final int total;
  final int currentIndex;
  final String currentFileName;
  final void Function(int index) onDotTap;

  final bool hideDownloadButton;
  final bool downloadLocked;
  final String lockedTooltip;
  final VoidCallback onDownload;
  final String? caption;

  const MediaCarouselFooter({
    super.key,
    required this.total,
    required this.currentIndex,
    required this.currentFileName,
    required this.onDotTap,
    required this.onDownload,
    this.hideDownloadButton = false,
    this.downloadLocked = false,
    this.lockedTooltip = 'Not available yet',
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF252525))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 5),
          Row(
            children: [
              MediaDotsIndicator(
                total: total,
                currentIndex: currentIndex,
                onDotTap: onDotTap,
              ),
              const SizedBox(width: 8),
              Text(
                '${currentIndex + 1} of $total',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                ),
              ),
              if (!hideDownloadButton) ...[
                const Spacer(),
                if (!downloadLocked)
                  GestureDetector(
                    onTap: onDownload,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  )
                else
                  Tooltip(
                    message: lockedTooltip,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e1e1e),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2a2a2a)),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF444444),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          if (caption != null && caption!.trim().isNotEmpty) ...[
            Text(
              caption!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
