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

class _PremiumEmbedScreenState extends State<PremiumEmbedScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
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
