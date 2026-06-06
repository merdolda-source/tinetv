import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._();

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  static const _defaults = {
    'm3u_url': '',
    'ad_provider': 'admob',
    'ad_app_open_enabled': true,
    'ad_interstitial_enabled': true,
    'ad_interstitial_frequency': 3,
    'ad_native_enabled': true,
    'ad_rewarded_enabled': true,
    'admob_app_open_id': '',
    'admob_interstitial_id': '',
    'admob_native_id': '',
    'admob_rewarded_id': '',
    'unity_game_id': '',
    'unity_interstitial_id': 'Interstitial_iOS',
    'unity_rewarded_id': 'Rewarded_iOS',
    'categories_enabled': true,
    'categories_json': '[]',
  };

  Future<void> initialize() async {
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero,
      ),
    );
    await _rc.setDefaults(_defaults);
    await _rc.fetchAndActivate();
  }

  String get m3uUrl => _rc.getString('m3u_url');
  String get adProvider => _rc.getString('ad_provider');
  bool get appOpenAdEnabled => _rc.getBool('ad_app_open_enabled');
  bool get interstitialEnabled => _rc.getBool('ad_interstitial_enabled');
  int get interstitialFrequency => _rc.getInt('ad_interstitial_frequency');
  bool get nativeAdEnabled => _rc.getBool('ad_native_enabled');
  bool get rewardedAdEnabled => _rc.getBool('ad_rewarded_enabled');
  bool get categoriesEnabled => _rc.getBool('categories_enabled');
  String get categoriesJson => _rc.getString('categories_json');
  String get admobAppOpenId => _rc.getString('admob_app_open_id');
  String get admobInterstitialId => _rc.getString('admob_interstitial_id');
  String get admobNativeId => _rc.getString('admob_native_id');
  String get admobRewardedId => _rc.getString('admob_rewarded_id');
  String get unityGameId => _rc.getString('unity_game_id');
  String getString(String key) => _rc.getString(key);
}
