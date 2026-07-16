import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yandex_mobileads/mobile_ads.dart' as ya;
import '../services/ad_free_service.dart';
import '../services/remote_config_service.dart';

/// Listelere (CanlıSkor, Filmler vb.) gömülen native reklam kartı.
///
/// Ağ seçimi Android'deki gibi resolver'a bağlı (RemoteConfigService.nativeNetwork):
///   • admob  → AdMob "Native Template" (Small)
///   • yandex → Yandex "adaptive inline banner" (Flutter'da native format YOK;
///              bu format video/medya destekli ve yüksek CPM — native yerine geçer)
///
/// Reklamsız mod / native kapalı / uygun birim yoksa gizli kalır.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  final _rc = RemoteConfigService();

  // AdMob
  NativeAd? _admobAd;
  // Yandex (adaptive inline banner)
  ya.BannerAd? _yandexBanner;

  String _net = 'none';
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (AdFreeService().isAdFree || !_rc.nativeAdEnabled) {
      _failed = true;
      return;
    }
    _net = _rc.nativeNetwork; // admob | yandex
    // Boyut için ilk frame'de MediaQuery gerekiyor.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (!mounted) return;
    if (_net == 'admob') {
      _loadAdmob();
    } else if (_net == 'yandex') {
      _loadYandex();
    } else {
      setState(() => _failed = true);
    }
  }

  void _loadAdmob() {
    if (_rc.admobNativeId.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    _admobAd = NativeAd(
      adUnitId: _rc.admobNativeId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: const Color(0xFF1A1A1A),
        cornerRadius: 10,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFFE50914),
        ),
        primaryTextStyle: NativeTemplateTextStyle(textColor: Colors.white),
        secondaryTextStyle: NativeTemplateTextStyle(textColor: Colors.grey),
        tertiaryTextStyle: NativeTemplateTextStyle(textColor: Colors.grey),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _admobAd = null;
            _failed = true;
          });
        },
      ),
    )..load();
  }

  void _loadYandex() {
    if (_rc.yandexNativeId.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    final screenWidth = MediaQuery.of(context).size.width.round();
    final banner = ya.BannerAd(
      adSize: ya.BannerAdSize.inline(width: screenWidth, maxHeight: 320),
    );
    banner.loadStateStream.listen((state) {
      if (!mounted) return;
      if (state is ya.BannerAdLoadStateLoaded) {
        setState(() => _loaded = true);
      } else if (state is ya.BannerAdLoadStateError) {
        setState(() {
          _yandexBanner = null;
          _failed = true;
        });
      }
    });
    banner.load(ya.AdRequest(adUnitId: _rc.yandexNativeId));
    _yandexBanner = banner;
  }

  @override
  void dispose() {
    _admobAd?.dispose();
    _yandexBanner?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_loaded) return const SizedBox.shrink();

    Widget? adWidget;
    if (_net == 'admob' && _admobAd != null) {
      adWidget = SizedBox(height: 110, child: AdWidget(ad: _admobAd!));
    } else if (_net == 'yandex' && _yandexBanner != null) {
      adWidget = ya.AdWidget(bannerAd: _yandexBanner!);
    }
    if (adWidget == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          adWidget,
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'REKLAM',
                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
