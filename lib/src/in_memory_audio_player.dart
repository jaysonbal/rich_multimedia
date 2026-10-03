import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// An inline audio player — streams [url] (network or local file path,
/// anything `just_audio`'s `setUrl` accepts) and renders a compact
/// icon + optional scrubber + play/pause button that scales to whatever
/// box it's given.
class InMemoryAudioPlayer extends StatefulWidget {
  final String url;

  /// Hides the scrubber/time labels/play button, leaving just the icon —
  /// used when this is shown as a static preview tile rather than a
  /// player someone is expected to interact with.
  final bool hideControls;

  /// When true, wraps the player in a [VisibilityDetector] that auto-plays
  /// once it's more than 50% visible and auto-pauses once it isn't.
  final bool autoPlayOnVisible;

  const InMemoryAudioPlayer({
    super.key,
    required this.url,
    this.hideControls = false,
    this.autoPlayOnVisible = false,
  });

  @override
  State<InMemoryAudioPlayer> createState() => _InMemoryAudioPlayerState();
}

class _InMemoryAudioPlayerState extends State<InMemoryAudioPlayer> {
  late final AudioPlayer _player;
  bool _loading = true;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setUrl(widget.url);

      _player.durationStream.listen((d) {
        if (d != null && mounted) setState(() => _duration = d);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playerStateStream.listen((s) {
        if (mounted) setState(() => _playing = s.playing);
      });

      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed && mounted) {
          _player.seek(Duration.zero);
          _player.pause();
          setState(() {
            _position = Duration.zero;
            _playing = false;
          });
        }
      });

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white24,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final player = _buildPlayer(context);

    if (!widget.autoPlayOnVisible) return player;
    return VisibilityDetector(
      key: Key(widget.url),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction * 100;
        if (visible > 50) {
          if (!_playing) _player.play();
        } else {
          if (_playing) _player.pause();
        }
      },
      child: player,
    );
  }

  Widget _buildPlayer(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double h =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 150;
          final scale = (h / 150).clamp(0.5, 1.0);

          final iconSize = 80 * scale;
          final buttonSize = 46 * scale;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 6 * scale,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.audio_file_rounded,
                  size: iconSize,
                  color: const Color(0xFF444444),
                ),
                SizedBox(height: 8 * scale),
                if (widget.hideControls == false) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: SizedBox(
                      height: 24 * scale,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white70,
                          inactiveTrackColor: const Color(0xFF333333),
                          thumbColor: Colors.white,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 4 * scale,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                          trackHeight: 2 * scale,
                        ),
                        child: Slider(
                          min: 0,
                          max: _duration.inMilliseconds
                              .toDouble()
                              .clamp(1, double.infinity),
                          value: _position.inMilliseconds.toDouble().clamp(
                                0,
                                _duration.inMilliseconds.toDouble(),
                              ),
                          onChanged: (v) => _player.seek(
                            Duration(milliseconds: v.toInt()),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.0 * scale),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(_position),
                          style: TextStyle(
                            color: const Color(0xFF888888),
                            fontSize: 12 * scale,
                          ),
                        ),
                        Text(
                          _fmt(_duration),
                          style: TextStyle(
                            color: const Color(0xFF888888),
                            fontSize: 12 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  InkWell(
                    onTap: () => _playing ? _player.pause() : _player.play(),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white70,
                        size: buttonSize * 0.55,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
