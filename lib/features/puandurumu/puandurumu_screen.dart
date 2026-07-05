import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'puandurumu_controller.dart';
import '../../core/models/puanlig_model.dart';
import '../../core/widgets/native_ad_card.dart';

class PuanDurumuScreen extends StatelessWidget {
  const PuanDurumuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PuandurumuController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'PUAN DURUMU',
          style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }
        final veri = controller.veri.value;
        if (veri == null) {
          return const Center(
            child: Text('Puan durumu alınamadı', style: TextStyle(color: Colors.grey)),
          );
        }
        return Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final lig in veri.ligler)
                    _chip(lig.ad, controller.aktifLig.value == lig.key,
                        () => controller.selectLig(lig.key)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _sekmeButon('Genel', 'genel', controller)),
                Expanded(child: _sekmeButon('İç Saha', 'icSaha', controller)),
                Expanded(child: _sekmeButon('Dış Saha', 'disSaha', controller)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: controller.aktifListe.isEmpty
                  ? const Center(
                      child: Text('Puan durumu bulunamadı', style: TextStyle(color: Colors.grey)),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: _tablo(controller.aktifListe),
                      ),
                    ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: NativeAdCard(),
            ),
          ],
        );
      }),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE50914) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sekmeButon(String label, String key, PuandurumuController controller) {
    return Obx(() {
      final selected = controller.aktifSekme.value == key;
      return GestureDetector(
        onTap: () => controller.selectSekme(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFFE50914) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      );
    });
  }

  Widget _tablo(List<PuanSatiri> satirlar) {
    const headerStyle = TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold);
    const cellStyle = TextStyle(color: Colors.white, fontSize: 11.5);

    Widget hucre(String text, double width, {bool header = false, bool start = false}) {
      return SizedBox(
        width: width,
        child: Text(
          text,
          textAlign: start ? TextAlign.start : TextAlign.center,
          style: header ? headerStyle : cellStyle,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                hucre('#', 24, header: true),
                const SizedBox(width: 28),
                hucre('Takım', 130, header: true, start: true),
                hucre('O', 28, header: true),
                hucre('G', 28, header: true),
                hucre('B', 28, header: true),
                hucre('M', 28, header: true),
                hucre('A', 28, header: true),
                hucre('Y', 28, header: true),
                hucre('AV', 32, header: true),
                hucre('P', 28, header: true),
              ],
            ),
          ),
          for (final s in satirlar)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  hucre('${s.sira}', 24),
                  SizedBox(
                    width: 28,
                    child: s.logo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: s.logo,
                            width: 20,
                            height: 20,
                            errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 16, color: Colors.grey),
                          )
                        : const Icon(Icons.shield, size: 16, color: Colors.grey),
                  ),
                  hucre(s.takim, 130, start: true),
                  hucre('${s.oynanan}', 28),
                  hucre('${s.galibiyet}', 28),
                  hucre('${s.berabere}', 28),
                  hucre('${s.maglubiyet}', 28),
                  hucre('${s.attigi}', 28),
                  hucre('${s.yedigi}', 28),
                  hucre('${s.averaj}', 32),
                  hucre('${s.puan}', 28),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
