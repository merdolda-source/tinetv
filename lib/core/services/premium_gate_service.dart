import 'package:hive_flutter/hive_flutter.dart';

/// Premium/Patron gibi bölümlere GİRİŞ kapısı. Ödüllü reklam izlenince belirli
/// süre (varsayılan 6 saat) giriş serbest kalır. Cihazda saklanır — hesap yok.
/// Reklamları GİZLEMEZ (geçiş reklamları çalışmaya devam eder); sadece premium
/// bölümlerin kilidini yönetir.
class PremiumGateService {
  static final PremiumGateService _instance = PremiumGateService._();
  factory PremiumGateService() => _instance;
  PremiumGateService._();

  static const _boxName = 'premium_gate';
  static const _key = 'unlockUntilMs';

  Box? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  bool get isUnlocked {
    final until = (_box?.get(_key, defaultValue: 0) as int?) ?? 0;
    return until > DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> unlockHours(int hours) async {
    final until =
        DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch;
    await _box?.put(_key, until);
  }
}
