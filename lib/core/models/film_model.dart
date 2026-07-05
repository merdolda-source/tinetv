class Film {
  final String url;
  final String title;
  final String year;
  final String imdb;
  final String quality;
  final String poster;

  Film({
    required this.url,
    required this.title,
    required this.year,
    required this.imdb,
    required this.quality,
    required this.poster,
  });

  factory Film.fromJson(Map<String, dynamic> json) => Film(
        url: json['url'] as String? ?? '',
        title: json['title'] as String? ?? '',
        year: json['year']?.toString() ?? '',
        imdb: json['imdb']?.toString() ?? '',
        quality: json['quality'] as String? ?? '',
        poster: json['poster'] as String? ?? '',
      );
}
