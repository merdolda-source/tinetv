import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/series_model.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/dramaflix_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/remote_config_service.dart';

class TineflixPlayerScreen extends StatefulWidget {
  final SeriesDetail detail;
  final int startIndex;
  const TineflixPlayerScreen({super.key, required this.detail, required this.startIndex});

  @override
  State<TineflixPlayerScreen> createState() => _TineflixPlayerScreenState();
}

class _TineflixPlayerScreenState extends State<TineflixPlayerScreen> {
  final _service = DramaflixService();
  late BetterPlayerController _controller;
  late int _currentIndex;
  int _episodeWatchCount = 0;
  bool _switchingEpisode = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _controller = BetterPlayerController(const BetterPlayerConfiguration(
      autoPlay: true,
      // TineFlix bölümleri dikey (kısa dizi) formatında.
      aspectRatio: 9 / 16,
      fullScreenByDefault: false,
      allowedScreenSleep: false,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enableSkips: false,
        enableFullscreen: false,
        enableOverflowMenu: false,
        controlBarColor: Colors.black54,
        iconsColor: Colors.white,
        progressBarPlayedColor: Color(0xFFE50914),
        progressBarHandleColor: Color(0xFFE50914),
      ),
    ));
    _loadEpisode(_currentIndex);
  }

  void _loadEpisode(int index) {
    final ep = widget.detail.episodes[index];
    final sub = ep.preferredSubtitle;

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      _service.proxiedStreamUrl(ep.url),
      liveStream: false,
      // Oynatıcı, video/altyazı akışını kendi ağ isteğiyle çekiyor — bu
      // istek DramaflixService'in Dio istemcisinden geçmiyor, o yüzden
      // User-Agent'ı burada ayrıca vermek zorundayız (bkz. DramaflixService.userAgent).
      headers: const {'User-Agent': DramaflixService.userAgent},
      subtitles: sub != null
          ? [
              BetterPlayerSubtitlesSource(
                type: BetterPlayerSubtitlesSourceType.network,
                urls: [_service.proxiedSubtitleUrl(sub.url)],
                headers: const {'User-Agent': DramaflixService.userAgent},
                selectedByDefault: true,
              ),
            ]
          : null,
    );
    _controller.setupDataSource(dataSource);
    ProgressService.saveProgress(widget.detail.series.slug, index);
  }

  void _goToEpisode(int index) {
    if (_switchingEpisode) return;
    if (index < 0 || index >= widget.detail.episodes.length) return;

    _episodeWatchCount++;
    final interval = RemoteConfigService().tineflixEpAdInterval;
    final shouldBreak = interval > 0 && _episodeWatchCount >= interval;

    if (!shouldBreak) {
      setState(() => _currentIndex = index);
      _loadEpisode(index);
      return;
    }

    _episodeWatchCount = 0;
    setState(() => _switchingEpisode = true);
    AdService().showAdBreak(onDone: () {
      if (!mounted) return;
      setState(() {
        _currentIndex = index;
        _switchingEpisode = false;
      });
      _loadEpisode(index);
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ep = widget.detail.episodes[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: BetterPlayer(controller: _controller),
              ),
            ),
            if (_switchingEpisode)
              const Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('TİNEFLİX',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                      '${widget.detail.series.title} — Bölüm ${ep.episodeNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 24,
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                    onPressed: () => _goToEpisode(_currentIndex - 1),
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
                    onPressed: () => _goToEpisode(_currentIndex + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
