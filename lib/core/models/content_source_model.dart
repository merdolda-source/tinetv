import 'dart:convert';

/// RC 'content_json' içindeki tek kaynak. Birden fazla M3U ve resolve kaynağı
/// Ana Sayfa'ya kart olarak eklenir — APK güncellemeden Firebase'ten yönetilir.
///
/// Örnek:
///   {"type":"m3u","title":"Spor","url":"https://…/spor.m3u"}
///   {"type":"resolve","title":"Maçlar","url":"https://…/matches",
///    "embed_base":"https://patrongol34.cfd","embed_only":true}
class ContentSource {
  final String type; // 'm3u' | 'resolve'
  final String title;
  final String url;
  final String embedBase; // resolve: embedOnly bölüm domaini / boss watch öneki
  final bool embedOnly; // resolve: doğrudan embed (Taraftarium tarzı)

  const ContentSource({
    required this.type,
    required this.title,
    required this.url,
    this.embedBase = '',
    this.embedOnly = false,
  });

  bool get isM3u => type.toLowerCase() == 'm3u';
  bool get isResolve => type.toLowerCase() == 'resolve';

  factory ContentSource.fromJson(Map<String, dynamic> j) => ContentSource(
        type: (j['type'] ?? '').toString().trim(),
        title: (j['title'] ?? '').toString().trim(),
        url: (j['url'] ?? '').toString().trim(),
        embedBase: (j['embed_base'] ?? j['embedBase'] ?? '').toString().trim(),
        embedOnly: j['embed_only'] == true || j['embedOnly'] == true,
      );

  /// RC string'ini (JSON dizi) güvenle ayrıştırır; hatalıysa boş liste.
  static List<ContentSource> parseList(String raw) {
    if (raw.trim().isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => ContentSource.fromJson(e.cast<String, dynamic>()))
          .where((s) => s.url.isNotEmpty && (s.isM3u || s.isResolve))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
