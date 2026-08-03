import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/premium_model.dart';
import 'remote_config_service.dart';

/// Boss / Patron-Taraftarium / genel premium spor kaynaklarını çekip tek tip
/// [PremiumItem] listesine çevirir. Android PremiumSporActivity'nin
/// cekVeIsle + parsePatronMatches + parseBossChannels + futbol filtresi portu.
///
/// İçerik-tabanlı yönlendirme (gövdenin ilk karakterine göre):
///   `[ ... ]`                              -> Patron matches (resolver'lı)
///   `{ data:[...], success|generated_at }` -> Boss channels (doğrudan m3u8)
///   `{ items | list.item }`                -> genel premium (hazır media_url)
class PremiumService {
  final _rc = RemoteConfigService();

  static const _bossUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
  static const _browserUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36';
  static const _izinliSpor = ['football', 'futbol', 'soccer'];

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    responseType: ResponseType.plain,
    followRedirects: true,
  ));

  // ── RC yardımcıları (domain APK'da DEĞİL; hepsi Remote Config'ten) ─────────
  String _trimSlash(String s) {
    s = s.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  String _patronEmbedBase() => _trimSlash(_rc.getString('patron_embed_base'));
  String _patronRefererBase() {
    final r = _rc.getString('patron_referer').trim();
    return r.isEmpty ? _patronEmbedBase() : _trimSlash(r);
  }

  String _patronReferer() => '${_patronRefererBase()}/';
  String _patronOrigin() => _patronRefererBase();
  String _resolverBase() => _rc.getString('patron_resolver').trim();

  String _siteParam() {
    final site = _rc.getString('taraftarium_site').trim();
    if (site.isEmpty) return '';
    return '&site=${Uri.encodeQueryComponent(site)}';
  }

  String _bossRefererFromUrl(String u) {
    try {
      final su = Uri.parse(u);
      return '${su.scheme}://${su.host}/';
    } catch (_) {
      return '';
    }
  }

  String _extractId(String u) {
    final idx = u.indexOf('id=');
    return idx < 0 ? '' : u.substring(idx + 3);
  }

  /// Bir veya birden fazla kaynağı (Boss matches + channels gibi) tek listede
  /// toplar, futbol filtresini uygular.
  Future<List<PremiumItem>> fetch({
    required List<String> urls,
    bool embedOnly = false,
    String sectionEmbedBase = '',
    String bossEmbedBase = '',
  }) async {
    final all = <PremiumItem>[];
    for (final u in urls) {
      if (u.trim().isEmpty) continue;
      try {
        await _cekVeIsle(u.trim(), all,
            embedOnly: embedOnly,
            sectionEmbedBase: _trimSlash(sectionEmbedBase),
            bossEmbedBase: bossEmbedBase.trim());
      } catch (_) {/* bir kaynak patlarsa diğerleri devam etsin */}
    }
    return _sadeceFutbolFiltrele(all);
  }

  Future<void> _cekVeIsle(
    String url,
    List<PremiumItem> out, {
    required bool embedOnly,
    required String sectionEmbedBase,
    required String bossEmbedBase,
  }) async {
    final resp = await _dio.get(
      url,
      options: Options(headers: {
        'User-Agent': _browserUa,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'tr-TR,tr;q=0.9,en;q=0.8',
      }),
    );
    final body = (resp.data is String ? resp.data as String : '').trim();
    if (body.isEmpty) return;

    String srcBase = '';
    try {
      final su = Uri.parse(url);
      srcBase = '${su.scheme}://${su.host}';
    } catch (_) {}

    if (body.startsWith('[')) {
      _parsePatronMatches(jsonDecode(body) as List, srcBase, out,
          embedOnly: embedOnly, sectionEmbedBase: sectionEmbedBase);
    } else if (body.startsWith('{')) {
      final obj = jsonDecode(body);
      if (obj is Map &&
          obj['data'] is List &&
          (obj.containsKey('success') || obj.containsKey('generated_at'))) {
        _parseBossChannels(obj['data'] as List, _bossRefererFromUrl(url), out,
            bossEmbedBase: bossEmbedBase);
      } else if (obj is Map) {
        List? items;
        if (obj['list'] is Map && (obj['list'] as Map)['item'] is List) {
          items = (obj['list'] as Map)['item'] as List;
        } else if (obj['items'] is List) {
          items = obj['items'] as List;
        }
        if (items != null) {
          for (final e in items.whereType<Map>()) {
            out.add(PremiumItem(
              title: (e['title'] ?? 'Bilinmeyen').toString(),
              mediaUrl: (e['media_url'] ?? '').toString(),
              thumb: (e['thumb'] ?? '').toString(),
              referer: (e['referer'] ?? '').toString(),
              origin: (e['origin'] ?? '').toString(),
              group: (e['group'] ?? '').toString(),
            ));
          }
        }
      }
    }
  }

  // ── Patron/Taraftarium (matches.php | channels.php ham dizisi) ─────────────
  void _parsePatronMatches(
    List matches,
    String srcBase,
    List<PremiumItem> out, {
    required bool embedOnly,
    required String sectionEmbedBase,
  }) {
    final embedBase = _patronEmbedBase();
    final ref = _patronReferer();
    final org = _patronOrigin();
    final resolver = _resolverBase();
    final site = _siteParam();

    for (final m in matches.whereType<Map>()) {
      var rawUrl = (m['URL'] ?? '').toString().trim(); // "/ch.html?id=XXX"
      final id = _extractId(rawUrl);
      if (id.isEmpty && rawUrl.isEmpty) continue;
      if (!rawUrl.startsWith('/')) rawUrl = '/$rawUrl';

      String embed, media, directEmbed = '';
      if (embedOnly) {
        final base = sectionEmbedBase.isNotEmpty ? sectionEmbedBase : embedBase;
        directEmbed = base.isEmpty ? '' : base + rawUrl;
        embed = directEmbed;
        media = '';
      } else {
        embed = embedBase.isEmpty ? '' : embedBase + rawUrl;
        media = (resolver.isEmpty || id.isEmpty)
            ? ''
            : '$resolver?id=${Uri.encodeQueryComponent(id)}$site';
      }

      final mac = (m['Mac'] ?? '').toString().trim();
      final home = (m['HomeTeam'] ?? '').toString().trim();
      final away = (m['AwayTeam'] ?? '').toString().trim();
      final lig = (m['league'] ?? '').toString().trim();
      final saat = (m['Time'] ?? '').toString().trim();

      String title, group, logo;
      if (mac.isNotEmpty) {
        title = mac;
        group = lig.isEmpty ? '7/24' : lig;
        logo = (m['Logo'] ?? '').toString();
      } else {
        if (home.isNotEmpty && away.isNotEmpty && home != away) {
          title = '$home - $away';
        } else {
          title = lig.isNotEmpty ? lig : (home.isNotEmpty ? home : id);
        }
        if (saat.isNotEmpty) title = '$saat  $title';
        group = lig.isEmpty ? 'Spor' : lig;
        logo = (m['HomeLogo'] ?? m['Logo'] ?? '').toString();
      }
      if (logo.startsWith('/') && srcBase.isNotEmpty) logo = srcBase + logo;

      var itemRef = ref, itemOrg = org;
      if (embedOnly && directEmbed.isNotEmpty) {
        final base = sectionEmbedBase.isNotEmpty ? sectionEmbedBase : embedBase;
        itemRef = '$base/';
        itemOrg = base;
      }

      out.add(PremiumItem(
        title: title,
        mediaUrl: media,
        embedUrl: embed,
        directEmbedUrl: directEmbed,
        thumb: logo,
        referer: itemRef,
        origin: itemOrg,
        userAgent: _bossUa,
        group: group,
      ));
    }
  }

  // ── Boss Sports /api/channels|matches ({ success, data:[...] }) ────────────
  void _parseBossChannels(
    List data,
    String referer,
    List<PremiumItem> out, {
    required String bossEmbedBase,
  }) {
    final ref = referer.isEmpty ? '' : referer;
    final origin =
        ref.endsWith('/') ? ref.substring(0, ref.length - 1) : ref;

    for (final c in data.whereType<Map>()) {
      var media = '';
      final st = c['streams'];
      if (st is List && st.isNotEmpty && st.first is Map) {
        media = ((st.first as Map)['url'] ?? '').toString();
      }
      if (media.isEmpty) media = (c['videoid'] ?? '').toString();
      if (media.isEmpty) continue;

      final cat = (c['category'] ?? '').toString().trim();
      final league = (c['league'] ?? '').toString().trim();
      final kanalMi = (c['is_channel'] == true) ||
          cat.toLowerCase() == 'channels' ||
          league.toLowerCase() == 'live tv';

      if (!media.toLowerCase().contains('.m3u8')) media = '$media#.m3u8';

      final home = (c['home'] ?? '').toString().trim();
      final away = (c['away'] ?? '').toString().trim();
      String title;
      if (home.isNotEmpty && away.isNotEmpty && home != away) {
        title = '$home - $away';
      } else if (home.isNotEmpty) {
        title = home;
      } else {
        title = (c['upstream_id'] ?? 'Kanal').toString();
      }

      final group =
          league.isNotEmpty ? league : (cat.isNotEmpty ? cat : 'Canlı');
      final logo = (c['home_icon'] ?? c['logo'] ?? '').toString();

      var embedUrl = '';
      var directEmbedUrl = '';
      if (bossEmbedBase.isNotEmpty) {
        var bid = (c['id'] ?? '').toString().trim();
        if (bid.isEmpty) bid = (c['upstream_id'] ?? '').toString().trim();
        if (bid.isNotEmpty) {
          final embedU = bossEmbedBase + Uri.encodeQueryComponent(bid);
          if (kanalMi) {
            directEmbedUrl = embedU;
          } else {
            embedUrl = embedU;
          }
        }
      }

      out.add(PremiumItem(
        title: title,
        mediaUrl: media,
        embedUrl: embedUrl,
        directEmbedUrl: directEmbedUrl,
        thumb: logo,
        referer: ref,
        origin: origin,
        userAgent: _bossUa,
        group: group,
        // Futbol filtresi: SADECE maçlar etiketlenir; kanallar (etiketsiz) kalır.
        sport: kanalMi ? '' : cat.toLowerCase(),
      ));
    }
  }

  List<PremiumItem> _sadeceFutbolFiltrele(List<PremiumItem> list) {
    return list.where((it) {
      if (it.sport.isEmpty) return true; // kanal → kalsın
      return _izinliSpor.any((a) => it.sport.contains(a));
    }).toList();
  }
}
