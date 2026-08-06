import 'package:flutter/services.dart';

/// Bağımsız (standalone) InMobi — native köprü (InMobiBridge.swift) ile konuşur.
/// Sadece iOS; geçiş (interstitial) + ödül (rewarded). Native (yerli) henüz yok.
class InMobiService {
  static final InMobiService _i = InMobiService._();
  factory InMobiService() => _i;
  InMobiService._() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const MethodChannel _channel = MethodChannel('tinetv/inmobi');

  bool _inited = false;
  bool interstitialReady = false;
  bool rewardedReady = false;

  void Function()? _onInterstitialDone;
  void Function()? _onRewardEarned;
  void Function()? _onRewardedDone;

  Future<void> init(String accountId) async {
    if (_inited || accountId.isEmpty) return;
    _inited = true;
    try {
      await _channel.invokeMethod('init', {'accountId': accountId});
    } catch (_) {}
  }

  // ── Geçiş ──
  Future<void> loadInterstitial(String placementId) async {
    if (placementId.isEmpty) return;
    interstitialReady = false;
    try {
      await _channel.invokeMethod('loadInterstitial', {'placementId': placementId});
    } catch (_) {}
  }

  /// Hazırsa gösterir; kapanınca [onDone] çağrılır. Dönüş: gösterildi mi.
  Future<bool> showInterstitial({void Function()? onDone}) async {
    _onInterstitialDone = onDone;
    try {
      final ok = await _channel.invokeMethod('showInterstitial') == true;
      if (!ok) {
        _onInterstitialDone = null;
      }
      return ok;
    } catch (_) {
      _onInterstitialDone = null;
      return false;
    }
  }

  // ── Ödül ──
  Future<void> loadRewarded(String placementId) async {
    if (placementId.isEmpty) return;
    rewardedReady = false;
    try {
      await _channel.invokeMethod('loadRewarded', {'placementId': placementId});
    } catch (_) {}
  }

  /// Hazırsa gösterir; ödül kazanılırsa [onReward], kapanınca [onDone].
  Future<bool> showRewarded({
    void Function()? onReward,
    void Function()? onDone,
  }) async {
    _onRewardEarned = onReward;
    _onRewardedDone = onDone;
    try {
      final ok = await _channel.invokeMethod('showRewarded') == true;
      if (!ok) {
        _onRewardEarned = null;
        _onRewardedDone = null;
      }
      return ok;
    } catch (_) {
      _onRewardEarned = null;
      _onRewardedDone = null;
      return false;
    }
  }

  Future<dynamic> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'onInterstitialLoaded':
        interstitialReady = true;
        break;
      case 'onInterstitialFailed':
        interstitialReady = false;
        break;
      case 'onInterstitialDismissed':
        interstitialReady = false;
        final cb = _onInterstitialDone;
        _onInterstitialDone = null;
        cb?.call();
        break;
      case 'onRewardedLoaded':
        rewardedReady = true;
        break;
      case 'onRewardedFailed':
        rewardedReady = false;
        break;
      case 'onRewardEarned':
        _onRewardEarned?.call();
        break;
      case 'onRewardedDismissed':
        rewardedReady = false;
        final cb = _onRewardedDone;
        _onRewardedDone = null;
        cb?.call();
        break;
    }
    return null;
  }
}
