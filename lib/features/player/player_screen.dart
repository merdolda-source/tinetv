import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/models/channel_model.dart';
import '../../core/services/remote_config_service.dart';
import 'cloudflare_player_screen.dart';

/// Ana kanal oynatıcı — Android PlayerActivity paritesi (tek cihaz oynatma):
///   • Referer / Origin / User-Agent başlıkları (#EXTVLCOPT'ten)  → 403'leri aşar
///   • HLS (.m3u8) / DASH (.mpd) biçim tespiti, canlı yayın modu
///   • Kaynak hatasında otomatik yeniden deneme (retry)
///   • Kalite / hız / altyazı / ses parçası menüsü + tam ekran
class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const String _defaultUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
  static const int _maxRetry = 3;

  late BetterPlayerController _controller;
  int _retry = 0;
  bool _hata = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.contain,
        aspectRatio: 16 / 9,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        handleLifecycle: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableSkips: false,
          enableFullscreen: true,
          enableOverflowMenu: true,
          enableQualities: true,
          enablePlaybackSpeed: true,
          enableSubtitles: true,
          enableAudioTracks: true,
          overflowMenuIconsColor: Colors.white,
          controlBarColor: Colors.black54,
          iconsColor: Colors.white,
          progressBarPlayedColor: Color(0xFFE50914),
          progressBarHandleColor: Color(0xFFE50914),
        ),
      ),
    );

    _controller.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        _onError();
      }
    });

    _controller.setupDataSource(_dataSource());
  }

  BetterPlayerDataSource _dataSource() {
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.channel.url,
      liveStream: true,
      videoFormat: _format(widget.channel.url),
      headers: _headers(),
      useAsmsSubtitles: true,
      useAsmsTracks: true,
    );
  }

  // Android: userAgent yoksa CF_DEFAULT_UA; referer/origin doluysa eklenir.
  Map<String, String> _headers() {
    final h = <String, String>{};
    final ua = (widget.channel.userAgent ?? '').trim();
    h['User-Agent'] = ua.isNotEmpty ? ua : _defaultUa;
    final ref = (widget.channel.referer ?? '').trim();
    if (ref.isNotEmpty) h['Referer'] = ref;
    final org = (widget.channel.origin ?? '').trim();
    if (org.isNotEmpty) h['Origin'] = org;
    return h;
  }

  BetterPlayerVideoFormat? _format(String url) {
    final l = url.toLowerCase();
    if (l.contains('.m3u8') || l.contains('/hls/') || l.contains('playlist.m3u')) {
      return BetterPlayerVideoFormat.hls;
    }
    if (l.contains('.mpd')) return BetterPlayerVideoFormat.dash;
    return null; // .ts / .mp4 vb. → better_player otomatik algılar
  }

  // Kaynak hatası: birkaç kez sessizce yeniden dene, sonra hata göster.
  Future<void> _onError() async {
    if (_retry >= _maxRetry) {
      if (mounted) setState(() => _hata = true);
      return;
    }
    _retry++;
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _controller.setupDataSource(_dataSource());
  }

  void _tekrarDene() {
    setState(() {
      _hata = false;
      _retry = 0;
    });
    _controller.setupDataSource(_dataSource());
  }

  // Yayın açılmıyorsa (çoğu zaman Cloudflare "managed challenge" / 403), doğrulamayı
  // WebView'de çözüp aynı WebView içinde oynatan CF oynatıcısına geç. Android
  // CloudflareCookieHelper mantığının karşılığı. Get.off → başarısız player'ı değiştirir.
  void _cloudflareAc() {
    final ua = (widget.channel.userAgent ?? '').trim();
    Get.off(() => CloudflarePlayerScreen(
          url: widget.channel.url,
          title: widget.channel.name,
          referer: widget.channel.referer ?? '',
          userAgent: ua.isNotEmpty ? ua : _defaultUa,
        ));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.channel.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(children: [
        Center(
        child: _hata
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  const Text('Yayın açılamadı.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _tekrarDene,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914)),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Tekrar Dene',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _cloudflareAc,
                    icon: const Icon(Icons.verified_user,
                        color: Color(0xFFE50914), size: 18),
                    label: const Text('Cloudflare Doğrulaması ile Aç',
                        style: TextStyle(color: Color(0xFFE50914))),
                  ),
                ],
              )
            : AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _controller),
              ),
      ),
        // Oynatıcı mesajı (Android show_player_message paritesi).
        if (RemoteConfigService().showPlayerMessage &&
            RemoteConfigService().playerMessage.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                RemoteConfigService().playerMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
      ]),
    );
  }
}
