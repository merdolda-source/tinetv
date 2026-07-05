import 'package:dio/dio.dart';
import '../models/haber_model.dart';
import 'remote_config_service.dart';

class HaberService {
  static final HaberService _instance = HaberService._();
  factory HaberService() => _instance;
  HaberService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  String get _baseUrl => RemoteConfigService().haberApiUrl;

  Future<List<HaberOzet>> fetchList() async {
    if (_baseUrl.isEmpty) return [];
    try {
      final resp = await _dio.get(_baseUrl);
      final data = resp.data;
      if (data is! Map || data['basarili'] != true) return [];
      final list = (data['veri'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => HaberOzet.fromJson(e.cast<String, dynamic>(), _baseUrl))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // "detayPath" liste API'sinden zaten hazır sorgu string'i olarak geliyor
  // (örn. "api_haber.php?u=..."), tabanUrl ile birleştirip doğrudan çağırıyoruz.
  Future<HaberDetay?> fetchDetail(String detayPath) async {
    if (_baseUrl.isEmpty || detayPath.isEmpty) return null;
    try {
      final url = Uri.parse(_baseUrl).resolve(detayPath).toString();
      final resp = await _dio.get(url);
      final data = resp.data;
      if (data is! Map || data['basarili'] != true) return null;
      final veri = data['veri'];
      if (veri is! Map) return null;
      return HaberDetay.fromJson(veri.cast<String, dynamic>(), _baseUrl);
    } catch (_) {
      return null;
    }
  }
}
