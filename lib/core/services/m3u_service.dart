import 'package:dio/dio.dart';
import '../models/channel_model.dart';
import 'remote_config_service.dart';

class M3uService {
  final _dio = Dio();
  final _rc = RemoteConfigService();

  Future<List<Channel>> fetchChannels() async {
    final url = _rc.m3uUrl;
    if (url.isEmpty) return [];

    try {
      final response = await _dio.get(url);
      return _parseM3u(response.data as String);
    } catch (e) {
      return [];
    }
  }

  List<Channel> _parseM3u(String content) {
    final lines = content.split('\n');
    final channels = <Channel>[];
    String? name, logo, group, tvgId;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF')) {
        name = _extract(line, 'tvg-name') ?? _lastName(line);
        logo = _extract(line, 'tvg-logo');
        group = _extract(line, 'group-title');
        tvgId = _extract(line, 'tvg-id');
      } else if (line.startsWith('http') && name != null) {
        channels.add(
          Channel(
            name: name,
            url: line,
            logo: logo,
            group: group,
            tvgId: tvgId,
          ),
        );
        name = logo = group = tvgId = null;
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
