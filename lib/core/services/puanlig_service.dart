import 'package:dio/dio.dart';
import '../models/puanlig_model.dart';
import 'remote_config_service.dart';

class PuanligService {
  static final PuanligService _instance = PuanligService._();
  factory PuanligService() => _instance;
  PuanligService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  String get _baseUrl => RemoteConfigService().puanligApiUrl;

  Future<PuanDurumuVeri?> fetch({String? lig}) async {
    if (_baseUrl.isEmpty) return null;
    try {
      final resp = await _dio.get(_baseUrl, queryParameters: {
        if (lig != null && lig.isNotEmpty) 'lig': lig,
      });
      final data = resp.data;
      if (data is! Map || data['basarili'] != true) return null;

      final liglerJson = (data['ligler'] as List?) ?? const [];
      final ligler = liglerJson
          .whereType<Map>()
          .map((e) => PuanLig.fromJson(e.cast<String, dynamic>()))
          .toList();

      final veri = data['veri'];
      if (veri is! Map) return null;

      List<PuanSatiri> parseList(String key) {
        final list = (veri[key] as List?) ?? const [];
        return list
            .whereType<Map>()
            .map((e) => PuanSatiri.fromJson(e.cast<String, dynamic>(), _baseUrl))
            .toList();
      }

      return PuanDurumuVeri(
        ligler: ligler,
        genel: parseList('genel'),
        icSaha: parseList('icSaha'),
        disSaha: parseList('disSaha'),
      );
    } catch (_) {
      return null;
    }
  }
}
