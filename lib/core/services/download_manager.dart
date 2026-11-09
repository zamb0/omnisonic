import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../entities/entities.dart';
import '../errors/errors.dart';
import '../utils/web_support.dart';

/// Download progress callback
typedef DownloadProgressCallback = void Function(int received, int total);

/// Download manager for offline content
class DownloadManager {
  DownloadManager({required Dio dio}) : _dio = dio;

  final Dio _dio;
  final Map<String, CancelToken> _activeDownloads = {};

  /// Downloads a track for offline use
  Future<Result<CacheEntry>> downloadTrack(
    Track track, {
    DownloadProgressCallback? onProgress,
  }) async {
    // dart:io file access throws in a browser; the web build streams only.
    if (!supportsOfflineDownloads) {
      return ResultHelper.failure(CacheFailure(offlineUnavailableOnWebMessage));
    }
    try {
      // Check if already downloading
      if (_activeDownloads.containsKey(track.id)) {
        return ResultHelper.failure(
          CacheFailure('Track is already being downloaded'),
        );
      }

      // Create cancel token for this download
      final cancelToken = CancelToken();
      _activeDownloads[track.id] = cancelToken;

      // Get cache directory
      final cacheDir = await _getCacheDirectory();

      // Create filename with track info
      final filename = _generateFilename(track);
      final filePath = path.join(cacheDir.path, filename);

      // Ensure directory exists
      await cacheDir.create(recursive: true);

      // Start download
      final response = await _dio.download(
        track.streamUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      // Remove from active downloads
      _activeDownloads.remove(track.id);

      if (response.statusCode == 200) {
        final contentType =
            response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ??
            '';

        // A Subsonic server reports errors (wrong credentials, missing file,
        // not allowed to download) as HTTP 200 with a JSON or XML body: that
        // body used to be saved as the "audio" file.
        if (contentType.contains('json') || contentType.contains('xml')) {
          final body = await _readSmallFile(filePath);
          await _cleanupFailedDownload(filePath);
          return ResultHelper.failure(
            ServerFailure('The server refused the download: $body'),
          );
        }

        // The stream URL has no file extension, so every download was named
        // .mp3 — a FLAC under that name fails to open on players that go by
        // the extension (AVFoundation on iOS and macOS).
        var savedPath = filePath;
        final extension = _extensionForContentType(contentType);
        if (extension != null && path.extension(filePath) != extension) {
          savedPath = path.setExtension(filePath, extension);
          await File(filePath).rename(savedPath);
        }

        // Get file info
        final file = File(savedPath);
        final fileSize = await file.length();

        // Create cache entry
        final cacheEntry = CacheEntry(
          trackId: track.id,
          filePath: savedPath,
          fileSize: fileSize,
          cachedAt: DateTime.now(),
          lastAccessed: DateTime.now(),
          isComplete: true,
        );

        return ResultHelper.success(cacheEntry);
      } else {
        // Clean up failed download
        await _cleanupFailedDownload(filePath);
        return ResultHelper.failure(
          NetworkFailure('Download failed with status: ${response.statusCode}'),
        );
      }
    } on DioException catch (e) {
      _activeDownloads.remove(track.id);

      if (e.type == DioExceptionType.cancel) {
        return ResultHelper.failure(CacheFailure('Download was cancelled'));
      }

      return ResultHelper.failure(
        NetworkFailure('Download failed: ${e.message}'),
      );
    } catch (e) {
      _activeDownloads.remove(track.id);
      return ResultHelper.failure(
        UnknownFailure('Unexpected download error: $e'),
      );
    }
  }

  /// Cancels an active download
  Future<Result<void>> cancelDownload(String trackId) async {
    try {
      final cancelToken = _activeDownloads[trackId];
      if (cancelToken != null) {
        cancelToken.cancel('Download cancelled by user');
        _activeDownloads.remove(trackId);
        return ResultHelper.success(null);
      }

      return ResultHelper.failure(
        CacheFailure('No active download found for track'),
      );
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to cancel download: $e'),
      );
    }
  }

  /// Checks if a track is currently being downloaded
  bool isDownloading(String trackId) {
    return _activeDownloads.containsKey(trackId);
  }

  /// Gets list of currently downloading track IDs
  List<String> get activeDownloads => _activeDownloads.keys.toList();

  /// Deletes a cached file
  Future<Result<void>> deleteCachedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to delete cached file: $e'),
      );
    }
  }

  /// Verifies a cached file exists and is valid
  Future<Result<bool>> verifyCachedFile(CacheEntry entry) async {
    try {
      final file = File(entry.filePath);

      if (!await file.exists()) {
        return ResultHelper.success(false);
      }

      final actualSize = await file.length();
      return ResultHelper.success(
        actualSize == entry.fileSize && entry.isComplete,
      );
    } catch (e) {
      return ResultHelper.failure(
        CacheFailure('Failed to verify cached file: $e'),
      );
    }
  }

  /// Gets the cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, 'omnisonic_cache', 'audio'));
  }

  /// Generates a safe filename for a track
  String _generateFilename(Track track) {
    // Create a safe filename from track metadata
    final safeTitle = _sanitizeFilename(track.title);
    final safeArtist = _sanitizeFilename(track.artist);
    final extension = _getFileExtension(track.streamUrl);

    return '${track.id}_${safeArtist}_$safeTitle$extension';
  }

  /// Sanitizes a string for use in filenames
  String _sanitizeFilename(String input) {
    // Whitespace collapsing shrinks the string, so the length limit has to be
    // applied to the sanitized value - not to `input`.
    final sanitized = input
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }

  /// Gets file extension from URL or defaults to .mp3
  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    if (pathSegments.isNotEmpty) {
      final lastSegment = pathSegments.last;
      final dotIndex = lastSegment.lastIndexOf('.');

      if (dotIndex != -1 && dotIndex < lastSegment.length - 1) {
        return lastSegment.substring(dotIndex);
      }
    }

    return '.mp3'; // Default extension
  }

  /// The file extension for an audio [contentType], or null when unknown.
  static String? _extensionForContentType(String contentType) {
    final mime = contentType.split(';').first.trim();
    return switch (mime) {
      'audio/flac' || 'audio/x-flac' => '.flac',
      'audio/mpeg' || 'audio/mp3' => '.mp3',
      'audio/ogg' || 'application/ogg' || 'audio/vorbis' => '.ogg',
      'audio/opus' => '.opus',
      'audio/mp4' || 'audio/x-m4a' || 'audio/m4a' || 'audio/aac' => '.m4a',
      'audio/wav' || 'audio/x-wav' || 'audio/wave' => '.wav',
      'audio/aiff' || 'audio/x-aiff' => '.aiff',
      'audio/x-ms-wma' => '.wma',
      'audio/x-ape' || 'audio/ape' => '.ape',
      'audio/x-wavpack' || 'audio/wavpack' => '.wv',
      _ => null,
    };
  }

  /// The start of a small text file, for an error message.
  Future<String> _readSmallFile(String filePath) async {
    try {
      final text = await File(filePath).readAsString();
      return text.length > 300 ? '${text.substring(0, 300)}…' : text;
    } catch (_) {
      return 'no details';
    }
  }

  /// Cleans up a failed download
  Future<void> _cleanupFailedDownload(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Disposes the download manager
  void dispose() {
    // Cancel all active downloads
    for (final cancelToken in _activeDownloads.values) {
      cancelToken.cancel('Download manager disposed');
    }
    _activeDownloads.clear();
  }
}
