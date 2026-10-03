import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// One video page inside [MediaFullViewer]. Dumb by design — all the state
/// (controller, play/pause, progress) lives in the viewer itself; this
/// widget just renders whatever it's handed, including the "still loading"
/// state.
class VideoItemWidget extends StatelessWidget {
  const VideoItemWidget({
    super.key,
    required this.isVideoInitialized,
    required this.videoController,
    required this.onToggleProgressControls,
    required this.onPlayPause,
    required this.context,
    this.loadingColor = Colors.white,
    this.loadingLabel = 'Loading video...',
  });

  final bool isVideoInitialized;
  final VideoPlayerController? videoController;
  final VoidCallback onToggleProgressControls;
  final VoidCallback onPlayPause;
  final BuildContext context;
  final Color loadingColor;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isVideoInitialized && videoController != null)
          Center(
            child: GestureDetector(
              onTap: onToggleProgressControls,
              onDoubleTap: onPlayPause,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height,
                ),
                child: AspectRatio(
                  aspectRatio: videoController!.value.aspectRatio,
                  child: VideoPlayer(videoController!),
                ),
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: loadingColor,
                    strokeWidth: 1,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loadingLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        if (isVideoInitialized &&
            videoController != null &&
            videoController!.value.isBuffering)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 1,
              ),
            ),
          ),
      ],
    );
  }
}
