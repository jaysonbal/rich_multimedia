import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_multimedia/rich_multimedia.dart';

void main() {
  group('MediaClassifier.classify', () {
    test('classifies images', () {
      expect(MediaClassifier.classify('https://x.com/a.jpg'), MediaKind.image);
      expect(MediaClassifier.classify('https://x.com/a.PNG'), MediaKind.image);
      expect(MediaClassifier.classify('/local/photo.webp'), MediaKind.image);
    });

    test('classifies videos', () {
      expect(MediaClassifier.classify('https://x.com/clip.mp4'), MediaKind.video);
      expect(MediaClassifier.classify('https://x.com/clip.MOV'), MediaKind.video);
    });

    test('classifies audio', () {
      expect(MediaClassifier.classify('https://x.com/track.mp3'), MediaKind.audio);
      expect(MediaClassifier.classify('https://x.com/voice.m4a'), MediaKind.audio);
    });

    test('classifies pdf', () {
      expect(MediaClassifier.classify('https://x.com/doc.pdf'), MediaKind.pdf);
    });

    test('falls back to document for anything else', () {
      expect(MediaClassifier.classify('https://x.com/archive.zip'), MediaKind.document);
      expect(MediaClassifier.classify('https://x.com/report.docx'), MediaKind.document);
      expect(MediaClassifier.classify('https://x.com/no-extension'), MediaKind.document);
    });

    test('ignores a query string when classifying', () {
      expect(
        MediaClassifier.classify('https://x.com/a.jpg?token=abc&v=2'),
        MediaKind.image,
      );
    });
  });

  group('MediaClassifier.getFileName', () {
    test('strips the path and query string', () {
      expect(
        MediaClassifier.getFileName('https://x.com/path/to/photo.jpg?token=abc'),
        'photo.jpg',
      );
    });

    test('returns the input unchanged if there is no slash', () {
      expect(MediaClassifier.getFileName('photo.jpg'), 'photo.jpg');
    });
  });

  group('MediaClassifier.isLocalPath', () {
    test('true for absolute and file:// paths', () {
      expect(MediaClassifier.isLocalPath('/storage/emulated/0/img.jpg'), isTrue);
      expect(MediaClassifier.isLocalPath('file:///tmp/img.jpg'), isTrue);
    });

    test('false for network URLs', () {
      expect(MediaClassifier.isLocalPath('https://x.com/img.jpg'), isFalse);
    });
  });

  group('MediaClassifier.getFileIcon', () {
    test('returns a distinct icon per known extension', () {
      expect(MediaClassifier.getFileIcon('a.pdf'), Icons.picture_as_pdf);
      expect(MediaClassifier.getFileIcon('a.docx'), Icons.description);
      expect(MediaClassifier.getFileIcon('a.zip'), Icons.folder_zip);
      expect(MediaClassifier.getFileIcon('a.xlsx'), Icons.table_chart);
      expect(MediaClassifier.getFileIcon('a.unknownext'), Icons.insert_drive_file);
    });
  });

  group('MediaClassifier.formatFileSize', () {
    test('formats bytes, KB, and MB at the expected thresholds', () {
      expect(MediaClassifier.formatFileSize(500), '500 B');
      expect(MediaClassifier.formatFileSize(2048), '2.0 KB');
      expect(MediaClassifier.formatFileSize(5 * 1024 * 1024), '5.0 MB');
    });
  });
}
