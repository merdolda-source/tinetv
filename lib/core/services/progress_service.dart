import 'package:hive_flutter/hive_flutter.dart';

/// TineFlix'te dizi başına son izlenen bölüm indeksini cihazda saklar.
/// Sadece "kaldığın yerden devam et" işaretlemesi için kullanılır —
/// otomatik devam ettirme (auto-resume) yapılmaz.
class ProgressService {
  static const _boxName = 'dfx_progress';
  static Box? _box;

  static Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  static int? lastEpisodeIndex(String slug) {
    return _box?.get(slug) as int?;
  }

  static Future<void> saveProgress(String slug, int episodeIndex) async {
    await _box?.put(slug, episodeIndex);
  }
}
