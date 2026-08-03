import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/remote_config_service.dart';
import '../home/home_screen.dart';
import '../puandurumu/puandurumu_screen.dart';
import '../canliskor/canliskor_screen.dart';
import '../canliskor/canliskor_controller.dart';

/// Alt gezinme kabuğu — SADE menü.
///
/// Alt menüde yalnızca: Ana Sayfa + (RC açıksa) Canlı Skor + (RC açıksa) Puan
/// Durumu bulunur. Boss / Taraftarium / TineFlix / Filmler / Haberler / Siteler
/// artık alt sekme DEĞİL — Ana Sayfa'da LİSTE (kart) olarak açılır (bkz.
/// HomeScreen). Böylece çubuk hiç kalabalıklaşmaz.
///
/// M3U "formalite": hiç kart yok + m3u_url boşsa Ana Sayfa yine birebir eski
/// M3U giriş ekranını gösterir; her şey kapalıyken alt çubuk hiç çıkmaz.
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

    // ANA KİLİT: login=true → İNCELEME MODU. Alt menü YOK, hiç sekme yok;
    // yalnızca Ana Sayfa (o da HomeScreen içinde sadece M3U login ekranını
    // gösterir). Tüm içerikler gizli.
    if (rc.loginGate) {
      return const HomeScreen();
    }

    // SADE alt menü: Ana Sayfa + (açıksa) Canlı Skor + (açıksa) Puan Durumu.
    // Diğer tüm özellikler Ana Sayfa'da kart olarak açılır.
    final tabs = <_TabItem>[
      const _TabItem('Ana Sayfa', Icons.home_rounded, HomeScreen()),
      if (rc.canliskorEnabled)
        const _TabItem('Canlı Skor', Icons.sports_soccer, CanliskorScreen()),
      if (rc.puanligEnabled)
        const _TabItem('Puan Durumu', Icons.emoji_events, PuanDurumuScreen()),
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
