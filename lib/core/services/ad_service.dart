import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:yandex_mobileads/mobile_ads.dart' as ya;
import 'ad_free_service.dart';
import 'remote_config_service.dart';

/// Reklam yöneticisi — Android sistemiyle AYNI mantık:
///   • Aktif ağ (öncelik admob>yandex>unity) geçiş + ödüllü reklamı verir.
///   • NATIVE ve AÇILIŞ (app open) admob aktif değilse OTOMATİK Yandex'ten gelir
///     (Unity/none → yandex). Böylece "Unity açıkken geçiş Unity, native+açılış
///     Yandex" olur — çakışma yok.
///   • Yandex'te Flutter native FORMATI YOK → native yerine Yandex "adaptive
///     inline banner" kullanılır (native_ad_card.dart içinde), video/yüksek CPM.
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  final _rc = RemoteConfigService();
  final _adFree = AdFreeService();

  // AdMob (google_mobile_ads)
  InterstitialAd? _admobInterstitial;
  AppOpenAd? _admobAppOpen;

  // Yandex
  ya.InterstitialAd? _yandexInterstitial;
  ya.AppOpenAd? _yandexAppOpen;

  int _channelOpenCount = 0;

  /// AB/İngiltere gibi bölgelerde AdMob reklam onay formu (UMP). Android'deki
  /// gatherConsentThenInit() ile aynı — reklam SDK'ları başlatılmadan önce.
  Future<void> gatherConsent() async {
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          try {
            ConsentForm.loadAndShowConsentFormIfRequired((_) => finish());
          } catch (_) {
            finish();
          }
        },
        (_) => finish(),
      );
    } catch (_) {
      finish();
    }
    return completer.future;
  }

  Future<void> initialize() async {
    // AdMob — yalnızca açıksa başlat.
    if (_rc.showAdmobAds) {
      try {
        await MobileAds.instance.initialize();
      } catch (_) {}
    }
    // Unity — açıksa başlat.
    if (_rc.showUnityAds) {
      try {
        await UnityAds.init(
          gameId: _rc.unityGameId,
          onComplete: () {},
          onFailed: (error, message) {},
        );
      } catch (_) {}
    }
    // Yandex — native + app open admob değilse buraya düştüğü için HER ZAMAN
    // başlatmayı dene (Android'deki "yandex hep init" mantığı).
    try {
      await ya.MobileAds.initialize();
    } catch (_) {}

    _loadInterstitial();
    _loadAppOpen();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  APP OPEN (açılış) — admob veya yandex
  // ══════════════════════════════════════════════════════════════════════════
  void _loadAppOpen() {
    if (!_rc.appOpenAdEnabled) return;
    final net = _rc.appOpenNetwork; // admob | yandex
    if (net == 'admob') {
      AppOpenAd.load(
        adUnitId: _rc.admobAppOpenId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) => _admobAppOpen = ad,
          onAdFailedToLoad: (error) => _admobAppOpen = null,
        ),
      );
    } else if (net == 'yandex') {
      _loadYandexAppOpen();
    }
  }

  Future<void> _loadYandexAppOpen() async {
    if (_rc.yandexAppOpenId.isEmpty) return;
    try {
      final loader = await ya.AppOpenAdLoader.create(
        onAdLoaded: (ad) => _yandexAppOpen = ad,
        onAdFailedToLoad: (error) => _yandexAppOpen = null,
      );
      await loader.loadAd(
        adRequestConfiguration:
            ya.AdRequestConfiguration(adUnitId: _rc.yandexAppOpenId),
      );
    } catch (_) {
      _yandexAppOpen = null;
    }
  }

  void showAppOpen() {
    if (!_rc.appOpenAdEnabled) return;
    final net = _rc.appOpenNetwork;

    if (net == 'admob') {
      final ad = _admobAppOpen;
      if (ad == null) return;
      _admobAppOpen = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _loadAppOpen();
        },
        onAdFailedToShowFullScreenContent: (a, error) {
          a.dispose();
          _loadAppOpen();
        },
      );
      ad.show();
    } else if (net == 'yandex') {
      final ad = _yandexAppOpen;
      if (ad == null) return;
      _yandexAppOpen = null;
      ad.setAdEventListener(
        eventListener: ya.AppOpenAdEventListener(
          onAdShown: () {},
          onAdFailedToShow: (error) {
            ad.destroy();
            _loadAppOpen();
          },
          onAdClicked: () {},
          onAdDismissed: () {
            ad.destroy();
            _loadAppOpen();
          },
          onAdImpression: (data) {},
        ),
      );
      ad.show();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INTERSTITIAL (geçiş) — admob / yandex / unity
  // ══════════════════════════════════════════════════════════════════════════
  void _loadInterstitial() {
    if (!_rc.interstitialEnabled) return;
    final net = _rc.interstitialNetwork; // admob | yandex | unity
    if (net == 'admob') {
      InterstitialAd.load(
        adUnitId: _rc.admobInterstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _admobInterstitial = ad,
          onAdFailedToLoad: (error) => _admobInterstitial = null,
        ),
      );
    } else if (net == 'yandex') {
      _loadYandexInterstitial();
    }
    // unity: yükleme show anında yapılır (UnityAds.load→showVideoAd).
  }

  Future<void> _loadYandexInterstitial() async {
    if (_rc.yandexInterstitialId.isEmpty) return;
    try {
      final loader = await ya.InterstitialAdLoader.create(
        onAdLoaded: (ad) => _yandexInterstitial = ad,
        onAdFailedToLoad: (error) => _yandexInterstitial = null,
      );
      await loader.loadAd(
        adRequestConfiguration:
            ya.AdRequestConfiguration(adUnitId: _rc.yandexInterstitialId),
      );
    } catch (_) {
      _yandexInterstitial = null;
    }
  }

  /// Kanal/liste navigasyonunda geçiş reklamı (sayaçlı). Android'deki
  /// main/list click count mantığı.
  void onChannelOpened() {
    if (_adFree.isAdFree) return;
    _channelOpenCount++;
    if (_rc.interstitialFrequency <= 0 ||
        _channelOpenCount % _rc.interstitialFrequency != 0) {
      return;
    }
    _showInterstitial(onDone: () {});
  }

  /// Geçiş reklamını aktif ağa göre gösterir; her koşulda [onDone] çağrılır.
  void _showInterstitial({required VoidCallback onDone}) {
    final net = _rc.interstitialNetwork;

    if (net == 'admob') {
      final ad = _admobInterstitial;
      if (ad == null) {
        onDone();
        return;
      }
      _admobInterstitial = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _loadInterstitial();
          onDone();
        },
        onAdFailedToShowFullScreenContent: (a, error) {
          a.dispose();
          _loadInterstitial();
          onDone();
        },
      );
      ad.show();
    } else if (net == 'yandex') {
      final ad = _yandexInterstitial;
      if (ad == null) {
        onDone();
        return;
      }
      _yandexInterstitial = null;
      ad.setAdEventListener(
        eventListener: ya.InterstitialAdEventListener(
          onAdShown: () {},
          onAdFailedToShow: (error) {
            ad.destroy();
            _loadInterstitial();
            onDone();
          },
          onAdClicked: () {},
          onAdDismissed: () {
            ad.destroy();
            _loadInterstitial();
            onDone();
          },
          onAdImpression: (data) {},
        ),
      );
      ad.show();
    } else if (net == 'unity') {
      UnityAds.load(
        placementId: _rc.getString('unity_interstitial_id'),
        onComplete: (placementId) {
          UnityAds.showVideoAd(
            placementId: placementId,
            onComplete: (_) => onDone(),
            onFailed: (_, __, ___) => onDone(),
            onStart: (_) {},
            onClick: (_) {},
            onSkipped: (_) => onDone(),
          );
        },
        onFailed: (_, __, ___) => onDone(),
      );
    } else {
      onDone();
    }
  }

  /// TineFlix bölüm geçişi / site gezinme için genel geçiş-reklamı arası.
  void showAdBreak({required VoidCallback onDone}) {
    if (_adFree.isAdFree) {
      onDone();
      return;
    }
    _showInterstitial(onDone: onDone);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  REWARDED (ödüllü) — admob / yandex / unity
  // ══════════════════════════════════════════════════════════════════════════
  void showRewarded({required Function() onReward}) {
    if (!_rc.rewardedAdEnabled) return;
    final net = _rc.rewardedNetwork;

    if (net == 'admob') {
      RewardedAd.load(
        adUnitId: _rc.admobRewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) => a.dispose(),
              onAdFailedToShowFullScreenContent: (a, error) => a.dispose(),
            );
            ad.show(onUserEarnedReward: (_, reward) => onReward());
          },
          onAdFailedToLoad: (_) {},
        ),
      );
    } else if (net == 'yandex') {
      _showYandexRewarded(onReward: onReward);
    } else if (net == 'unity') {
      UnityAds.load(
        placementId: _rc.getString('unity_rewarded_id'),
        onComplete: (placementId) {
          UnityAds.showVideoAd(
            placementId: placementId,
            onComplete: (_) => onReward(),
            onFailed: (_, __, ___) {},
            onStart: (_) {},
            onClick: (_) {},
            onSkipped: (_) {},
          );
        },
        onFailed: (_, __, ___) {},
      );
    }
  }

  Future<void> _showYandexRewarded({required Function() onReward}) async {
    if (_rc.yandexRewardedId.isEmpty) return;
    try {
      final loader = await ya.RewardedAdLoader.create(
        onAdLoaded: (ad) {
          ad.setAdEventListener(
            eventListener: ya.RewardedAdEventListener(
              onAdShown: () {},
              onAdFailedToShow: (error) => ad.destroy(),
              onAdClicked: () {},
              onAdDismissed: () => ad.destroy(),
              onAdImpression: (data) {},
              onRewarded: (reward) => onReward(),
            ),
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {},
      );
      await loader.loadAd(
        adRequestConfiguration:
            ya.AdRequestConfiguration(adUnitId: _rc.yandexRewardedId),
      );
    } catch (_) {}
  }

  /// Ödüllü karşılığı reklamsız pencere açar (Ayarlar/"Reklamsız İzle").
  void showRewardedForAdFree(
      {required VoidCallback onGranted, required VoidCallback onFailed}) {
    if (!_rc.rewardedAdEnabled) {
      onFailed();
      return;
    }
    showRewarded(
      onReward: () {
        _adFree.grantHours(_rc.adFreeHours);
        onGranted();
      },
    );
  }
}
