import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Cloudflare "managed challenge" arkasındaki HLS yayınları için oynatıcı.
///
/// Android [CloudflareCookieHelper] mantığının iOS/Flutter karşılığı. Flutter'da
/// webview_flutter, HttpOnly `cf_clearance` çerezini OKUYAMADIĞI için (Android
/// CookieManager.getCookie karşılığı yok), çerezi dışarı çıkarıp better_player'a
/// vermek yerine — challenge'ı çözen AYNI WebView içinde oynatırız. Böylece
/// cf_clearance çerezi (WKWebView çerez deposunda) yayın isteklerine otomatik
/// eklenir; ekstra paket / native kod / pubspec değişikliği GEREKMEZ.
///
/// Akış:
///   1) Kaynağın kök sayfası (host) WebView'de, oynatıcıyla AYNI User-Agent ile
///      açılır → Cloudflare challenge tarayıcıda çözülür (cf_clearance oluşur).
///   2) Aynı origin'de bir <video src="m3u8"> sayfası yüklenir → WKWebView HLS'i
///      natively oynatır, istekler cf_clearance ile gider.
///   İnteraktif CAPTCHA çıkarsa WebView görünür olduğundan kullanıcı 1 kez dokunur.
class CloudflarePlayerScreen extends StatefulWidget {
  final String url; // m3u8 / yayın adresi
  final String title;
  final String referer; // opsiyonel — host bundan türetilir
  final String userAgent; // cf_clearance UA'ya bağlı → WebView UA'sı ile aynı olmalı

  const CloudflarePlayerScreen({
    super.key,
    required this.url,
    this.title = 'Canlı Yayın',
    this.referer = '',
    this.userAgent = '',
  });

  @override
  State<CloudflarePlayerScreen> createState() => _CloudflarePlayerScreenState();
}

class _CloudflarePlayerScreenState extends State<CloudflarePlayerScreen> {
  static const String _defaultUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  late final WebViewController _controller;
  bool _dogrulaniyor = true; // üst banner: challenge aşaması
  bool _videoYuklendi = false;

  String get _host {
    final kaynak = widget.referer.trim().isNotEmpty ? widget.referer.trim() : widget.url;
    try {
      final u = Uri.parse(kaynak);
      if (u.scheme.isEmpty || u.host.isEmpty) return kaynak;
      return '${u.scheme}://${u.host}/';
    } catch (_) {
      return kaynak;
    }
  }

  String _videoHtml() {
    // src'yi güvenle göm (çift tırnak kaçışı yeterli — m3u8 URL'lerinde tırnak olmaz).
    final src = widget.url.replaceAll('"', '%22');
    return '<!doctype html><html><head>'
        '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">'
        '<style>html,body{margin:0;padding:0;background:#000;height:100%;overflow:hidden}'
        'video{width:100vw;height:100vh;object-fit:contain;background:#000}</style></head>'
        '<body><video src="$src" autoplay playsinline controls '
        'webkit-playsinline></video></body></html>';
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final ua = widget.userAgent.trim().isNotEmpty ? widget.userAgent.trim() : _defaultUa;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(ua)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (!_videoYuklendi) {
            // Kök sayfa yüklendi → Cloudflare JS'inin çözmesi için kısa bekleme,
            // sonra aynı origin'de video sayfasını yükle.
            _videoYuklendi = true;
            Future.delayed(const Duration(milliseconds: 1600), () {
              if (!mounted) return;
              _controller.loadHtmlString(_videoHtml(), baseUrl: _host);
              setState(() => _dogrulaniyor = false);
            });
          }
        },
      ))
      ..loadRequest(
        Uri.parse(_host),
        headers: widget.referer.trim().isNotEmpty
            ? {'Referer': widget.referer.trim()}
            : const {},
      );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_dogrulaniyor)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: const Color(0xCC101010),
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Güvenlik doğrulaması yapılıyor… (gerekirse ekrana dokunun)',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
