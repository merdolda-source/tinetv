import 'dart:io' show Platform;
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
    // AdMob'da reklam birimleri (ad unit) belirli bir "app"e bağlıdır — Android
    // ve iOS AdMob konsolunda AYRI app olarak kayıtlı (GADApplicationIdentifier
    // iOS'ta ~9827212102). Bu yüzden iOS için AYRI reklam birimi ID'lerine
    // ihtiyaç var; RC'den "_ios" anahtarı henüz tanımlı değilse (fetch
    // gelmeden önce veya konsola hiç eklenmezse) buradaki yerel varsayılan
    // devreye girer — Firebase konsolundaki güncel değerlerle senkron tutuldu.
    'admob_app_open_id_ios':     'ca-app-pub-2289573527937577/7387612952',
    'admob_interstitial_id_ios': 'ca-app-pub-2289573527937577/7220091995',
    'admob_native_id_ios':       'ca-app-pub-2289573527937577/9654683647',
    'admob_rewarded_id_ios':     'ca-app-pub-2289573527937577/8197262202',
    'unity_game_id': '',
    'unity_interstitial_id': 'Interstitial_iOS',
    'unity_rewarded_id': 'Rewarded_iOS',
    // ── Android tarzı çoklu-ağ (true/false) ─────────────────────────────────
    // Öncelik: admob > yandex > unity (ilk açık olan "aktif ağ").
    // Aktif ağ Unity ise: geçiş/ödüllü Unity'den; ama NATIVE ve AÇILIŞ (app
    // open) OTOMATİK Yandex'ten gelir (ad_service resolver'ları hallediyor) —
    // Unity ile çakışmadan. Android sistemiyle birebir aynı mantık.
    'show_admob_ads': false,
    'show_yandex_ads': false,
    'show_unity_ads': true,
    // Yandex iOS reklam birimleri (Boost app 19601807).
    'yandex_interstitial_id': 'R-M-19601807-4',
    'yandex_app_open_id':     'R-M-19601807-3',
    'yandex_native_id':       'R-M-19601807-2', // Flutter'da native yok → adaptive inline banner
    'yandex_rewarded_id':     'R-M-19601807-1',
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
    // Fikstür adresi — boşsa puanlig.php ile aynı dizinde fikstur.php varsayılır.
    'puanlig_fikstur_url': '',
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

  // ── Android tarzı çoklu-ağ ağ seçimi ──────────────────────────────────────
  bool get showAdmobAds  => _rc.getBool('show_admob_ads');
  bool get showYandexAds => _rc.getBool('show_yandex_ads');
  bool get showUnityAds  => _rc.getBool('show_unity_ads');

  String get yandexInterstitialId => _rc.getString('yandex_interstitial_id');
  String get yandexAppOpenId      => _rc.getString('yandex_app_open_id');
  String get yandexNativeId       => _rc.getString('yandex_native_id');
  String get yandexRewardedId     => _rc.getString('yandex_rewarded_id');

  /// Aktif ağ — ilk AÇIK olan (öncelik: admob > yandex > unity), yoksa 'none'.
  String get activeNetwork {
    if (showAdmobAds) return 'admob';
    if (showYandexAds) return 'yandex';
    if (showUnityAds) return 'unity';
    return 'none';
  }

  /// Geçiş reklamı ağı = aktif ağ (admob / yandex / unity).
  String get interstitialNetwork => activeNetwork;

  /// Ödüllü reklam ağı = aktif ağ (iOS'ta Unity ödüllü çalışır).
  String get rewardedNetwork => activeNetwork;

  /// NATIVE ağı — Android'deki gibi: admob aktifse admob, aksi halde (unity/
  /// none) OTOMATİK Yandex. Böylece Unity açıkken native Yandex'ten gelir.
  String get nativeNetwork => activeNetwork == 'admob' ? 'admob' : 'yandex';

  /// AÇILIŞ (app open) ağı — native ile aynı kural: admob→admob, aksi→yandex.
  String get appOpenNetwork => activeNetwork == 'admob' ? 'admob' : 'yandex';
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
  // iOS'ta _ios anahtarı okunur; Android'de (ve diğer platformlarda) eski
  // paylaşılan anahtar okunur — Android tarafı değişmedi.
  String get admobAppOpenId =>
      _rc.getString(Platform.isIOS ? 'admob_app_open_id_ios' : 'admob_app_open_id');
  String get admobInterstitialId =>
      _rc.getString(Platform.isIOS ? 'admob_interstitial_id_ios' : 'admob_interstitial_id');
  String get admobNativeId =>
      _rc.getString(Platform.isIOS ? 'admob_native_id_ios' : 'admob_native_id');
  String get admobRewardedId =>
      _rc.getString(Platform.isIOS ? 'admob_rewarded_id_ios' : 'admob_rewarded_id');
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

  /// Fikstür adresi — RC'de 'puanlig_fikstur_url' tanımlıysa onu, değilse
  /// puanlig.php ile AYNI dizindeki fikstur.php'yi kullanır (Android mantığı).
  String get puanligFiksturUrl {
    final override = _rc.getString('puanlig_fikstur_url');
    if (override.isNotEmpty) return override;
    final base = puanligApiUrl;
    if (base.isEmpty) return '';
    return Uri.parse(base).resolve('fikstur.php').toString();
  }

  bool get canliskorEnabled => _rc.getBool('canliskor_enabled');
  String get canliskorApiUrl => _rc.getString('canliskor_api_url');
  int get canliSkorRefreshMs => _rc.getInt('canli_skor_refresh_ms');

  bool get haberlerEnabled => _rc.getBool('haberler_enabled');
  String get haberApiUrl => _rc.getString('haber_api_url');

  int get gridNativeAdInterval => _rc.getInt('grid_native_ad_interval');

  String getString(String key) => _rc.getString(key);
}
