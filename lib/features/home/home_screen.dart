import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_controller.dart';
import '../channel_detail/channel_detail_screen.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/ad_free_service.dart';
import '../../core/services/remote_config_service.dart';
// Ana Sayfa listesinden (kart) açılan özellik ekranları.
import '../premium/premium_spor_screen.dart';
import '../tineflix/tineflix_screen.dart';
import '../film/film_screen.dart';
import '../haberler/haberler_screen.dart';
import '../sites/sites_screen.dart';
import 'm3u_list_screen.dart';
import '../../core/models/content_source_model.dart';

/// Ana Sayfa'da kart olarak görünen özellik (alt menüden çıkarılanlar).
class _Feature {
  final String title;
  final IconData icon;
  final Widget Function() open;
  const _Feature(this.title, this.icon, this.open);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'TİNE TV',
          style: TextStyle(
            color: Color(0xFFE50914),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              AdFreeService().isAdFree ? Icons.card_giftcard : Icons.card_giftcard_outlined,
              color: const Color(0xFFE50914),
            ),
            tooltip: 'Reklamsız İzle',
            onPressed: () => _watchRewardedForAdFree(context),
          ),
          Obx(() => controller.hasUrl.value
              ? IconButton(
                  icon: const Icon(Icons.link_off, color: Colors.grey),
                  onPressed: controller.clearUrl,
                  tooltip: 'Linki Değiştir',
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        // Loading
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        final features = _enabledFeatures();

        // M3U "FORMALİTE" KORUNDU: hiç özellik kartı yok + M3U linki yoksa
        // ekran birebir eski M3U giriş ekranıdır (App Store onay durumu).
        if (features.isEmpty && !controller.hasUrl.value) {
          return _buildUrlInputScreen(controller);
        }

        // Aksi halde LİSTE yapısı: üstte özellik kartları şeridi, altta ya
        // kanal listesi ya da (link yoksa) M3U giriş ekranı.
        return Column(
          children: [
            if (features.isNotEmpty) _featureStrip(features),
            Expanded(
              child: controller.hasUrl.value
                  ? _buildChannelList(controller)
                  : _buildUrlInputScreen(controller),
            ),
          ],
        );
      }),
    );
  }

  /// RC'de açık olan özellikleri (alt menüden çıkarılanlar) Ana Sayfa kartı
  /// olarak toplar. Boss/Patron yalnızca adresi de doluysa eklenir.
  List<_Feature> _enabledFeatures() {
    final rc = RemoteConfigService();

    // ANA KİLİT: login=true iken hiçbir içerik kartı gösterilmez.
    if (rc.loginGate) return const [];

    final list = <_Feature>[];

    // 1) Çoklu kaynak (content_json) — birden fazla M3U + resolve, RC'den yönetilir.
    for (final s in ContentSource.parseList(rc.contentSourcesJson)) {
      if (s.isM3u) {
        final t = s.title.isEmpty ? 'Liste' : s.title;
        list.add(_Feature(t, Icons.playlist_play, () => M3uListScreen(title: t, url: s.url)));
      } else {
        // resolve → resolver'lı oynatıcı (Boss/Patron ile aynı altyapı).
        final t = s.title.isEmpty ? 'Canlı Yayın' : s.title;
        list.add(_Feature(t, Icons.live_tv, () => PremiumSporScreen(
              title: t,
              urls: [s.url],
              embedOnly: s.embedOnly,
              sectionEmbedBase: s.embedOnly ? s.embedBase : '',
              bossEmbedBase: s.embedOnly ? '' : s.embedBase,
            )));
      }
    }

    // 2) Adlı bölümler (geriye dönük): Boss / Patron / TineFlix / Filmler / …
    final bossBase = rc.bossSectionBase;
    if (rc.bossSectionShow && bossBase.isNotEmpty) {
      list.add(_Feature(rc.bossSectionTitle, Icons.sports, () => PremiumSporScreen(
            title: rc.bossSectionTitle,
            urls: ['$bossBase/api/matches', '$bossBase/api/channels'],
            bossEmbedBase: '$bossBase/?channel=',
          )));
    }
    final patronUrl = rc.patronSectionUrl;
    if (rc.patronSectionShow && patronUrl.isNotEmpty) {
      list.add(_Feature(rc.patronSectionTitle, Icons.stadium, () => PremiumSporScreen(
            title: rc.patronSectionTitle,
            urls: [patronUrl],
            embedOnly: true,
            sectionEmbedBase: rc.patronSectionEmbedBase,
          )));
    }
    if (rc.tineflixEnabled) {
      list.add(_Feature('TineFlix', Icons.movie_creation_outlined, () => const TineflixScreen()));
    }
    if (rc.filmEnabled) {
      list.add(_Feature('Filmler', Icons.local_movies, () => const FilmScreen()));
    }
    if (rc.haberlerEnabled) {
      list.add(_Feature('Haberler', Icons.article, () => const HaberlerScreen()));
    }
    if (rc.sitesEnabled) {
      list.add(_Feature('Siteler', Icons.public, () => const SitesScreen()));
    }
    return list;
  }

  /// Yatay kaydırmalı özellik kartları şeridi (Android ana ekran kartları gibi).
  Widget _featureStrip(List<_Feature> features) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        itemCount: features.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final f = features[i];
          return GestureDetector(
            onTap: () => Get.to(f.open),
            child: Container(
              width: 108,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x22E50914)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(f.icon, color: const Color(0xFFE50914), size: 26),
                  Text(
                    f.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _watchRewardedForAdFree(BuildContext context) {
    if (AdFreeService().isAdFree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zaten reklamsız moddasın, keyfini çıkar! 🎉')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reklam yükleniyor...')),
    );
    AdService().showRewardedForAdFree(
      onGranted: () {
        final hours = RemoteConfigService().adFreeHours;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $hours saat reklamsız! Bol keyifli izlemeler.')),
        );
      },
      onFailed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reklam gösterilemedi, biraz sonra tekrar dene.')),
        );
      },
    );
  }

  Widget _buildUrlInputScreen(HomeController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // İkon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                color: Color(0xFFE50914),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'M3U Oynatıcı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kanalları izlemek için M3U playlist linkinizi girin',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // URL giriş alanı
            TextField(
              controller: controller.urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://example.com/playlist.m3u',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.link, color: Color(0xFFE50914)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE50914)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Yükle butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  controller.loadFromUserUrl(controller.urlController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kanalları Yükle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Bilgi kutusu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nasıl kullanılır?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. M3U playlist URL\'nizi girin\n'
                    '2. "Kanalları Yükle" butonuna tıklayın\n'
                    '3. Kanallarınız yüklenecek ve izlemeye başlayabilirsiniz',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelList(HomeController controller) {
    return Column(
      children: [
        // Arama çubuğu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            onChanged: controller.search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Kanal ara...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Kategori listesi
        SizedBox(
          height: 44,
          child: Obx(() => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: controller.categories.length,
                itemBuilder: (context, index) {
                  final cat = controller.categories[index];
                  return Obx(() {
                    final isSelected = controller.selectedCategory.value == cat;
                    return GestureDetector(
                      onTap: () => controller.filterByCategory(cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE50914)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  });
                },
              )),
        ),
        const SizedBox(height: 8),

        // Kanal grid
        Expanded(
          child: Obx(() => controller.filteredChannels.isEmpty
              ? const Center(
                  child: Text(
                    'Kanal bulunamadı',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 16 / 9,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: controller.filteredChannels.length,
                  itemBuilder: (context, index) {
                    final channel = controller.filteredChannels[index];
                    return GestureDetector(
                      onTap: () => Get.to(() => ChannelDetailScreen(channel: channel)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (channel.logo != null)
                              CachedNetworkImage(
                                imageUrl: channel.logo!,
                                height: 48,
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.tv,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              )
                            else
                              const Icon(
                                Icons.tv,
                                color: Colors.grey,
                                size: 40,
                              ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                channel.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
        ),
      ],
    );
  }
}
