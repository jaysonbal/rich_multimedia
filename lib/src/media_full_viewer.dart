import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'file_placeholder.dart';
import 'image_item_widget.dart';
import 'in_memory_audio_player.dart';
import 'in_memory_pdf_viewer.dart';
import 'media_kind.dart';
import 'media_nav_arrow.dart';
import 'screenshot_protection.dart';
import 'video_item_widget.dart';

/// Full-screen, swipeable viewer for a list of media URLs — images (pinch
/// to zoom), videos (play/pause/mute/scrub, auto-pauses off-screen pages),
/// audio, PDFs, and a generic file fallback, all dispatched through
/// [MediaClassifier]. This is what [MultiMediaItem] opens on tap; use
/// [MediaFullViewer.show] directly if you want to open it from your own
/// tap handler without going through that widget.
class MediaFullViewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  final PageController? pageController;

  /// Color used for the video progress slider's active track/thumb.
  final Color accentColor;

  /// Enables screenshot/screen-recording protection for as long as the
  /// viewer is open, turning it back off on dispose. Defaults to true.
  final bool protectFromScreenshots;

  const MediaFullViewer({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
    this.pageController,
    this.accentColor = Colors.white,
    this.protectFromScreenshots = true,
  });

  /// Pushes a [MediaFullViewer] as a new full-screen route.
  static Future<void> show({
    required BuildContext context,
    required List<String> mediaUrls,
    int initialIndex = 0,
    Color accentColor = Colors.white,
    bool protectFromScreenshots = true,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaFullViewer(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
          accentColor: accentColor,
          protectFromScreenshots: protectFromScreenshots,
        ),
      ),
    );
  }

  @override
  State<MediaFullViewer> createState() => _MediaFullViewerState();
}

class _MediaFullViewerState extends State<MediaFullViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};
  final Map<int, Duration> _videoPositions = {};
  final Map<int, Duration> _videoDurations = {};
  final Map<int, bool> _videoIsPlaying = {};
  final Map<int, bool> _videoIsMuted = {};
  Timer? _hideControlsTimer;
  bool _showControls = true;
  bool _showVideoProgressControls = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = widget.pageController ??
        PageController(initialPage: widget.initialIndex);

    _initializeVideoIfNeeded(widget.initialIndex);
    _startHideControlsTimer();

    if (widget.protectFromScreenshots) {
      ScreenshotProtection.enable();
    }
  }

  void _initializeVideoIfNeeded(int index) {
    if (index < 0 || index >= widget.mediaUrls.length) return;

    final mediaUrl = widget.mediaUrls[index];
    if (MediaClassifier.isVideo(mediaUrl) &&
        !_videoControllers.containsKey(index)) {
      _videoIsMuted[index] = false;
      _videoIsPlaying[index] = false;
      _videoPositions[index] = Duration.zero;
      _videoDurations[index] = Duration.zero;

      _videoControllers[index] =
          VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
            ..setLooping(true)
            ..initialize().then((_) {
              if (mounted) {
                setState(() {
                  _videoInitialized[index] = true;
                  _videoDurations[index] =
                      _videoControllers[index]!.value.duration;
                });

                _videoControllers[index]!.addListener(() {
                  if (_videoControllers[index]!.value.isInitialized &&
                      mounted) {
                    setState(() {
                      _videoPositions[index] =
                          _videoControllers[index]?.value.position ??
                              Duration.zero;
                      _videoIsPlaying[index] =
                          _videoControllers[index]?.value.isPlaying ?? false;
                    });
                  }
                });

                if (index == _currentIndex) {
                  _videoControllers[index]?.play();
                  setState(() {
                    _videoIsPlaying[index] = true;
                  });
                }
              }
            }).catchError((error) {
              if (kDebugMode) {
                debugPrint(
                    'rich_multimedia: error initializing video at index $index: $error');
              }
              if (mounted) {
                setState(() {
                  _videoInitialized[index] = false;
                });
              }
            });
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 9), () {
      if (mounted) {
        setState(() {
          _showControls = false;
          _showVideoProgressControls = false;
        });
      }
    });
  }

  void _resetHideControlsTimer() {
    _startHideControlsTimer();
    if (mounted) setState(() => _showControls = true);
  }

  void _handlePageChange(int index) {
    if (_videoControllers.containsKey(_currentIndex)) {
      _videoControllers[_currentIndex]?.pause();
      if (mounted) {
        setState(() => _videoIsPlaying[_currentIndex] = false);
      }
    }
    if (mounted) {
      setState(() {
        _currentIndex = index;
        _showVideoProgressControls = false;
      });
    }

    _initializeVideoIfNeeded(index);
    if (_videoControllers.containsKey(index) &&
        _videoInitialized[index] == true) {
      _videoControllers[index]?.play();
      if (mounted) setState(() => _videoIsPlaying[index] = true);
    }
  }

  void _togglePlayPause() {
    final currentVideoController = _videoControllers[_currentIndex];
    final isCurrentVideoInitialized = _videoInitialized[_currentIndex];

    if (currentVideoController != null && isCurrentVideoInitialized == true) {
      final isPlaying = _videoIsPlaying[_currentIndex] ?? false;

      if (isPlaying) {
        currentVideoController.pause();
        setState(() => _videoIsPlaying[_currentIndex] = false);
      } else {
        currentVideoController.play();
        setState(() => _videoIsPlaying[_currentIndex] = true);
      }
    }
    _resetHideControlsTimer();
  }

  void _toggleMute() {
    final currentVideoController = _videoControllers[_currentIndex];
    if (currentVideoController != null) {
      final isMuted = _videoIsMuted[_currentIndex] ?? false;
      if (mounted) {
        setState(() {
          _videoIsMuted[_currentIndex] = !isMuted;
          currentVideoController.setVolume(!isMuted ? 0.0 : 1.0);
        });
      }
    }
    _resetHideControlsTimer();
  }

  void _seekToPosition(double value) {
    final currentVideoController = _videoControllers[_currentIndex];
    if (currentVideoController != null) {
      currentVideoController.seekTo(Duration(milliseconds: value.toInt()));
    }
    _resetHideControlsTimer();
  }

  void _toggleVideoProgressControls() {
    if (mounted) {
      setState(() => _showVideoProgressControls = !_showVideoProgressControls);
    }
    _resetHideControlsTimer();
  }

  static String _formatVideoDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds";
  }

  Widget _buildPage(BuildContext context, String mediaUrl, int index) {
    switch (MediaClassifier.classify(mediaUrl)) {
      case MediaKind.video:
        return VideoItemWidget(
          isVideoInitialized: _videoInitialized[index] ?? false,
          videoController: _videoControllers[index],
          onToggleProgressControls: _toggleVideoProgressControls,
          onPlayPause: _togglePlayPause,
          context: context,
        );
      case MediaKind.image:
        return ImageItemWidget(mediaUrl: mediaUrl, onTap: _resetHideControlsTimer);
      case MediaKind.audio:
        return InMemoryAudioPlayer(url: mediaUrl);
      case MediaKind.pdf:
        return InMemoryPdfViewer(url: mediaUrl, loadingColor: widget.accentColor);
      case MediaKind.document:
        return FilePlaceholder(url: mediaUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentVideo = _currentIndex < widget.mediaUrls.length &&
        MediaClassifier.isVideo(widget.mediaUrls[_currentIndex]) &&
        _videoInitialized[_currentIndex] == true;

    final currentVideoIsPlaying = _videoIsPlaying[_currentIndex] ?? false;
    final currentVideoIsMuted = _videoIsMuted[_currentIndex] ?? false;
    final currentVideoPosition =
        _videoPositions[_currentIndex] ?? Duration.zero;
    final currentVideoDuration =
        _videoDurations[_currentIndex] ?? Duration.zero;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _resetHideControlsTimer,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.mediaUrls.length,
                onPageChanged: _handlePageChange,
                itemBuilder: (context, index) {
                  final mediaUrl = widget.mediaUrls[index];

                  return VisibilityDetector(
                    key: Key('rich_multimedia_page_$index'),
                    onVisibilityChanged: (visibilityInfo) {
                      final visiblePercentage =
                          visibilityInfo.visibleFraction * 100;

                      if (MediaClassifier.isVideo(mediaUrl) &&
                          _videoControllers.containsKey(index) &&
                          _videoInitialized[index] == true) {
                        final isPlaying = _videoIsPlaying[index] ?? false;
                        if (visiblePercentage > 50 && index == _currentIndex) {
                          if (!isPlaying) {
                            _videoControllers[index]!.play();
                            if (mounted) {
                              setState(() => _videoIsPlaying[index] = true);
                            }
                          }
                        } else {
                          if (isPlaying) {
                            _videoControllers[index]!.pause();
                            if (mounted) {
                              setState(() => _videoIsPlaying[index] = false);
                            }
                          }
                        }
                      }
                    },
                    child: _buildPage(context, mediaUrl, index),
                  );
                },
              ),
              if (_showControls) ...[
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                if (widget.mediaUrls.length > 1) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30.0),
                      child: MediaNavArrow(
                        icon: Icons.chevron_left,
                        onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 30.0),
                      child: MediaNavArrow(
                        icon: Icons.chevron_right,
                        onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                ],
                if (widget.mediaUrls.length > 1)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.mediaUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isCurrentVideo)
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: 16,
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              currentVideoIsMuted
                                  ? Icons.volume_off
                                  : Icons.volume_up,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _toggleMute,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isCurrentVideo)
                  Positioned.fill(
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: AnimatedOpacity(
                              opacity: _showControls ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.black38,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      currentVideoIsPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_showVideoProgressControls && isCurrentVideo)
                          AnimatedOpacity(
                            opacity: _showControls ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: Colors.black87,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: widget.accentColor,
                                      inactiveTrackColor: Colors.white54,
                                      thumbColor: widget.accentColor,
                                      overlayColor: Colors.white24,
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                    ),
                                    child: Slider(
                                      value: currentVideoPosition
                                          .inMilliseconds
                                          .toDouble(),
                                      min: 0,
                                      max: currentVideoDuration
                                                  .inMilliseconds >
                                              0
                                          ? currentVideoDuration.inMilliseconds
                                              .toDouble()
                                          : 1.0,
                                      onChanged: _seekToPosition,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatVideoDuration(
                                              currentVideoPosition),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatVideoDuration(
                                              currentVideoDuration),
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _pageController.dispose();

    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
    _videoPositions.clear();
    _videoDurations.clear();
    _videoIsPlaying.clear();
    _videoIsMuted.clear();

    if (widget.protectFromScreenshots) {
      ScreenshotProtection.disable();
    }

    super.dispose();
  }
}
