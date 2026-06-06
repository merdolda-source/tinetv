import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'remote_config_service.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  final _rc = RemoteConfigService();
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  int _channelOpenCount = 0;

  Future<void> initialize() async {
    final provider = _rc.adProvider;

    if (provider == 'admob') {
      await MobileAds.instance.initialize();
      _loadInterstitial();
      _loadAppOpen();
    } else if (provider == 'unity') {
      await UnityAds.init(
        gameId: _rc.unityGameId,
        onComplete: () {},
        onFailed: (error, message) {},
      );
    }
  }

  void _loadAppOpen() {
    if (!_rc.appOpenAdEnabled) return;
    AppOpenAd.load(
      adUnitId: _rc.admobAppOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (error) => _appOpenAd = null,
      ),
    );
  }

  void showAppOpen() {
    if (_rc.adProvider == 'admob' && _appOpenAd != null) {
      _appOpenAd!.show();
      _appOpenAd = null;
      _loadAppOpen();
    }
  }

  void _loadInterstitial() {
    if (!_rc.interstitialEnabled) return;
    InterstitialAd.load(
      adUnitId: _rc.admobInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void onChannelOpened() {
    _channelOpenCount++;
    if (_channelOpenCount % _rc.interstitialFrequency != 0) return;

    if (_rc.adProvider == 'admob' && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitial();
    } else if (_rc.adProvider == 'unity') {
      UnityAds.load(
        placementId: _rc.getString('unity_interstitial_id'),
        onComplete: (placementId) {
          UnityAds.showVideoAd(
            placementId: placementId,
            onComplete: (_) {},
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

  void showRewarded({required Function() onReward}) {
    if (!_rc.rewardedAdEnabled) return;

    if (_rc.adProvider == 'admob') {
      RewardedAd.load(
        adUnitId: _rc.admobRewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.show(onUserEarnedReward: (_, reward) => onReward());
          },
          onAdFailedToLoad: (_) {},
        ),
      );
    } else if (_rc.adProvider == 'unity') {
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
}
