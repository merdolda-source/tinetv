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
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }
        final rc = RemoteConfigService();

        // ── İNCELEME MODU (login=true): SADECE M3U giriş ekranı (formalite).
        //    Reviewer link girip "Kanalları Yükle" derse kanal listesi açılır.
        if (rc.loginGate) {
          return controller.hasUrl.value
              ? _buildChannelList(controller)
              : _buildUrlInputScreen(controller);
        }

        // ── NORMAL MOD (login=false): Android liste yapısı. ASLA giriş ekranı YOK.
        return _buildHome(controller, rc);
      }),
    );
  }

  /// RC'de açık olan özellikleri Ana Sayfa kart şeridine toplar — Android
  /// sırasıyla: Patron → Boss → Mahsun → (content_json) → sekmeler.
  List<_Feature> _enabledFeatures() {
    final rc = RemoteConfigService();
    if (rc.loginGate) return const [];
    final list = <_Feature>[];

    // 1) Patron / Taraftarium (embedOnly iframe) — Android patron_section_*.
    final patronUrl = rc.patronSectionUrl;
    if (rc.patronSectionShow && patronUrl.isNotEmpty) {
      list.add(_Feature(rc.patronSectionTitle, Icons.stadium, () => PremiumSporScreen(
            title: rc.patronSectionTitle,
            urls: [patronUrl],
            embedOnly: true,
            sectionEmbedBase: rc.patronSectionEmbedBase,
          )));
    }

    // 2) Boss Sports — Android boss_section_* (matches + channels + watch).
    final bossBase = rc.bossSectionBase;
    if (rc.bossSectionShow && bossBase.isNotEmpty) {
      list.add(_Feature(rc.bossSectionTitle, Icons.sports, () => PremiumSporScreen(
            title: rc.bossSectionTitle,
            urls: ['$bossBase/api/matches', '$bossBase/api/channels'],
            bossEmbedBase: '$bossBase/?channel=',
          )));
    }

    // 4) content_json (geriye-uyumlu) — ekstra m3u / resolve kaynakları.
    for (final s in ContentSource.parseList(rc.contentSourcesJson)) {
      if (s.isM3u) {
        final t = s.title.isEmpty ? 'Liste' : s.title;
        list.add(_Feature(t, Icons.playlist_play, () => M3uListScreen(title: t, url: s.url)));
      } else {
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

    // 5) Sekmeler
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

  /// NORMAL MOD (login=false) Ana Sayfa — Android liste yapısı:
  /// özellik kartları şeridi + Premium (premium_sites) + Kanal Listeleri
  /// (m3u_playlists) + varsa tek m3u_url. HİÇBİR yerde M3U giriş ekranı yok.
  Widget _buildHome(HomeController controller, RemoteConfigService rc) {
    final features = _enabledFeatures();
    final premium = rc.premiumSites;
    final playlists = rc.m3uPlaylists;
    final singleM3u = rc.m3uUrl.trim();

    final sections = <Widget>[];

    // ── Premium bölümü: özellik kartları (Patron / Boss / Mahsun / TineFlix …)
    //    + premium_sites — HEPSİ DÜŞEY kart. Yana kaydırma YOK.
    final premiumCards = <Widget>[];
    for (final f in features) {
      premiumCards.add(_listCard(f.title, f.icon, f.open));
    }
    for (final p in premium) {
      final title = p['title'] ?? 'PREMIUM';
      final url = p['url'] ?? '';
      premiumCards.add(_listCard(title, Icons.workspace_premium,
          () => PremiumSporScreen(title: title, urls: [url])));
    }
    if (premiumCards.isNotEmpty) {
      sections.add(_sectionHeader('Premium'));
      sections.addAll(premiumCards);
    }

    // ── Kanal Listeleri: m3u_playlists + varsa tek m3u_url.
    if (playlists.isNotEmpty || singleM3u.isNotEmpty) {
      sections.add(_sectionHeader('Kanal Listeleri'));
      for (final pl in playlists) {
        final name = pl['name'] ?? 'Liste';
        final url = pl['url'] ?? '';
        sections.add(_listCard(name, Icons.playlist_play,
            () => M3uListScreen(title: name, url: url)));
      }
      if (singleM3u.isNotEmpty) {
        sections.add(_listCard('Kanallar', Icons.live_tv,
            () => M3uListScreen(title: 'Kanallar', url: singleM3u)));
      }
    }

    // Hiç içerik yoksa: boş durum (M3U giriş ekranı DEĞİL).
    if (sections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('İçerik yakında eklenecek.',
              style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        ),
      );
    }

    return ListView(
      children: [
        ...sections,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _listCard(String title, IconData icon, Widget Function() open) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: GestureDetector(
          onTap: () => Get.to(open),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x22E50914)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFE50914), size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );

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
