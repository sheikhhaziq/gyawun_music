import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeAudioSource extends StreamAudioSource {
  final String videoId;
  final String quality; // 'high' or 'low'
  final YoutubeExplode ytExplode;

  YouTubeAudioSource({
    required this.videoId,
    required this.quality,
    super.tag,
  }) : ytExplode = YoutubeExplode();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    try {
      final manifest = await ytExplode.videos.streams.getManifest(videoId,
          requireWatchPage: true, ytClients: [YoutubeApiClient.androidVr]);
      final supportedStreams = manifest.audioOnly.sortByBitrate();

      final audioStream = quality == 'high'
          ? supportedStreams.firstOrNull
          : supportedStreams.lastOrNull;

      if (audioStream == null) {
        throw Exception('No audio stream available for this video.');
      }

      start ??= 0;
      end ??= (audioStream.isThrottled
          ? (end ?? (start + 10379935))
          : audioStream.size.totalBytes);
      if (end > audioStream.size.totalBytes) {
        end = audioStream.size.totalBytes;
      }

      final stream = ytExplode.videos.streams.get(audioStream, start, end);
      return StreamAudioResponse(
        sourceLength: audioStream.size.totalBytes,
        contentLength: end - start,
        offset: start,
        stream: stream,
        contentType: audioStream.codec.mimeType,
      );
    } catch (e) {
      throw Exception('Failed to load audio: $e');
    }
  }
}

final YoutubeExplode ytExplode = YoutubeExplode();

/// Starts a generic HTTP server that listens for requests to stream YouTube audio.
///
/// Clients must pass 'id' and 'quality' as URL query parameters.
/// The server binds to a random available port.
/// Returns the base URL for the streaming endpoint.
Future<String> createAudioStreamServer() async {
  // Bind to a random port (port 0) on the loopback interface.
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

  // Listen for requests and dispatch them to the handler
  server.listen((HttpRequest request) {
    // Pass only the request object to the handler
    handleAudioRequest(request);
  });

  // Construct the base streaming URL
  final host = server.address.host;
  final port = server.port;
  final url = 'http://$host:$port/audio';

  debugPrint(
      'Generic streaming server started on $url. Use ?id=...&quality=... to stream.');

  // You would typically return the server instance here too, if you needed
  // to close it later (e.g., return {'server': server, 'url': url})
  return url;
}

// ----------------------------------------------------------------------------
// HANDLER FUNCTION (Modified to read parameters from the request URI)
// ----------------------------------------------------------------------------

Future<void> handleAudioRequest(HttpRequest request) async {
  final response = request.response;

  // 1. Check the path and extract parameters from URL query
  if (request.uri.path != '/audio') {
    response.statusCode = HttpStatus.notFound;
    response.write('404 Not Found');
    await response.close();
    return;
  }

  final queryParams = request.uri.queryParameters;
  final videoId = queryParams['id'];
  final quality = queryParams['quality'] ?? 'high'; // Default to 'high'

  if (videoId == null || videoId.isEmpty) {
    response.statusCode = HttpStatus.badRequest;
    response.write('Missing required query parameter: id');
    await response.close();
    return;
  }

  debugPrint('Processing request for video ID: $videoId (Quality: $quality)');

  try {
    // 2. Get the Stream Manifest and select the audio stream
    final manifest = await ytExplode.videos.streamsClient.getManifest(videoId,
        requireWatchPage: true, ytClients: [YoutubeApiClient.androidVr]);

    final supportedStreams = manifest.audioOnly.sortByBitrate();
    final audioStreamInfo = quality == 'high'
        ? supportedStreams.firstOrNull
        : supportedStreams.lastOrNull;

    if (audioStreamInfo == null) {
      response.statusCode = HttpStatus.internalServerError;
      response.write('No audio stream available for video $videoId.');
      await response.close();
      return;
    }

    final totalLength = audioStreamInfo.size.totalBytes;

    // 3. Parse the client's 'Range' header (same logic)

    (int start, int end)? parseRange(String rangeHeader, int totalLength) {
      // Expected format: "bytes=start-end" or "bytes=start-"
      if (!rangeHeader.startsWith('bytes=')) return null;

      final parts = rangeHeader.substring(6).split('-');
      if (parts.length != 2) return null;

      final startStr = parts[0];
      final endStr = parts[1];

      final start = int.tryParse(startStr) ?? 0;

      // If end is missing (e.g., "bytes=1000-"), it means until the end of the file
      final end = endStr.isEmpty ? totalLength - 1 : int.tryParse(endStr);

      if (end == null ||
          end >= totalLength ||
          start >= totalLength ||
          start > end) {
        return null; // Invalid range or past the end of the file
      }

      return (start, end);
    }

    int start = 0;
    int end = totalLength - 1;
    bool isPartial = false;

    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    if (rangeHeader != null) {
      final range = parseRange(rangeHeader, totalLength);
      if (range != null) {
        start = range.$1;
        end = range.$2;
        isPartial = true;
      }
    }

    // 4. Get the *actual* byte stream from YouTube
    final stream =
        ytExplode.videos.streamsClient.get(audioStreamInfo, start, end + 1);

    // 5. Set the HTTP headers and pipe the stream (same logic)
    final contentLength = end - start + 1;
    final mimeType = audioStreamInfo.codec.mimeType;

    response.statusCode = isPartial ? HttpStatus.partialContent : HttpStatus.ok;
    response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    response.headers.contentType = ContentType.parse(mimeType);
    response.headers.contentLength = contentLength;
    if (isPartial) {
      response.headers.set(
          HttpHeaders.contentRangeHeader, 'bytes $start-$end/$totalLength');
    }
    response.bufferOutput = false;

    await response.addStream(stream);

    await response.close();
    debugPrint(
        '[$videoId] Served ${isPartial ? 'partial' : 'full'} stream: bytes $start-$end');
  } catch (e) {
    debugPrint('Error serving audio for ID $videoId: $e');
  }
}
