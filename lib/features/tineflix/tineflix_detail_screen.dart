import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/series_model.dart';
import '../../core/services/dramaflix_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/widgets/native_ad_card.dart';
import 'tineflix_player_screen.dart';

class TineflixDetailScreen extends StatefulWidget {
  final String slug;
  const TineflixDetailScreen({super.key, required this.slug});

  @override
  State<TineflixDetailScreen> createState() => _TineflixDetailScreenState();
}

class _TineflixDetailScreenState extends State<TineflixDetailScreen> {
  final _service = DramaflixService();
  SeriesDetail? _detail;
  bool _isLoading = true;
  int? _lastWatchedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _service.fetchDetail(widget.slug);
    if (!mounted) return;
    setState(() {
      _detail = result;
      _lastWatchedIndex = ProgressService.lastEpisodeIndex(widget.slug);
      _isLoading = false;
    });
  }

  void _openPlayer(int startIndex) {
    final detail = _detail;
    if (detail == null) return;
    Get.to(() => TineflixPlayerScreen(detail: detail, startIndex: startIndex))?.then((_) {
      // Oynatıcıdan dönünce "kaldığın yerden" işaretini tazele.
      if (!mounted) return;
      setState(() => _lastWatchedIndex = ProgressService.lastEpisodeIndex(widget.slug));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _detail == null
              ? _buildError()
              : _buildContent(_detail!),
    );
  }

  Widget _buildError() {
    return Stack(
      children: [
        Positioned(
          top: 40,
          left: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const Center(
          child: Text('Dizi bilgisi yüklenemedi.', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildContent(SeriesDetail detail) {
    final series = detail.series;
    final isDubbed = series.isDubbed;
    final hasProgress = _lastWatchedIndex != null &&
        _lastWatchedIndex! >= 0 &&
        _lastWatchedIndex! < detail.episodes.length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          expandedHeight: 220,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: series.coverImage.isNotEmpty
                ? CachedNetworkImage(imageUrl: series.coverImage, fit: BoxFit.cover)
                : Container(color: const Color(0xFF1A1A1A)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('TİNEFLİX',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text(
                        series.title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isDubbed ? '🎙️ Türkçe Dublaj' : '💬 Orijinal Ses + Altyazı',
                  style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Text(
                  series.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // "İlk Bölümden Oynat" ve "Kaldığın Yerden Devam Et" — ikisi
                // birlikte gösterilir, otomatik devam ettirme yapılmaz.
                if (hasProgress)
                  _ActionCard(
                    icon: Icons.play_circle_fill,
                    label: 'Kaldığın Yerden Devam Et — Bölüm ${detail.episodes[_lastWatchedIndex!].episodeNumber}',
                    onTap: () => _openPlayer(_lastWatchedIndex!),
                  ),
                if (hasProgress) const SizedBox(height: 10),
                _ActionCard(
                  icon: Icons.replay_circle_filled,
                  label: 'İlk Bölümden Oynat',
                  onTap: () => _openPlayer(0),
                  outlined: hasProgress,
                ),

                const SizedBox(height: 20),
                const Text('Bölümler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ep = detail.episodes[index];
                final isLastWatched = index == _lastWatchedIndex;
                return GestureDetector(
                  onTap: () => _openPlayer(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: isLastWatched ? Border.all(color: const Color(0xFFE50914), width: 2) : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('${ep.episodeNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (isLastWatched)
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.circle, color: Color(0xFFE50914), size: 8),
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: detail.episodes.length,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverToBoxAdapter(child: NativeAdCard()),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : const Color(0xFFE50914),
          borderRadius: BorderRadius.circular(10),
          border: outlined ? Border.all(color: const Color(0xFFE50914)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: outlined ? const Color(0xFFE50914) : Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: outlined ? const Color(0xFFE50914) : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
