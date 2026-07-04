class Series {
  final int id;
  final String slug;
  final String title;
  final String description;
  final String coverImage;
  final String platform;
  final String language;
  final int totalEpisodes;
  final bool isNew;
  final bool isPopular;

  Series({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.coverImage,
    required this.platform,
    required this.language,
    required this.totalEpisodes,
    required this.isNew,
    required this.isPopular,
  });

  factory Series.fromJson(Map<String, dynamic> json) => Series(
        id: (json['id'] as num?)?.toInt() ?? 0,
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        coverImage: json['cover_image'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        language: (json['language'] as String? ?? '').toUpperCase(),
        totalEpisodes: (json['total_episodes'] as num?)?.toInt() ?? 0,
        isNew: json['is_new'] as bool? ?? false,
        isPopular: json['is_popular'] as bool? ?? false,
      );

  // Başlıkta "Dublajlı" geçen içerikler gerçekten Türkçe seslendirilmiş —
  // diğerlerinde "language" alanı yalnızca altyazı/metadata dilini belirtir.
  bool get isDubbed => title.toLowerCase().contains('dublaj');
}

class SubtitleTrack {
  final String language;
  final String url;
  final String label;

  SubtitleTrack({required this.language, required this.url, required this.label});

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) => SubtitleTrack(
        language: json['language'] as String? ?? '',
        url: json['url'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class Episode {
  final int id;
  final int episodeNumber;
  final String url;
  final List<SubtitleTrack> subtitles;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.url,
    required this.subtitles,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: (json['id'] as num?)?.toInt() ?? 0,
        episodeNumber: (json['episode_number'] as num?)?.toInt() ?? 0,
        url: json['url'] as String? ?? '',
        subtitles: ((json['subtitles'] as List?) ?? const [])
            .map((s) => SubtitleTrack.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  SubtitleTrack? get preferredSubtitle {
    if (subtitles.isEmpty) return null;
    for (final s in subtitles) {
      if (s.language.toUpperCase() == 'TR') return s;
    }
    return subtitles.first;
  }
}

class SeriesDetail {
  final Series series;
  final List<Episode> episodes;

  SeriesDetail({required this.series, required this.episodes});
}
