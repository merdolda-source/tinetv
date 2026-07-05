import 'package:dio/dio.dart';
import '../models/film_model.dart';
import 'remote_config_service.dart';

class FilmService {
  static final FilmService _instance = FilmService._();
  factory FilmService() => _instance;
  FilmService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  String get _baseUrl => RemoteConfigService().filmApiUrl;

  Future<List<Film>> fetchFilms({int page = 1}) async {
    if (_baseUrl.isEmpty) return [];
    try {
      final resp = await _dio.get(_baseUrl, queryParameters: {'page': page});
      final data = resp.data;
      if (data is! Map) return [];
      final list = (data['films'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => Film.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
