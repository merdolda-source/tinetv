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
