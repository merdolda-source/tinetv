import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/premium_model.dart';
import 'remote_config_service.dart';

/// Play-time resolver — Android PlayerActivity'deki
/// isResolverUrl / resolverHttpUrl / applyResolverJson mantığının birebir portu.
///
/// Patron/Taraftarium maçları doğrudan m3u8 vermez; `media_url` bir resolver
/// endpoint'idir (…/resolver.php?id=…). Cihaz o adrese gider, dönen JSON'dan
/// TAZE stream URL + başlıkları (Referer/Origin/UA/Cookie) alır ve onu oynatır.
/// Boss kanalları ise doğrudan m3u8 taşır → resolver'a hiç uğramaz.
class PremiumResolver {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    responseType: ResponseType.plain,
    followRedirects: true,
  ));

  static const _cfDefaultUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  /// media_url bir resolver endpoint'i mi? (ham m3u8 yerine sunucu-çözüm)
  static bool isResolverUrl(String? u) {
    if (u == null) return false;
    return u.startsWith('tineresolve://') ||
        u.contains('resolver.php') ||
        u.contains('resolve=1');
  }

  /// resolver çağrısı için gerçek HTTP adresi. RC 'resolver_url' varsa
  /// resolver.php tabanını onunla değiştirir (query '?id=...' korunur) —
  /// tek RC değeriyle tüm resolver adresi taşınabilir.
  static String resolverHttpUrl(String u) {
    if (u.startsWith('tineresolve://')) {
      u = 'https://${u.substring('tineresolve://'.length)}';
    }
    final rcBase = RemoteConfigService().getString('resolver_url').trim();
    if (rcBase.isNotEmpty && u.contains('resolver.php')) {
      final q = u.indexOf('?');
      final query = q >= 0 ? u.substring(q) : '';
      return rcBase + query;
    }
    return u;
  }

  static String? _firstNonEmpty(Map o, List<String> keys) {
    for (final k in keys) {
      final v = o[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  /// Resolver'a sorar, JSON'dan stream + başlıkları çıkarır. Başarısızsa null.
  static Future<PlayResource?> resolve(PremiumItem item) async {
    final endpoint = resolverHttpUrl(item.mediaUrl);
    try {
      final resp = await _dio.get(
        endpoint,
        options: Options(headers: {
          'User-Agent':
              item.userAgent.isNotEmpty ? item.userAgent : _cfDefaultUa,
          'Accept': 'application/json,*/*',
          if (item.referer.isNotEmpty) 'Referer': item.referer,
        }),
      );
      final body = resp.data;
      if (body is! String || body.trim().isEmpty) return null;
      final o = jsonDecode(body.trim());
      if (o is! Map) return null;

      final v = _firstNonEmpty(
          o, ['VideoURL', 'video_url', 'url', 'stream', 'media_url', 'link']);
      if (v == null || v.isEmpty) return null;

      final referer =
          _firstNonEmpty(o, ['Referer', 'referer']) ?? item.referer;
      final origin = _firstNonEmpty(o, ['Origin', 'origin']) ?? item.origin;
      final ua = _firstNonEmpty(
              o, ['User-Agent', 'userAgent', 'user_agent', 'ua']) ??
          (item.userAgent.isNotEmpty ? item.userAgent : _cfDefaultUa);
      final cookie = _firstNonEmpty(o, ['Cookie', 'cookie']);

      final headers = <String, String>{'User-Agent': ua};
      if (referer.isNotEmpty) headers['Referer'] = referer;
      if (origin.isNotEmpty) headers['Origin'] = origin;
      if (cookie != null && cookie.isNotEmpty) headers['Cookie'] = cookie;
      // İsteğe bağlı ek başlıklar (h.headers objesi).
      final h = o['headers'];
      if (h is Map) {
        h.forEach((k, val) {
          if (val != null) headers[k.toString()] = val.toString();
        });
      }
      return PlayResource(v, headers);
    } catch (_) {
      return null;
    }
  }

  /// Doğrudan m3u8 (Boss) için başlıkları hazırla — resolver yok.
  static PlayResource direct(PremiumItem item) {
    final headers = <String, String>{
      'User-Agent': item.userAgent.isNotEmpty ? item.userAgent : _cfDefaultUa,
    };
    if (item.referer.isNotEmpty) headers['Referer'] = item.referer;
    if (item.origin.isNotEmpty) headers['Origin'] = item.origin;
    return PlayResource(item.mediaUrl, headers);
  }
}
