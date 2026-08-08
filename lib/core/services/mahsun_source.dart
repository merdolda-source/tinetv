import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import '../models/premium_model.dart';

/// Mahsun Sports kaynağı — SUNUCUSUZ (PHP YOK). Uygulama, sitenin veri
/// dosyasını (script4.js) ve yayın CDN tabanını (event.html) CİHAZDA okuyup
/// DOĞRUDAN m3u8 listesi üretir; her yayın referer+origin ile oynatılır.
///
///  script4.js → {title, url:/event.html?id=androstreamlive...} dizileri
///  event.html → baseurls[]  ve  m3u8 = base + id + ".m3u8"
///  m3u8 CDN'i referer'siz 403; referer=site/ ile 200.
///
/// Domain değişirse SADECE content_json'daki `url` (site) güncellenir — uygulama
/// güncellemesi GEREKMEZ. iOS'ta CDN "facebooklive" varyantını ister; bunu
/// Platform.isIOS ile otomatik seçeriz.
class MahsunSource {
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 25),
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
            'Accept': '*/*',
            if (referer.isNotEmpty) 'Referer': referer,
          }));
      return r.data is String ? r.data as String : '';
    } catch (_) {
      return '';
    }
  }

  static String? _field(String obj, String key) {
    // Hem `title: "x"` hem `"title": "x"` hem tek tırnak — hepsini yakalar.
    final m = RegExp('["\']?$key["\']?\\s*:\\s*["\']([^"\']*)["\']')
        .firstMatch(obj);
    return m?.group(1)?.trim();
  }

  /// event.html'den yayın CDN tabanını (checklist/ içeren baseurl) okur.
  static Future<String> _cdnBase(String siteBase, String ref) async {
    final html = await _get('$siteBase/event.html?id=androstreamlivebs1', ref);
    for (final m in RegExp(r'"(https?://[^"]+/)"').allMatches(html)) {
      final u = m.group(1)!;
      if (u.toLowerCase().contains('checklist/')) return u;
    }
    return 'https://andro.evrenesoglu57.click/checklist/'; // event.html okunamazsa
  }

  /// event.html JS mantığının birebir portu: id → m3u8.
  static String _buildM3u8(String base, String id, bool ios) {
    if (id == 'androstreamlivebs1' || id == 'facebooklivebs1') {
      return '${base}batutest.m3u8';
    }
    if (id.startsWith('facebooklive')) return '$base$id.m3u8';
    if (id.startsWith('androstreamlive')) {
      if (ios) {
        return '${base}facebooklive${id.substring('androstreamlive'.length)}.m3u8';
      }
      return '$base$id.m3u8';
    }
    return '$base$id.m3u8';
  }

  /// [siteBase] = https://mahsunsports50.xyz (referer/origin + event.html için).
  /// [dataUrl]  = script4.js adresi; boşsa ana sayfadan otomatik bulunur.
  static Future<List<PremiumItem>> fetch(String siteBase,
      {String dataUrl = ''}) async {
    siteBase = _trimSlash(siteBase);
    if (siteBase.isEmpty) return [];
    final ref = '$siteBase/';
    final org = siteBase;

    // 1) script4.js adresini bul
    var jsUrl = dataUrl.trim();
    if (jsUrl.isEmpty) {
      final home = await _get(siteBase, ref);
      final m = RegExp('''src=["']([^"']*script4\\.js[^"']*)["']''')
          .firstMatch(home);
      if (m != null) {
        var u = m.group(1)!;
        if (u.startsWith('http')) {
          jsUrl = u;
        } else if (u.startsWith('//')) {
          jsUrl = 'https:$u';
        } else {
          jsUrl = '$siteBase/${u.replaceFirst(RegExp(r'^/'), '')}';
        }
      }
    }
    if (jsUrl.isEmpty) return [];

    final js = await _get(jsUrl, ref);
    if (js.isEmpty) return [];

    final base = await _cdnBase(siteBase, ref);
    final ios = Platform.isIOS;

    const arrays = {
      'karsilasmalar': 'Maçlar',
      'futbolMatches': 'Futbol',
      'basketbolMatches': 'Basketbol',
      'voleybolMatches': 'Voleybol',
      'tenisMatches': 'Tenis',
      'channels': '7/24 TV',
    };

    final items = <PremiumItem>[];
    final seen = <String>{};
    arrays.forEach((name, label) {
      final bm =
          RegExp('$name\\s*=\\s*\\[(.*?)\\]\\s*;', dotAll: true).firstMatch(js);
      if (bm == null) return;
      final block = bm.group(1)!;
      for (final om in RegExp(r'\{[^{}]*\}', dotAll: true).allMatches(block)) {
        final obj = om.group(0)!;
        final idm = RegExp(r'id=([A-Za-z0-9_]+)').firstMatch(obj);
        if (idm == null) continue;
        final id = idm.group(1)!;
        final title = _field(obj, 'title') ?? id;
        final time = _field(obj, 'time') ?? '';
        final lig = _field(obj, 'league') ?? '';

        final m3u8 = _buildM3u8(base, id, ios);
        if (!seen.add(m3u8)) continue; // aynı yayını iki kez ekleme

        items.add(PremiumItem(
          title: time.isNotEmpty ? '$time  $title' : title,
          group: lig.isNotEmpty ? lig : label,
          mediaUrl: m3u8, // DOĞRUDAN m3u8 (resolver değil)
          referer: ref, // CDN bunu ister → cihaz header olarak taşır
          origin: org,
          userAgent: _ua,
        ));
      }
    });
    return items;
  }
}
