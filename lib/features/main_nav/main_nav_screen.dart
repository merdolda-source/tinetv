import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/remote_config_service.dart';
import '../home/home_screen.dart';
import '../tineflix/tineflix_screen.dart';
import '../sites/sites_screen.dart';
import '../film/film_screen.dart';
import '../puandurumu/puandurumu_screen.dart';
import '../canliskor/canliskor_screen.dart';
import '../canliskor/canliskor_controller.dart';
import '../haberler/haberler_screen.dart';

/// Alt gezinme kabuğu. TineFlix/Siteler Remote Config'ten kapalıysa (varsayılan)
/// hiç sekme çubuğu gösterilmez ve uygulama tıpkı öncekiyle aynı şekilde
/// doğrudan M3U ekranını (HomeScreen) açar — mevcut davranış korunur.
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final rc = RemoteConfigService();

    final tabs = <_TabItem>[
      const _TabItem('Kanallar', Icons.live_tv, HomeScreen()),
      if (rc.tineflixEnabled)
        const _TabItem('TineFlix', Icons.movie_creation_outlined, TineflixScreen()),
      if (rc.haberlerEnabled) const _TabItem('Haberler', Icons.article, HaberlerScreen()),
      if (rc.filmEnabled) const _TabItem('Filmler', Icons.local_movies, FilmScreen()),
      if (rc.canliskorEnabled)
        const _TabItem('Canlı Skor', Icons.sports_soccer, CanliskorScreen()),
      if (rc.puanligEnabled)
        const _TabItem('Puan Durumu', Icons.emoji_events, PuanDurumuScreen()),
      if (rc.sitesEnabled) const _TabItem('Siteler', Icons.public, SitesScreen()),
    ];

    if (_index >= tabs.length) _index = 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: tabs.length > 1
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFF0A0A0A),
              selectedItemColor: const Color(0xFFE50914),
              unselectedItemColor: Colors.grey,
              currentIndex: _index,
              onTap: (i) => _onTabTap(tabs, i),
              items: [
                for (final t in tabs)
                  BottomNavigationBarItem(icon: Icon(t.icon), label: t.title),
              ],
            )
          : null,
    );
  }

  // CanlıSkor sekmesi IndexedStack içinde ekrandan gizlense bile mount'lu
  // kalıyor — kontrolcü sekmeler arası geçişte duraklatılıp
  // devam ettirilmezse saniyelik yenileme sonsuza dek arka planda çalışırdı.
  void _onTabTap(List<_TabItem> tabs, int i) {
    if (!Get.isRegistered<CanliskorController>()) {
      setState(() => _index = i);
      return;
    }
    final controller = Get.find<CanliskorController>();
    if (tabs[_index].title == 'Canlı Skor') controller.pause();
    setState(() => _index = i);
    if (tabs[_index].title == 'Canlı Skor') controller.resume();
  }
}

class _TabItem {
  final String title;
  final IconData icon;
  final Widget screen;
  const _TabItem(this.title, this.icon, this.screen);
}
