import 'package:flutter/material.dart';
import 'package:rich_multimedia/rich_multimedia.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rich_multimedia example',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const ExampleHome(),
    );
  }
}

/// A handful of public sample URLs covering every media kind this package
/// dispatches on, so the carousel and viewer both have something real to
/// show without needing any app-specific backend.
const _sampleUrls = <String>[
  'https://images.unsplash.com/photo-1501594907352-04cda38ebc29',
  'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
  'https://file-examples.com/storage/fe92b4a6b1651db37f3b64c/2017/11/file_example_MP3_700KB.mp3',
  'https://file-examples.com/storage/fe92b4a6b1651db37f3b64c/2017/10/file-sample_150kB.pdf',
];

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('rich_multimedia example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'MediaCarousel',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          MediaCarousel(
            mediaUrls: _sampleUrls,
            caption: 'One of each media kind this package handles.',
            downloadLocked: false,
            accentColor: Theme.of(context).colorScheme.primary,
            onDownload: (url) => MediaDownloader.download(
              context,
              url,
              galleryAlbum: 'rich_multimedia example',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'MultiMediaItem (single tile)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MultiMediaItem(
                url: _sampleUrls.first,
                mediaUrls: _sampleUrls,
                index: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Locked download (gated-content example)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          MediaCarousel(
            mediaUrls: _sampleUrls,
            downloadLocked: true,
            lockedTooltip: 'Available after the booking is marked complete',
            onDownload: (url) {},
          ),
        ],
      ),
    );
  }
}
