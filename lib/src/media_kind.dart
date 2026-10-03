import 'package:flutter/material.dart';

/// What kind of media a URL or local file path points to, plus the
/// extension-based classification every widget in this package relies on.
///
/// The original app this package was extracted from had two slightly
/// different classifiers living in two different helper classes (one used
/// by the carousel tile, a different one used by the full-screen viewer),
/// which is exactly the kind of drift that causes a file to render
/// correctly in one place and fall back to a generic file icon in another.
/// This package has exactly one classifier, used everywhere.
enum MediaKind {
  image,
  video,
  audio,
  pdf,
  document,
}

/// Static helpers for classifying a media URL/path and deriving display
/// info (file name, icon, human-readable size) from it. None of this reads
/// the file itself — it's all extension-based, same as the app code this
/// was extracted from.
class MediaClassifier {
  MediaClassifier._();

  static const _imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'];
  static const _videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.m4v'];
  static const _audioExtensions = ['.mp3', '.wav', '.aac', '.m4a', '.ogg'];
  static const _pdfExtension = '.pdf';

  /// The file name portion of a URL or local path, with any query string
  /// stripped (so a signed/cache-busted URL still shows a clean name).
  static String getFileName(String urlOrPath) {
    final withoutQuery = urlOrPath.split('?').first;
    final segments = withoutQuery.split('/');
    return segments.isNotEmpty && segments.last.isNotEmpty
        ? segments.last
        : urlOrPath;
  }

  /// The lowercased extension, including the leading dot (e.g. `.pdf`), or
  /// an empty string if there isn't a recognizable one.
  static String getExtension(String urlOrPath) {
    final fileName = getFileName(urlOrPath);
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex).toLowerCase();
  }

  /// Classifies a URL or local path by its extension. Defaults to
  /// [MediaKind.document] for anything unrecognized (zip, docx, txt, ...),
  /// which every widget here renders as a generic [FilePlaceholder] rather
  /// than failing.
  static MediaKind classify(String urlOrPath) {
    final ext = getExtension(urlOrPath);
    if (_imageExtensions.contains(ext)) return MediaKind.image;
    if (_videoExtensions.contains(ext)) return MediaKind.video;
    if (_audioExtensions.contains(ext)) return MediaKind.audio;
    if (ext == _pdfExtension) return MediaKind.pdf;
    return MediaKind.document;
  }

  static bool isImage(String urlOrPath) => classify(urlOrPath) == MediaKind.image;
  static bool isVideo(String urlOrPath) => classify(urlOrPath) == MediaKind.video;
  static bool isAudio(String urlOrPath) => classify(urlOrPath) == MediaKind.audio;
  static bool isPdf(String urlOrPath) => classify(urlOrPath) == MediaKind.pdf;

  /// Whether [urlOrPath] points at the local filesystem rather than a
  /// network URL — used to decide between `Image.file`/`VideoPlayerController.file`
  /// and their network equivalents.
  static bool isLocalPath(String urlOrPath) {
    return urlOrPath.startsWith('/') || urlOrPath.startsWith('file://');
  }

  /// A Material icon representing [fileName]'s type — used by
  /// [FilePlaceholder] and anywhere else a generic "this is a file" glyph
  /// is useful (e.g. a download sheet's file-name row).
  static IconData getFileIcon(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_fields;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Formats a byte count as a human-readable size (`"1.4 MB"`), same
  /// thresholds as the original app helper this was ported from.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
