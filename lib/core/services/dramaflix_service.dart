import 'package:dio/dio.dart';
import '../models/series_model.dart';
import 'remote_config_service.dart';

/// CDN oynatma bileti — dramaflix_api.php `?r=ticket`'ten gelir.
/// Video artık SUNUCUDAN proxy'lenmiyor; cihaz CDN'den (cdn.dramaflix.cc)
/// DOĞRUDAN oynatıyor. Cloudflare sunucu IP'lerini blokluyor ama gerçek
/// mobil cihazın IP'si geçiyor. Bilet, cihazın CDN'e giderken taşıması
/// gereken Cookie (dfexp/dfsig) + Referer + tarayıcı User-Agent'ını verir.
class DramaflixTicket {
  final String cookie;
  final String referer;
  final String userAgent;
  const DramaflixTicket({
    required this.cookie,
    required this.referer,
    required this.userAgent,
  });

  /// Oynatıcının (better_player) video/altyazı akışını çekerken kullanacağı
  /// HTTP başlıkları. Boş alanlar eklenmez.
  Map<String, String> get headers => {
        'User-Agent':
            userAgent.isNotEmpty ? userAgent : DramaflixService.cdnUserAgent,
        if (referer.isNotEmpty) 'Referer': referer,
        if (cookie.isNotEmpty) 'Cookie': cookie,
      };
}

/// dramaflix_api.php ile konuşur (Android uygulamasıyla aynı backend).
/// PHP tarafı sadece User-Agent'ında "TineTV" geçen istekleri kabul eder —
/// normal bir tarayıcıdan erişilirse 404 döner.
class DramaflixService {
  static final DramaflixService _instance = DramaflixService._();
  factory DramaflixService() => _instance;
  DramaflixService._();

  // JSON API (r=api, r=ticket) istekleri bu User-Agent'ı taşımak zorunda —
  // PHP tarafı "TineTV" geçmeyen istekleri 404'ler.
  static const userAgent = 'TineTV-iOS/1.0';

  // CDN'e DOĞRUDAN gidilen (video/altyazı) isteklerde kullanılan tarayıcı
  // User-Agent'ı. Normalde bilet (`?r=ticket`) kendi user_agent'ını verir;
  // bilet gelmezse bu yedek devreye girer. Buraya "TineTV" YAZMA — CDN'in
  // önündeki Cloudflare gerçek bir tarayıcı UA'sı bekler.
  static const cdnUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0 Safari/537.36';

  final Dio _dio = Dio(BaseOptions(
    headers: {'User-Agent': userAgent},
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  String get _baseUrl => RemoteConfigService().tineflixApiUrl;

  Future<List<Series>> fetchSeries({
    String? lang,
    String? search,
    String? platform,
    int limit = 24,
    int offset = 0,
  }) async {
    if (_baseUrl.isEmpty) return [];
    try {
      final resp = await _dio.get(_baseUrl, queryParameters: {
        'r': 'api',
        'action': 'series',
        'limit': limit,
        'offset': offset,
        if (lang != null && lang.isNotEmpty) 'lang': lang,
        if (search != null && search.isNotEmpty) 'search': search,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
      });
      final data = resp.data;
      if (data is! Map) return [];
      final list = (data['series'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => Series.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<SeriesDetail?> fetchDetail(String slug) async {
    if (_baseUrl.isEmpty || slug.isEmpty) return null;
    try {
      final resp = await _dio.get(_baseUrl, queryParameters: {
        'r': 'api',
        'action': 'detail',
        'slug': slug,
      });
      final data = resp.data;
      if (data is! Map) return null;
      final seriesJson = data['series'];
      if (seriesJson is! Map) return null;
      final episodesJson = (data['episodes'] as List?) ?? const [];
      final episodes = episodesJson
          .whereType<Map>()
          .map((e) => Episode.fromJson(e.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      return SeriesDetail(
        series: Series.fromJson(seriesJson.cast<String, dynamic>()),
        episodes: episodes,
      );
    } catch (_) {
      return null;
    }
  }

  /// CDN oynatma bileti (Cookie + Referer + UA) — `?r=ticket`.
  /// Oynatıcı bölüm/altyazı URL'lerini (cdn.dramaflix.cc) DOĞRUDAN çekerken
  /// bu bileti başlık olarak kullanır. Sunucu bileti ~55 dk önbelleğe alır,
  /// domain değişirse yalnızca PHP tarafındaki DFX_BASE/DFX_CDN değişir —
  /// uygulamaya (bu koda) dokunmaya gerek yoktur.
  Future<DramaflixTicket?> fetchTicket() async {
    if (_baseUrl.isEmpty) return null;
    try {
      final resp = await _dio.get(_baseUrl, queryParameters: {'r': 'ticket'});
      final data = resp.data;
      if (data is! Map) return null;
      return DramaflixTicket(
        cookie: data['cookie'] as String? ?? '',
        referer: data['referer'] as String? ?? '',
        userAgent: data['user_agent'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
