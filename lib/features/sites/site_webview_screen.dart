import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/models/site_model.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/remote_config_service.dart';

/// Dizipal tarzı harici siteleri uygulama içinde açar. Android tarafındaki
/// WebViewActivity ile aynı mantık: sayfa içi gezinme belirli sayıda
/// tıklamada bir geçiş reklamıyla "kapılanır" (gate edilir).
class SiteWebviewScreen extends StatefulWidget {
  final SiteEntry site;
  const SiteWebviewScreen({super.key, required this.site});

  @override
  State<SiteWebviewScreen> createState() => _SiteWebviewScreenState();
}

class _SiteWebviewScreenState extends State<SiteWebviewScreen> {
  late final WebViewController _webController;
  bool _isLoading = true;
  int _navCount = 0;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: _onNavigationRequest,
      ))
      ..loadRequest(Uri.parse(widget.site.url));
  }

  Future<NavigationDecision> _onNavigationRequest(NavigationRequest request) async {
    _navCount++;
    final threshold = RemoteConfigService().siteNavAdClickCount;
    if (threshold > 0 && _navCount % threshold == 0) {
      final completer = Completer<void>();
      AdService().showAdBreak(onDone: () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    }
    return NavigationDecision.navigate;
  }

  // Medyayı durdur + iframe'leri DOM'dan kaldır (cross-origin ses çıkışta sürmesin).
  void _stopMedia() {
    try {
      _webController.runJavaScript(
          "try{"
          "document.querySelectorAll('video,audio').forEach(function(m){try{m.pause();m.muted=true;m.removeAttribute('src');m.src='';if(m.load)m.load();}catch(e){}});"
          "document.querySelectorAll('iframe').forEach(function(f){try{f.src='about:blank';if(f.parentNode)f.parentNode.removeChild(f);}catch(e){}});"
          "}catch(e){}");
    } catch (_) {}
  }

  // Çıkışta: webview canlıyken durdur, kısa bekle, sonra kapat.
  Future<void> _leave() async {
    _stopMedia();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _stopMedia();
    try {
      _webController.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          widget.site.title.isNotEmpty ? widget.site.title : 'Site',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        // Varsayılan geri butonu yerine: önce medyayı durdur, sonra kapat.
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _leave,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webController),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
        ],
      ),
    );
  }
}
