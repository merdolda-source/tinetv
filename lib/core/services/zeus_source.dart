import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/premium_model.dart';

/// Zeus TV kaynağı — SUNUCUSUZ (PHP yok). Android ZeusKaynak'ın birebir portu.
/// Cihaz doğrudan zeus API'siyle konuşur:
///   /api/channels.php        → Canlı TV (embed_code: /ch.html?id=b1)
///   /api/today_matches.php   → Günün maçları (futbol) — tıklamada çözülür
///   /api/get_match_channels.php?match_id=X → maçın kanalları (resolveMatch)
///
/// m3u8: ch.html → {CDN}/{id}/index.txt (CDN, ch.html'den DİNAMİK okunur →
/// link/CDN değişince otomatik takip). Referer = site. Domain RC'den (zeus_base).
///
/// DÜZ JSON API istemcisi — şifre/imza/steganografi çözme YOK.
class ZeusSource {
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
  static const _cdnFallback = 'https://zeus324232.cfd/';

  // Futbol DIŞI ligleri ele (sadece futbol istendi). Geri kalan futbol sayılır.
  static const _futbolDisi = [
    'basket', 'nba', 'euroleague', 'voleyb', 'volley', 'tenis', 'tennis',
    'atp', 'wta', 'hentbol', 'handball', 'buz hokey', 'hockey', 'beyzbol',
    'baseball', 'amerikan futbol', 'nfl', 'mma', 'ufc', 'boks', 'boxing',
    'formula', 'moto', 'snooker', 'darts', 'rugby', 'hokey',
  ];

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
    responseType: ResponseType.plain,
    followRedirects: true,
  ));

  static String _trimSlash(String s) {
    s = s.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static Future<String> _get(String url, String referer) async {
    try {
      final r = await _dio.get(url,
          options: Options(headers: {
            'User-Agent': _ua,
            'Accept': 'application/json,*/*',
            if (referer.isNotEmpty) 'Referer': referer,
          }));
      return r.data is String ? r.data as String : '';
    } catch (_) {
      return '';
    }
  }

  /// ch.html'den yayın CDN tabanını DİNAMİK okur (link takibi). Alınamazsa fallback.
  static Future<String> cdnBase(String site) async {
    try {
      final html = await _get('$site/ch.html?id=b1', '$site/');
      final m1 =
          RegExp(r'"(https?://[^"]+/)"\s*\+\s*streamId').firstMatch(html);
      if (m1 != null) return m1.group(1)!;
      final m2 = RegExp(r'"(https?://[^"]+/)"\s*\+').firstMatch(html);
      if (m2 != null) return m2.group(1)!;
    } catch (_) {}
    return _cdnFallback;
  }

  /// embed_code içindeki  /ch.html?id=b1  → b1
  static String _chId(String embed) {
    final m = RegExp(r'ch\.html\?id=([A-Za-z0-9_]+)').firstMatch(embed);
    return m != null ? m.group(1)! : '';
  }

  /// index.txt uçlarına zararsız #.m3u8 ipucu ekle (fragment sunucuya gitmez,
  /// yalnızca oynatıcının HLS MIME tespiti için).
  static String _hls(String u) {
    if (u.isEmpty) return u;
    return u.toLowerCase().contains('.m3u8') ? u : '$u#.m3u8';
  }

  static bool _playable(String u) {
    final l = u.toLowerCase();
    return l.startsWith('http') &&
        (l.contains('.m3u8') || l.contains('/index.txt') || l.contains('.txt'));
  }

  static bool _football(String lig) {
    final l = lig.toLowerCase();
    for (final d in _futbolDisi) {
      if (l.contains(d)) return false;
    }
    return true;
  }

  // ── Canlı TV (channels.php) — doğrudan m3u8 ────────────────────────────────
  static Future<List<PremiumItem>> fetchChannels(String siteRaw) async {
    final out = <PremiumItem>[];
    final site = _trimSlash(siteRaw);
    if (site.isEmpty) return out;
    final ref = '$site/';
    final cdn = await cdnBase(site);
    final body = await _get('$site/api/channels.php', ref);
    if (body.isEmpty) return out;
    try {
      final o = jsonDecode(body);
      final arr =
          (o is Map && o['channels'] is List) ? o['channels'] as List : const [];
      for (final e in arr.whereType<Map>()) {
        final status = (e['status'] ?? 'active').toString().toLowerCase();
        if (status != 'active') continue;
        final id = _chId((e['embed_code'] ?? '').toString());
        final direct = (e['stream_url'] ?? '').toString().trim();
        String media;
        if (id.isNotEmpty) {
          media = _hls('$cdn$id/index.txt');
        } else if (_playable(direct)) {
          media = _hls(direct);
        } else {
          continue;
        }
        out.add(PremiumItem(
          title: (e['name'] ?? 'Kanal').toString(),
          group: 'Canlı TV',
          mediaUrl: media,
          referer: ref,
          origin: site,
          userAgent: _ua,
          thumb: (e['logo_url'] ?? '').toString(),
        ));
      }
    } catch (_) {}
    return out;
  }

  // ── Günün Maçları (today_matches.php) — SADECE FUTBOL, tıklamada çözülür ────
  static Future<List<PremiumItem>> fetchMatches(String siteRaw) async {
    final out = <PremiumItem>[];
    final site = _trimSlash(siteRaw);
    if (site.isEmpty) return out;
    final ref = '$site/';
    final cdn = await cdnBase(site);
    final body = await _get('$site/api/today_matches.php', ref);
    if (body.isEmpty) return out;
    try {
      final o = jsonDecode(body);
      final arr =
          (o is Map && o['matches'] is List) ? o['matches'] as List : const [];
      for (final e in arr.whereType<Map>()) {
        final lig = (e['league_name'] ?? '').toString();
        if (!_football(lig)) continue; // sadece futbol
        final home = (e['home_team'] ?? '').toString().trim();
        final away = (e['away_team'] ?? '').toString().trim();
        if (home.isEmpty && away.isEmpty) continue;
        final saat = (e['match_time'] ?? '').toString().trim();
        var title = (home.isNotEmpty && away.isNotEmpty)
            ? '$home - $away'
            : (home.isNotEmpty ? home : away);
        if (saat.isNotEmpty) title = '$saat  $title';
        final mid = (e['id'] ?? '').toString();
        out.add(PremiumItem(
          title: title,
          group: lig.isEmpty ? 'Maçlar' : lig,
          thumb: (e['home_logo'] ?? '').toString(),
          referer: ref,
          origin: site,
          userAgent: _ua,
          // media_url boş → tıklamada resolveMatch ile çözülür.
          zeusMatchUrl: '$site/api/get_match_channels.php?match_id=$mid',
          zeusCdn: cdn,
        ));
      }
    } catch (_) {}
    return out;
  }

  /// Maç tıklanınca kanalları çekip oynatılabilir bir m3u8 döndürür (yoksa null).
  static Future<String?> resolveMatch(
      String matchUrl, String cdn, String referer) async {
    if (matchUrl.isEmpty) return null;
    final body = await _get(matchUrl, referer);
    if (body.isEmpty) return null;
    try {
      final o = jsonDecode(body);
      final arr =
          (o is Map && o['channels'] is List) ? o['channels'] as List : const [];
      String? embedFallback;
      for (final e in arr.whereType<Map>()) {
        final id = _chId((e['embed_code'] ?? '').toString());
        if (id.isNotEmpty) {
          final base = cdn.isNotEmpty ? cdn : _cdnFallback;
          return _hls('$base$id/index.txt');
        }
        final direct = (e['stream_url'] ?? '').toString().trim();
        if (_playable(direct)) embedFallback ??= _hls(direct);
      }
      return embedFallback; // ch.html yoksa doğrudan m3u8 (varsa)
    } catch (_) {
      return null;
    }
  }
}
