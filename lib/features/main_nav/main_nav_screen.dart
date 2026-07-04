import 'package:flutter/material.dart';
import '../../core/services/remote_config_service.dart';
import '../home/home_screen.dart';
import '../tineflix/tineflix_screen.dart';
import '../sites/sites_screen.dart';

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
              onTap: (i) => setState(() => _index = i),
              items: [
                for (final t in tabs)
                  BottomNavigationBarItem(icon: Icon(t.icon), label: t.title),
              ],
            )
          : null,
    );
  }
}

class _TabItem {
  final String title;
  final IconData icon;
  final Widget screen;
  const _TabItem(this.title, this.icon, this.screen);
}
