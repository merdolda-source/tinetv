import 'package:dio/dio.dart';
import '../models/series_model.dart';
import 'remote_config_service.dart';

/// dramaflix_api.php ile konuşur (Android uygulamasıyla aynı backend).
/// PHP tarafı sadece User-Agent'ında "TineTV" geçen istekleri kabul eder —
/// normal bir tarayıcıdan erişilirse 404 döner.
class DramaflixService {
  static final DramaflixService _instance = DramaflixService._();
  factory DramaflixService() => _instance;
  DramaflixService._();

  // dramaflix_api.php TÜM route'larda (r=api, r=hls, r=seg, r=sub) bu
  // User-Agent'ı arıyor — sadece JSON istekleri değil, oynatıcının
  // video/altyazı akışı için attığı istekler de bunu taşımak zorunda,
  // yoksa sunucu onlara da 404 döner (video "Video can't be played" olur).
  static const userAgent = 'TineTV-iOS/1.0';

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

  // CDN, cookie tabanlı korumalı olduğu için bölüm/altyazı linkleri doğrudan
  // oynatılamaz — PHP tarafındaki r=hls / r=sub proxy'sinden geçirilir
  // (dfexp/dfsig çerezini sunucu ekliyor).
  String proxiedStreamUrl(String cdnUrl) {
    return '$_baseUrl?r=hls&u=${Uri.encodeQueryComponent(cdnUrl)}';
  }

  String proxiedSubtitleUrl(String cdnUrl) {
    return '$_baseUrl?r=sub&u=${Uri.encodeQueryComponent(cdnUrl)}';
  }
}
