import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'file_placeholder.dart';

/// Downloads [url] once, caches the bytes on disk (keyed by a hash of the
/// URL, capped at 50MB total and evicted after 7 days), and renders it with
/// `flutter_pdfview`. Falls back to a cached copy if a re-fetch fails, and
/// to a plain [FilePlaceholder] if nothing could be loaded at all.
class InMemoryPdfViewer extends StatefulWidget {
  final String url;
  final double? height;
  final Color loadingColor;

  const InMemoryPdfViewer({
    super.key,
    required this.url,
    this.height,
    this.loadingColor = Colors.white,
  });

  @override
  State<InMemoryPdfViewer> createState() => _InMemoryPdfViewerState();
}

class _InMemoryPdfViewerState extends State<InMemoryPdfViewer> {
  Uint8List? _bytes;
  bool _loading = true;
  String? _error;

  static const Duration _cacheMaxAge = Duration(days: 7);
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB

  @override
  void initState() {
    super.initState();
    _loadPdfWithCache();
  }

  Future<void> _loadPdfWithCache() async {
    try {
      final cacheKey = _generateCacheKey(widget.url);
      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/$cacheKey.pdf');
      final metadataFile = File('${cacheDir.path}/$cacheKey.meta');

      if (await cacheFile.exists() && await metadataFile.exists()) {
        final metadata = jsonDecode(await metadataFile.readAsString());
        final cachedAt = DateTime.parse(metadata['cachedAt']);
        final age = DateTime.now().difference(cachedAt);

        if (age < _cacheMaxAge) {
          final bytes = await cacheFile.readAsBytes();
          if (mounted) {
            setState(() {
              _bytes = bytes;
              _loading = false;
            });
          }
          return;
        } else {
          await cacheFile.delete();
          await metadataFile.delete();
        }
      }

      await _fetchAndCachePdf(cacheFile, metadataFile);
    } catch (e) {
      await _loadFromCacheIfAvailable();

      if (_bytes == null && mounted) {
        setState(() {
          _error = 'Failed to load PDF';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchAndCachePdf(File cacheFile, File metadataFile) async {
    final response = await http.get(Uri.parse(widget.url));

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      await _manageCacheSize();
      await cacheFile.writeAsBytes(bytes);

      final metadata = {
        'cachedAt': DateTime.now().toIso8601String(),
        'url': widget.url,
        'size': bytes.length,
      };
      await metadataFile.writeAsString(jsonEncode(metadata));

      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } else {
      throw Exception('Failed to load PDF (status ${response.statusCode})');
    }
  }

  Future<void> _loadFromCacheIfAvailable() async {
    try {
      final cacheKey = _generateCacheKey(widget.url);
      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/$cacheKey.pdf');

      if (await cacheFile.exists()) {
        final bytes = await cacheFile.readAsBytes();
        if (mounted) {
          setState(() {
            _bytes = bytes;
            _loading = false;
          });
        }
      }
    } catch (_) {
      // Silent fail — _bytes stays null, caller falls back to a placeholder.
    }
  }

  Future<void> _manageCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final files = await cacheDir.list().toList();

      int totalSize = 0;
      final fileSizes = <File, int>{};

      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          final size = await entity.length();
          fileSizes[entity] = size;
          totalSize += size;
        }
      }

      if (totalSize > _maxCacheSize) {
        final sortedFiles = fileSizes.entries.toList()
          ..sort((a, b) {
            final aTime = a.key.lastModifiedSync();
            final bTime = b.key.lastModifiedSync();
            return aTime.compareTo(bTime);
          });

        for (var entry in sortedFiles) {
          if (totalSize <= _maxCacheSize) break;
          final file = entry.key;
          final size = entry.value;
          final basePath = file.path.replaceAll('.pdf', '');
          await file.delete();
          final metaFile = File('$basePath.meta');
          if (await metaFile.exists()) await metaFile.delete();
          totalSize -= size;
        }
      }
    } catch (_) {
      // Silent fail — cache just grows a bit past the cap this time.
    }
  }

  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/rich_multimedia_pdf_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height ?? 300,
        child: Center(
          child: CircularProgressIndicator(
            color: widget.loadingColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_error != null || _bytes == null) {
      return SizedBox(
        height: widget.height ?? 300,
        child: FilePlaceholder(url: widget.url),
      );
    }

    return SizedBox(
      height: widget.height ?? 300,
      child: PDFView(
        pdfData: _bytes!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        backgroundColor: const Color(0xFF1a1a1a),
      ),
    );
  }
}
