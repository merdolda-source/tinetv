import 'package:hive_flutter/hive_flutter.dart';

/// Ödüllü reklam karşılığı geçici reklamsız pencereyi cihazda saklar.
/// Hesap/oturum gerekmez — süre dolana kadar tüm reklam gösterimleri atlanır.
class AdFreeService {
  static final AdFreeService _instance = AdFreeService._();
  factory AdFreeService() => _instance;
  AdFreeService._();

  static const _boxName = 'ad_free';
  static const _key = 'expiresAtMs';

  Box? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  bool get isAdFree {
    final expiresAt = (_box?.get(_key, defaultValue: 0) as int?) ?? 0;
    return expiresAt > DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> grantHours(int hours) async {
    final expiresAt =
        DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch;
    await _box?.put(_key, expiresAt);
  }
}
