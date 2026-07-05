import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'haberler_controller.dart';
import '../../core/models/haber_model.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/widgets/native_ad_card.dart';
import 'haber_detay_screen.dart';

// Haber kartları arasına N öğede bir native reklam satırı ekler.
// Reklam satırının index'i, öğe sayısı sabit kaldığı sürece stabil kalır —
// bu yüzden yenilemede reklam yeniden yüklenip titremez.
List<Object> _rowsOlustur(List<HaberOzet> haberler) {
  final aralik = RemoteConfigService().gridNativeAdInterval;
  final rows = <Object>[];
  for (var i = 0; i < haberler.length; i++) {
    rows.add(haberler[i]);
    if (aralik > 0 && (i + 1) % aralik == 0) rows.add(const _AdMarker());
  }
  return rows;
}

class _AdMarker {
  const _AdMarker();
}

class HaberlerScreen extends StatelessWidget {
  const HaberlerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HaberlerController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'HABERLER',
          style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }
        if (controller.haberler.isEmpty) {
          return const Center(
            child: Text('Haber bulunamadı', style: TextStyle(color: Colors.grey)),
          );
        }
        final rows = _rowsOlustur(controller.haberler);
        return RefreshIndicator(
          color: const Color(0xFFE50914),
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final row = rows[index];
              if (row is HaberOzet) return _HaberKarti(haber: row);
              return const NativeAdCard();
            },
          ),
        );
      }),
    );
  }
}

class _HaberKarti extends StatelessWidget {
  final HaberOzet haber;
  const _HaberKarti({required this.haber});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => HaberDetayScreen(haber: haber)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (haber.gorsel.isNotEmpty)
              CachedNetworkImage(
                imageUrl: haber.gorsel,
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.article, color: Colors.grey),
              )
            else
              Container(width: 100, height: 80, color: Colors.black26, child: const Icon(Icons.article, color: Colors.grey)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  haber.baslik,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
