import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_free_service.dart';
import '../services/remote_config_service.dart';

/// Listelere (CanlıSkor, Filmler vb.) gömülen gerçek native reklam kartı.
///
/// AdMob'un hazır "Native Template" (Small) tasarımını kullanır — bu, Android
/// tarafındaki gibi özel bir platform view/factory (Swift/Kotlin) yazmaya
/// gerek kalmadan, salt Dart tarafından güvenle çalışır.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final rc = RemoteConfigService();
    // Reklamsız mod, native reklam kapalı, AdMob dışı bir sağlayıcı veya
    // birim ID tanımlı değilse hiç yüklemeye çalışmadan gizli kal.
    if (AdFreeService().isAdFree ||
        !rc.nativeAdEnabled ||
        rc.adProvider != 'admob' ||
        rc.admobNativeId.isEmpty) {
      _failed = true;
      return;
    }

    _ad = NativeAd(
      adUnitId: rc.admobNativeId,
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
            _ad = null;
            _failed = true;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_loaded || _ad == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          SizedBox(height: 110, child: AdWidget(ad: _ad!)),
          // Google'ın kendi "Ad" rozetinin yanı sıra, reklam olduğunu daha
          // görünür/net belirtmek için Türkçe "REKLAM" etiketi ekleniyor —
          // hem şeffaflık hem mağaza politikaları açısından gerekli.
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
