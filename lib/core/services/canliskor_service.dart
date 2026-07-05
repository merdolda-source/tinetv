import 'package:dio/dio.dart';
import '../models/canliskor_model.dart';
import 'remote_config_service.dart';

class CanliskorService {
  static final CanliskorService _instance = CanliskorService._();
  factory CanliskorService() => _instance;
  CanliskorService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  String get _baseUrl => RemoteConfigService().canliskorApiUrl;

  Future<List<TurnuvaVeri>> fetchList() async {
    if (_baseUrl.isEmpty) return [];
    try {
      final resp = await _dio.get(_baseUrl);
      final data = resp.data;
      if (data is! Map || data['basarili'] != true) return [];
      final list = (data['veri'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => TurnuvaVeri.fromJson(e.cast<String, dynamic>(), _baseUrl))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<MacDetay?> fetchDetail(String macUrl) async {
    if (_baseUrl.isEmpty || macUrl.isEmpty) return null;
    try {
      final resp = await _dio.get(_baseUrl, queryParameters: {
        'aksiyon': 'detay',
        'macUrl': macUrl,
      });
      final data = resp.data;
      if (data is! Map || data['basarili'] != true) return null;

      final olaylarJson = (data['olaylar'] as List?) ?? const [];
      final puanDurumuJson = (data['puanDurumu'] as List?) ?? const [];
      final kadrolar = data['kadrolar'];

      List<KadroVeri> parseKadro(dynamic list) {
        if (list is! List) return [];
        return list
            .whereType<Map>()
            .map((e) => KadroVeri.fromJson(e.cast<String, dynamic>(), _baseUrl))
            .toList();
      }

      return MacDetay(
        olaylar: olaylarJson.whereType<Map>().map((e) => OlayVeri.fromJson(e.cast<String, dynamic>())).toList(),
        puanDurumu: puanDurumuJson
            .whereType<Map>()
            .map((e) => MacPuanSatiri.fromJson(e.cast<String, dynamic>(), _baseUrl))
            .toList(),
        kadroEv: kadrolar is Map ? parseKadro(kadrolar['ev']) : [],
        kadroMisafir: kadrolar is Map ? parseKadro(kadrolar['misafir']) : [],
      );
    } catch (_) {
      return null;
    }
  }
}
