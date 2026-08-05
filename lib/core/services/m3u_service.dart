import 'package:dio/dio.dart';
import '../models/channel_model.dart';

class M3uService {
  final _dio = Dio();

  Future<List<Channel>> fetchChannels(String url) async {
    if (url.isEmpty) return [];

    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      return _parseM3u(response.data as String);
    } catch (e) {
      return [];
    }
  }

  List<Channel> _parseM3u(String content) {
    // Android M3UParser paritesi: kompakt (tek satır) M3U'ları normalize et —
    // #EXTINF / #EXTVLCOPT önüne satır sonu koy ki her etiket ayrı satır olsun.
    content = content
        .replaceAll('#EXTINF', '\n#EXTINF')
        .replaceAll('#EXTVLCOPT', '\n#EXTVLCOPT');

    final lines = content.split('\n');
    final channels = <Channel>[];
    String? name, logo, group, tvgId, referer, origin, userAgent;

    void reset() {
      name = logo = group = tvgId = referer = origin = userAgent = null;
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF')) {
        name = _extract(line, 'tvg-name') ?? _lastName(line);
        logo = _extract(line, 'tvg-logo');
        group = _extract(line, 'group-title');
        tvgId = _extract(line, 'tvg-id');
      } else if (line.startsWith('#EXTVLCOPT:http-referrer=')) {
        referer = line.substring('#EXTVLCOPT:http-referrer='.length).trim();
      } else if (line.startsWith('#EXTVLCOPT:http-user-agent=')) {
        userAgent = line.substring('#EXTVLCOPT:http-user-agent='.length).trim();
      } else if (line.startsWith('#EXTVLCOPT:http-origin=')) {
        origin = line.substring('#EXTVLCOPT:http-origin='.length).trim();
      } else if ((line.startsWith('http://') || line.startsWith('https://')) &&
          name != null) {
        channels.add(
          Channel(
            name: name!,
            url: line,
            logo: logo,
            group: group,
            tvgId: tvgId,
            referer: referer,
            origin: origin,
            userAgent: userAgent,
          ),
        );
        reset();
      }
    }
    return channels;
  }

  String? _extract(String line, String key) {
    final reg = RegExp('$key="([^"]*)"');
    return reg.firstMatch(line)?.group(1);
  }

  String? _lastName(String line) {
    final parts = line.split(',');
    return parts.length > 1 ? parts.last.trim() : null;
  }
}
