import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/models/site_model.dart';
import '../../core/services/remote_config_service.dart';
import 'site_webview_screen.dart';

/// Remote Config'teki "sites_json" listesinden dizi/film sitelerini gösterir.
/// Boşsa (varsayılan) bu sekme MainNavScreen tarafından zaten gizlenir.
class SitesScreen extends StatelessWidget {
  const SitesScreen({super.key});

  List<SiteEntry> _parseSites() {
    try {
      final raw = RemoteConfigService().sitesJson;
      if (raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => SiteEntry.fromJson(e.cast<String, dynamic>()))
          .where((s) => s.url.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sites = _parseSites();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'SİTELER',
          style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: sites.isEmpty
          ? const Center(
              child: Text('Site bulunamadı', style: TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final site = sites[index];
                return GestureDetector(
                  onTap: () => Get.to(() => SiteWebviewScreen(site: site)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.public, color: Color(0xFFE50914)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            site.title.isNotEmpty ? site.title : site.url,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
