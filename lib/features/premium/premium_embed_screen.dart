import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Tam ekran embed oynatıcı — Android WebViewActivity(fullscreen, stripEmbedAds)
/// karşılığı. Patron/Taraftarium (embedOnly) ve resolver/m3u8 tutmayan
/// maçların ch.html embed'i burada açılır. Referer başlığıyla yüklenir.
class PremiumEmbedScreen extends StatefulWidget {
  final String url;
  final String title;
  final String referer;
  const PremiumEmbedScreen({
    super.key,
    required this.url,
    this.title = 'Canlı Yayın',
    this.referer = '',
  });

  @override
  State<PremiumEmbedScreen> createState() => _PremiumEmbedScreenState();
}

class _PremiumEmbedScreenState extends State<PremiumEmbedScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Canlı yayın yatay izlensin.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        // Reklam popup/redirect'lerini engelle (Android embedReklamMi karşılığı).
        onNavigationRequest: (req) => _isAdNav(req.url)
            ? NavigationDecision.prevent
            : NavigationDecision.navigate,
        onPageStarted: (_) {
          setState(() => _loading = true);
          _stripEmbedAds(); // erken enjekte et → preroll DOM'a girmeden yakala
        },
        onPageFinished: (_) {
          setState(() => _loading = false);
          _stripEmbedAds();
        },
      ))
      ..loadRequest(
        Uri.parse(widget.url),
        headers: widget.referer.isNotEmpty ? {'Referer': widget.referer} : const {},
      );
  }

  /// Android embedReklamMi karşılığı — preroll reklam videosu / reklam hedefi mi?
  bool _isAdNav(String u) {
    final l = u.toLowerCase();
    return l.contains('lookatusdoweneedu') ||
        l.contains('betpuanbasket') ||
        l.contains('ortakbetpuan') ||
        (l.contains('jsdelivr') && l.endsWith('.mp4'));
  }

  // Android stripEmbedAds/temizEmbedJs tam portu (webview_flutter sınırında):
  // üst butonlar + watermark + preroll kutusunu CSS ile gizle, preroll görünürse
  // skip'e bir kez bas, prerollEnabled'ı kapat, videoyu nazikçe oynat. Kendi
  // içinde setInterval ile ~16 sn tekrarlar (tek enjeksiyon yeterli).
  void _stripEmbedAds() {
    _controller.runJavaScript(_stripJs);
  }

  static const String _stripJs = r'''
(function(){
  try{
    var css = "#top-buttons,#watermark,#preroll-container,#preroll-link,#preroll-play-btn,"
      + "#skip-button,#iptv-link,#twitter-link,#telegram-link,.ads,.reklam,.advertisement,"
      + "ins.adsbygoogle,iframe[src*='ads'],[id*='preroll'],[class*='preroll']{"
      + "display:none!important;visibility:hidden!important;pointer-events:none!important}"
      + "html,body{background:#000!important;margin:0!important;padding:0!important}"
      + "video{object-fit:contain!important;background:#000!important}";
    var s = document.getElementById("tinetv-clean");
    if(!s){ s=document.createElement("style"); s.id="tinetv-clean"; (document.head||document.documentElement).appendChild(s); }
    s.textContent = css;
    try{ if(typeof window.prerollEnabled!=="undefined") window.prerollEnabled=false; }catch(e){}
    var n=0;
    var iv=setInterval(function(){
      n++;
      try{
        var pc=document.getElementById("preroll-container");
        var sb=document.getElementById("skip-button");
        var on=pc&&getComputedStyle(pc).display!=="none"&&pc.offsetParent!==null;
        if(on&&sb){ sb.disabled=false; try{ sb.dispatchEvent(new MouseEvent("mousedown",{bubbles:true})); }catch(e){} }
        var v=document.querySelector("video");
        if(v&&v.paused){ var p=v.play(); if(p&&p.catch) p.catch(function(){}); }
      }catch(e){}
      if(n>40) clearInterval(iv);
    },400);
  }catch(e){}
})();
''';

  // Uygulama arkaya atılınca yayını DURDUR (arka planda çalmasın, PiP açılmasın).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stopMedia();
  }

  // WebView içindeki tüm video/audio'yu durdur + sustur. ASIL yayın çoğu zaman
  // cross-origin bir IFRAME içinde; JS o iframe'in İÇİNE giremez, AMA kendi
  // document'imizden iframe ELEMENTİNİ kaldırmak serbesttir → iframe (ve içindeki
  // video/ses) yok olur. Boss/Patron/Taraftarium sesinin çıkışta devam etmesi
  // bu yüzdendi; iframe'leri de kaldırınca kesin susar.
  void _stopMedia() {
    try {
      _controller.runJavaScript(
          "try{"
          "document.querySelectorAll('video,audio').forEach(function(m){try{m.pause();m.muted=true;m.removeAttribute('src');m.src='';if(m.load)m.load();}catch(e){}});"
          "document.querySelectorAll('iframe').forEach(function(f){try{f.src='about:blank';if(f.parentNode)f.parentNode.removeChild(f);}catch(e){}});"
          "}catch(e){}");
    } catch (_) {}
  }

  // Ekrandan çıkış: webview HÂLÂ CANLIYKEN medyayı durdur, kısa bekle, sonra kapat.
  // (dispose anında çalıştırmak iOS'ta çok geç kalıyordu.)
  Future<void> _leave() async {
    _stopMedia();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Ekrandan çıkınca yayın kesin dursun: medyayı durdur + boş sayfa yükle.
    _stopMedia();
    try {
      _controller.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
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
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _leave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
