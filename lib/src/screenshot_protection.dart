import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Thin wrapper around the `no_screenshot` plugin, tracking whether
/// protection is currently on so enabling/disabling it is idempotent (the
/// underlying plugin call is a no-op either way, but this avoids firing it
/// redundantly if, say, two media tiles are opened and closed in quick
/// succession).
///
/// [MultiMediaItem] and [MediaFullViewer] both call this automatically
/// whenever `protectFromScreenshots` is true (the default) — most callers
/// never need to touch this class directly.
class ScreenshotProtection {
  ScreenshotProtection._();

  static final NoScreenshot _noScreenshot = NoScreenshot.instance;
  static bool _isProtected = false;

  /// Turns screenshot/screen-recording protection on. Safe to call more
  /// than once in a row.
  static Future<bool> enable() async {
    try {
      if (!_isProtected) {
        final result = await _noScreenshot.screenshotOff();
        if (result) {
          _isProtected = true;
        } else if (kDebugMode) {
          debugPrint('rich_multimedia: failed to enable screenshot protection');
        }
        return result;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('rich_multimedia: error enabling screenshot protection: $e');
      }
      return false;
    }
  }

  /// Turns screenshot/screen-recording protection back off. Safe to call
  /// more than once in a row.
  static Future<bool> disable() async {
    if (_isProtected) {
      final result = await _noScreenshot.screenshotOn();
      if (result) _isProtected = false;
      return result;
    }
    return true;
  }
}
