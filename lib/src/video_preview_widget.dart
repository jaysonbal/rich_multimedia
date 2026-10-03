import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A full-width network-video preview tile with its own inline play/pause,
/// mute, and "open full viewer" controls. Auto-pauses after 15 seconds (a
/// deliberate "preview, not full playback" cap — open the full viewer for
/// longer than that) and auto-pauses when it scrolls out of view.
class VideoPreviewWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onTap;
  final bool showbtn;
  final double? playBtnSize;

  const VideoPreviewWidget({
    super.key,
    required this.videoUrl,
    required this.onTap,
    this.showbtn = true,
    this.playBtnSize = 70,
  });

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _videoPlayerController;
  bool _isInitialized = false;
  bool _isMuted = true;
  bool _isPlaying = false;

  late VoidCallback _videoListener;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();
      if (!mounted) return;

      _videoPlayerController.setVolume(0.0);

      _videoListener = () {
        if (!mounted) return;
        if (_videoPlayerController.value.isInitialized) {
          final position = _videoPlayerController.value.position;
          if (position >= const Duration(seconds: 15)) {
            _videoPlayerController.pause();
            setState(() {
              _isPlaying = false;
            });
          }
        }
      };
      _videoPlayerController.addListener(_videoListener);
      setState(() => _isInitialized = true);
    } catch (e) {
      if (kDebugMode) debugPrint('VideoPreviewWidget init failed: $e');
    }
  }

  void _toggleMute() {
    if (_isMuted) {
      _videoPlayerController.setVolume(1.0);
    } else {
      _videoPlayerController.setVolume(0.0);
    }
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _videoPlayerController.play();
    } else {
      _videoPlayerController.pause();
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _videoPlayerController.removeListener(_videoListener);
    }
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (visibilityInfo) {
        if (!mounted) return;
        final visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage <= 50) {
          if (_videoPlayerController.value.isPlaying) {
            _videoPlayerController.pause();
            setState(() => _isPlaying = false);
          }
        }
      },
      child: Container(
        height: 370,
        color: Colors.black,
        child: Stack(
          children: [
            if (widget.videoUrl.isEmpty)
              Container(
                width: 100,
                height: 100,
                color: Colors.grey.shade900,
                child: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
            if (_isInitialized)
              SizedBox(
                width: double.infinity,
                height: 370,
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: VideoPlayer(_videoPlayerController),
                ),
              )
            else
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
            if (_isInitialized)
              Container(
                width: double.infinity,
                height: 370,
                color: Colors.transparent,
                child: Center(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        size: widget.playBtnSize,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.showbtn == true && _isPlaying)
              Positioned(
                bottom: 25,
                right: 10,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        onPressed: _toggleMute,
                        icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        onPressed: widget.onTap,
                        icon: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
