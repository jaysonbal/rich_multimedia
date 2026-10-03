import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'media_kind.dart';

/// Downloads a media URL and either saves it to the device's gallery
/// (images/videos) or to the app's documents folder with an "Open" action
/// (anything else — PDFs, docs, etc.), showing progress in a bottom sheet
/// the whole way.
class MediaDownloader {
  MediaDownloader._();

  /// Entry point — call this from a download button's `onTap`.
  ///
  /// [galleryAlbum] is the album name images/videos are saved under (gal
  /// creates it if it doesn't exist yet). [doneColor]/[errorColor] style
  /// the sheet's completed/failed states.
  static Future<void> download(
    BuildContext context,
    String url, {
    String galleryAlbum = 'Downloads',
    Color doneColor = Colors.green,
    Color errorColor = Colors.red,
  }) async {
    final fileName = MediaClassifier.getFileName(url);

    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        if (context.mounted) {
          Fluttertoast.showToast(msg: 'Gallery permission denied');
        }
        return;
      }
    }

    if (context.mounted) {
      _showProgressSheet(context, fileName, url, galleryAlbum, doneColor, errorColor);
    }
  }

  static void _showProgressSheet(
    BuildContext context,
    String fileName,
    String url,
    String galleryAlbum,
    Color doneColor,
    Color errorColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isDismissible: false,
      builder: (ctx) => SafeArea(
        child: _DownloadSheet(
          url: url,
          fileName: fileName,
          galleryAlbum: galleryAlbum,
          doneColor: doneColor,
          errorColor: errorColor,
        ),
      ),
    );
  }
}

class _DownloadSheet extends StatefulWidget {
  final String url;
  final String fileName;
  final String galleryAlbum;
  final Color doneColor;
  final Color errorColor;

  const _DownloadSheet({
    required this.url,
    required this.fileName,
    required this.galleryAlbum,
    required this.doneColor,
    required this.errorColor,
  });

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  double _progress = 0;
  String _status = 'Downloading...';
  bool _done = false;
  bool _error = false;
  String? _savedPath;

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  bool get _isImage => MediaClassifier.isImage(widget.url);
  bool get _isVideo => MediaClassifier.isVideo(widget.url);
  bool get _isMedia => _isImage || _isVideo;

  Future<void> _startDownload() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${widget.fileName}';

      await _dio.download(
        widget.url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) setState(() => _progress = received / total);
        },
      );

      if (_isMedia) {
        setState(() => _status = 'Saving to gallery...');
        try {
          if (_isImage) {
            await Gal.putImage(filePath, album: widget.galleryAlbum);
          } else {
            await Gal.putVideo(filePath, album: widget.galleryAlbum);
          }
          setState(() {
            _done = true;
            _status = 'Saved to gallery';
          });
        } catch (_) {
          setState(() {
            _error = true;
            _status = 'Failed to save to gallery';
          });
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final destPath = '${appDir.path}/${widget.fileName}';
        await File(filePath).copy(destPath);
        setState(() {
          _done = true;
          _savedPath = destPath;
          _status = 'Download complete';
        });
      }
    } catch (_) {
      setState(() {
        _error = true;
        _status = 'Download failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                MediaClassifier.getFileIcon(widget.fileName),
                color: const Color(0xFF888888),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_done && !_error) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: const Color(0xFF2a2a2a),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%  •  $_status',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ],
          if (_done) ...[
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: widget.doneColor, size: 20),
                const SizedBox(width: 8),
                Text(_status,
                    style: TextStyle(color: widget.doneColor, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_savedPath != null) ...[
                  Expanded(
                    child: _SheetButton(
                      label: 'Open',
                      icon: Icons.open_in_new_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        OpenFilex.open(_savedPath!);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _SheetButton(
                    label: 'Done',
                    icon: Icons.check_rounded,
                    filled: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
          if (_error) ...[
            Row(
              children: [
                Icon(Icons.error_outline_rounded, color: widget.errorColor, size: 20),
                const SizedBox(width: 8),
                Text(_status,
                    style: TextStyle(color: widget.errorColor, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            _SheetButton(
              label: 'Dismiss',
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? Colors.white : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.black : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.black : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
