class SiteEntry {
  final String title;
  final String url;

  SiteEntry({required this.title, required this.url});

  factory SiteEntry.fromJson(Map<String, dynamic> json) => SiteEntry(
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}
