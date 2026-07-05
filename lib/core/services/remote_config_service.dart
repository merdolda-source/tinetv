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
    'ad_rewarded_frequency': 5,
    'admob_app_open_id': '',
    'admob_interstitial_id': '',
    'admob_native_id': '',
    'admob_rewarded_id': '',
    'unity_game_id': '',
    'unity_interstitial_id': 'Interstitial_iOS',
    'unity_rewarded_id': 'Rewarded_iOS',
    'categories_enabled': true,
    'categories_json': '[]',
    'ad_interstitial_wait_seconds': 5,
    'ad_rewarded_wait_seconds': 3,
    'ad_free_hours': 24,
    // TineFlix — kapalıyken sekme hiç gösterilmez, m3u ekranı değişmeden kalır.
    'tineflix_enabled': false,
    'tineflix_api_url': '', // m3u_url ile aynı mantık — backend adresi değişirse/kapanırsa
                            // uygulama güncellemesi gerekmeden sadece Firebase'ten değiştirilsin.
    'tineflix_ep_ad_interval': 10,
    // Siteler — kapalıyken sekme hiç gösterilmez.
    'sites_enabled': false,
    'sites_json': '[]',
    'site_nav_ad_click_count': 3,
    // Film — kapalıyken sekme hiç gösterilmez.
    'film_enabled': false,
    'film_api_url': '',
    // Puan Durumu — kapalıyken sekme hiç gösterilmez.
    'puanlig_enabled': false,
    'puanlig_api_url': '',
    // CanlıSkor — kapalıyken sekme hiç gösterilmez.
    'canliskor_enabled': false,
    'canliskor_api_url': '',
    'canli_skor_refresh_ms': 1000,
    // Haberler — kapalıyken sekme hiç gösterilmez.
    'haberler_enabled': false,
    'haber_api_url': '',
    // Listelere kaç öğede bir native reklam gömülsün (Android ile aynı anahtar).
    'grid_native_ad_interval': 10,
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

  // Anlık güncelleme için
  Future<void> refresh() async {
    await _rc.fetchAndActivate();
  }

  String get m3uUrl => _rc.getString('m3u_url');
  String get adProvider => _rc.getString('ad_provider');
  bool get appOpenAdEnabled => _rc.getBool('ad_app_open_enabled');
  bool get interstitialEnabled => _rc.getBool('ad_interstitial_enabled');
  int get interstitialFrequency => _rc.getInt('ad_interstitial_frequency');
  int get interstitialWaitSeconds => _rc.getInt('ad_interstitial_wait_seconds');
  bool get nativeAdEnabled => _rc.getBool('ad_native_enabled');
  bool get rewardedAdEnabled => _rc.getBool('ad_rewarded_enabled');
  int get rewardedFrequency => _rc.getInt('ad_rewarded_frequency');
  int get rewardedWaitSeconds => _rc.getInt('ad_rewarded_wait_seconds');
  bool get categoriesEnabled => _rc.getBool('categories_enabled');
  String get categoriesJson => _rc.getString('categories_json');
  String get admobAppOpenId => _rc.getString('admob_app_open_id');
  String get admobInterstitialId => _rc.getString('admob_interstitial_id');
  String get admobNativeId => _rc.getString('admob_native_id');
  String get admobRewardedId => _rc.getString('admob_rewarded_id');
  String get unityGameId => _rc.getString('unity_game_id');
  int get adFreeHours => _rc.getInt('ad_free_hours');

  bool get tineflixEnabled => _rc.getBool('tineflix_enabled');
  String get tineflixApiUrl => _rc.getString('tineflix_api_url');
  int get tineflixEpAdInterval => _rc.getInt('tineflix_ep_ad_interval');

  bool get sitesEnabled => _rc.getBool('sites_enabled');
  String get sitesJson => _rc.getString('sites_json');
  int get siteNavAdClickCount => _rc.getInt('site_nav_ad_click_count');

  bool get filmEnabled => _rc.getBool('film_enabled');
  String get filmApiUrl => _rc.getString('film_api_url');

  bool get puanligEnabled => _rc.getBool('puanlig_enabled');
  String get puanligApiUrl => _rc.getString('puanlig_api_url');

  bool get canliskorEnabled => _rc.getBool('canliskor_enabled');
  String get canliskorApiUrl => _rc.getString('canliskor_api_url');
  int get canliSkorRefreshMs => _rc.getInt('canli_skor_refresh_ms');

  bool get haberlerEnabled => _rc.getBool('haberler_enabled');
  String get haberApiUrl => _rc.getString('haber_api_url');

  int get gridNativeAdInterval => _rc.getInt('grid_native_ad_interval');

  String getString(String key) => _rc.getString(key);
}
