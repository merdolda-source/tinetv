import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/models/premium_model.dart';
import '../../core/services/premium_resolver.dart';
import '../../core/services/remote_config_service.dart';
import 'premium_embed_screen.dart';

/// Premium spor oynatıcı — Android PlayerActivity resolver+embed akışının portu.
///
/// Karar zinciri (openPlayer):
///   1) directEmbedUrl varsa      → resolver ATLA, doğrudan embed (webview)
///   2) media_url resolver ise    → çöz → native m3u8; olmazsa embedUrl'e düş
///   3) media_url doğrudan m3u8'se → native oynat; olmazsa embedUrl'e düş
class PremiumPlayerScreen extends StatefulWidget {
  final PremiumItem item;
  const PremiumPlayerScreen({super.key, required this.item});

  @override
  State<PremiumPlayerScreen> createState() => _PremiumPlayerScreenState();
}

class _PremiumPlayerScreenState extends State<PremiumPlayerScreen> {
  BetterPlayerController? _controller;
  bool _preparing = true;
  bool _embedTried = false;
  String _status = 'Yayın hazırlanıyor…';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _start();
  }

  Future<void> _start() async {
    final item = widget.item;

    // 1) embedOnly (Patron/Taraftarium) → doğrudan webview.
    if (item.directEmbedUrl.isNotEmpty) {
      _openEmbed(item.directEmbedUrl);
      return;
    }

    // 2/3) media_url'i çöz (resolver) ya da doğrudan al.
    PlayResource? res;
    if (PremiumResolver.isResolverUrl(item.mediaUrl)) {
      res = await PremiumResolver.resolve(item);
    } else if (item.mediaUrl.isNotEmpty) {
      res = PremiumResolver.direct(item);
    }

    if (!mounted) return;

    if (res == null || res.url.isEmpty) {
      // Çözülemedi → embed yedeği (RC 'patron_embed' açıksa ve embedUrl varsa).
      if (item.embedUrl.isNotEmpty &&
          RemoteConfigService().patronEmbedFallback) {
        _openEmbed(item.embedUrl);
      } else {
        setState(() {
          _preparing = false;
          _status = 'Yayın bulunamadı.';
        });
      }
      return;
    }

    _setupPlayer(res);
  }

  void _setupPlayer(PlayResource res) {
    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.contain,
        aspectRatio: 16 / 9,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        handleLifecycle: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableFullscreen: false,
          enableSkips: false,
          enableOverflowMenu: true,
          enableQualities: true,
          enableSubtitles: false,
          enableAudioTracks: true,
          enablePlaybackSpeed: false,
          overflowMenuIconsColor: Colors.white,
          progressBarPlayedColor: Color(0xFFE50914),
          progressBarHandleColor: Color(0xFFE50914),
          controlBarColor: Colors.black54,
          iconsColor: Colors.white,
        ),
      ),
    );

    // Native/resolver oynatamazsa (kaynak hatası) embed yedeğine düş.
    controller.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        _fallbackToEmbed();
      }
    });

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      res.url,
      liveStream: true,
      videoFormat: BetterPlayerVideoFormat.hls,
      headers: res.headers,
      useAsmsSubtitles: false,
      useAsmsTracks: true,
    );
    controller.setupDataSource(dataSource);

    setState(() {
      _controller = controller;
      _preparing = false;
    });
  }

  // Kaynak hatasında Patron ch.html / Boss watch embed'ine bir kez düş.
  void _fallbackToEmbed() {
    if (_embedTried) return;
    if (widget.item.embedUrl.isEmpty) return;
    if (!RemoteConfigService().patronEmbedFallback) return;
    _embedTried = true;
    _openEmbed(widget.item.embedUrl);
  }

  void _openEmbed(String url) {
    // Oynatıcı ekranını embed ekranıyla değiştir (geri tuşu listeye dönsün).
    Get.off(() => PremiumEmbedScreen(
          url: url,
          title: widget.item.title,
          referer: widget.item.referer,
        ));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (c != null)
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: BetterPlayer(controller: c),
                ),
              )
            else
              Center(
                child: _preparing
                    ? const CircularProgressIndicator(color: Color(0xFFE50914))
                    : Text(_status, style: const TextStyle(color: Colors.grey)),
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
