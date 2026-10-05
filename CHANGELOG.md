## 0.1.2

* Updated hero image. No breaking change.

## 0.1.1

* Updated hero image. No breaking change.

## 0.1.0

* Initial release.
* `MediaCarousel` + `MultiMediaItem` — the two widgets most apps need: a
  swipeable carousel of mixed media, and a single tappable tile, both
  dispatching image/video/audio/pdf/other automatically.
* `MediaFullViewer` — full-screen pinch-to-zoom/play/scrub viewer, opened
  automatically by `MultiMediaItem` or launchable directly via
  `MediaFullViewer.show(...)`.
* `ImageItemWidget`, `VideoItemWidget`, `VideoPreviewWidget`,
  `LocalVideoPreview`, `NetworkVideoPreview`, `InMemoryAudioPlayer`,
  `InMemoryPdfViewer`, `FilePlaceholder`, `MediaNavArrow`,
  `MediaDotsIndicator`, `MediaCarouselFooter` — the lower-level pieces,
  exported individually for a custom layout.
* `MediaDownloader.download(...)` — downloads a URL with a progress sheet,
  saving images/videos to the gallery and anything else to the app's
  documents folder with an "Open" action.
* `ScreenshotProtection` — optional, on by default on `MultiMediaItem`'s
  full-viewer launch and on `MediaFullViewer` itself (`protectFromScreenshots`).
* `MediaClassifier`/`MediaKind` — one canonical extension-based classifier
  used by every widget in this package.
