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
        onPageStarted: (_) => setState(() => _loading = true),
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

  // ch.html preroll reklamı + üst butonlar + watermark temizliği (Android
  // stripEmbedAds karşılığı, hafif sürüm): görünür overlay/pop-up'ları gizle.
  void _stripEmbedAds() {
    _controller.runJavaScript('''
      (function(){
        try{
          document.querySelectorAll('a[target="_blank"],.ads,.reklam,.watermark,#ads,#reklam').forEach(function(e){e.remove();});
          document.querySelectorAll('video').forEach(function(v){v.muted=false;v.play&&v.play();});
        }catch(e){}
      })();
    ''');
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
