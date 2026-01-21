part of 'ytmusic_cubit.dart';

@immutable
class YTMusicState {
  final Map<String, String> location;
  final Map<String, String> language;
  final bool autofetchSongs;

  final AudioQuality streamingQuality;
  final AudioQuality downloadQuality;

  final bool translateLyrics;
  final bool personalisedContent;
  final String visitorId;

  const YTMusicState({
    required this.location,
    required this.language,
    required this.autofetchSongs,
    required this.streamingQuality,
    required this.downloadQuality,
    required this.translateLyrics,
    required this.personalisedContent,
    required this.visitorId,
  });

  YTMusicState copyWith({
    Map<String, String>? location,
    Map<String, String>? language,
    bool? autofetchSongs,
    dynamic streamingQuality,
    dynamic downloadQuality,
    bool? translateLyrics,
    bool? personalisedContent,
    String? visitorId,
  }) {
    return YTMusicState(
      location: location ?? this.location,
      language: language ?? this.language,
      autofetchSongs: autofetchSongs ?? this.autofetchSongs,
      streamingQuality: streamingQuality ?? this.streamingQuality,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      translateLyrics: translateLyrics ?? this.translateLyrics,
      personalisedContent: personalisedContent ?? this.personalisedContent,
      visitorId: visitorId ?? this.visitorId,
    );
  }
}
