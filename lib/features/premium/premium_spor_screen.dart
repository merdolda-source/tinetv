import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/premium_model.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/mahsun_source.dart';
import '../../core/services/ad_service.dart';
import 'premium_player_screen.dart';

/// Boss Sports / Patron-Taraftarium premium spor listesi (Android
/// PremiumSporActivity karşılığı). Tek ekran, iki kullanım:
///   Boss   : urls=[base/api/matches, base/api/channels], bossEmbedBase=base/?channel=
///   Patron : urls=[patron_section_url], embedOnly=true, sectionEmbedBase=...
class PremiumSporScreen extends StatefulWidget {
  final String title;
  final List<String> urls;
  final bool embedOnly;
  final String sectionEmbedBase;
  final String bossEmbedBase;
  // kind: 'generic' (Boss/Patron/JSON)  |  'mahsun' (sunucusuz script4.js).
  final String kind;
  final String dataUrl; // mahsun: script4.js adresi (opsiyonel)

  const PremiumSporScreen({
    super.key,
    required this.title,
    required this.urls,
    this.embedOnly = false,
    this.sectionEmbedBase = '',
    this.bossEmbedBase = '',
    this.kind = 'generic',
    this.dataUrl = '',
  });

  @override
  State<PremiumSporScreen> createState() => _PremiumSporScreenState();
}

class _PremiumSporScreenState extends State<PremiumSporScreen> {
  final _service = PremiumService();
  List<PremiumItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = widget.kind == 'mahsun'
        ? await MahsunSource.fetch(
            widget.urls.isNotEmpty ? widget.urls.first : '',
            dataUrl: widget.dataUrl,
          )
        : await _service.fetch(
            urls: widget.urls,
            embedOnly: widget.embedOnly,
            sectionEmbedBase: widget.sectionEmbedBase,
            bossEmbedBase: widget.bossEmbedBase,
          );
    if (!mounted) return;
    setState(() {
      _items = result;
      _loading = false;
    });
  }

  void _open(PremiumItem item) {
    // Boss / Patron / Mahsun / Premium açılışında da geçiş reklamı (sayaçlı).
    AdService().onChannelOpened();
    Get.to(() => PremiumPlayerScreen(item: item));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          widget.title.toUpperCase(),
          style: const TextStyle(
              color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Yayın bulunamadı',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Yenile')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFE50914),
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _card(_items[index]),
                  ),
                ),
    );
  }

  Widget _card(PremiumItem item) {
    return GestureDetector(
      onTap: () => _open(item),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.thumb,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _thumbFallback(),
                    )
                  : _thumbFallback(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  if (item.group.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.group,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Color(0xFFE50914)),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 44,
        height: 44,
        color: const Color(0xFF222222),
        child: const Icon(Icons.live_tv, color: Colors.grey, size: 22),
      );
}
