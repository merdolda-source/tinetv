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
        final ana = controller.anaSekme.value;
        // Lig listesi puan veya fikstür verisinden (ikisi de aynı ligleri döner).
        final ligler = controller.veri.value?.ligler ??
            controller.fikstur.value?.ligler ??
            const <PuanLig>[];

        return Column(
          children: [
            // ── Ana sekme: Puan Durumu / Fikstür ──────────────────────────
            Row(
              children: [
                Expanded(child: _anaSekmeButon(controller, 'Puan Durumu', 'puan')),
                Expanded(child: _anaSekmeButon(controller, 'Fikstür', 'fikstur')),
              ],
            ),
            // ── Lig seçici (paylaşımlı) ───────────────────────────────────
            if (ligler.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final lig in ligler)
                      _chip(lig.ad, controller.aktifLig.value == lig.key,
                          () => controller.selectLig(lig.key)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: ana == 'puan' ? _puanBody(controller) : _fiksturBody(controller),
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

  // ── PUAN DURUMU gövdesi ─────────────────────────────────────────────────
  Widget _puanBody(PuandurumuController c) {
    if (c.isLoading.value) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }
    if (c.veri.value == null) {
      return const Center(child: Text('Puan durumu alınamadı', style: TextStyle(color: Colors.grey)));
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _sekmeButon('Genel', 'genel', c)),
            Expanded(child: _sekmeButon('İç Saha', 'icSaha', c)),
            Expanded(child: _sekmeButon('Dış Saha', 'disSaha', c)),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: c.aktifListe.isEmpty
              ? const Center(child: Text('Puan durumu bulunamadı', style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(child: _tablo(c.aktifListe)),
                ),
        ),
      ],
    );
  }

  // ── FİKSTÜR gövdesi ─────────────────────────────────────────────────────
  Widget _fiksturBody(PuandurumuController c) {
    if (c.fiksturLoading.value && c.fikstur.value == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }
    final f = c.fikstur.value;
    if (f == null) {
      return const Center(child: Text('Fikstür alınamadı', style: TextStyle(color: Colors.grey)));
    }
    return Column(
      children: [
        // Hafta seçici
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (int h = 1; h <= f.maxHafta; h++)
                _chip('$h. Hafta', c.aktifHafta.value == h, () => c.selectHafta(h)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: f.maclar.isEmpty
              ? const Center(child: Text('Bu hafta maç yok', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: f.maclar.length,
                  itemBuilder: (_, i) => _fiksturSatiri(f.maclar[i]),
                ),
        ),
      ],
    );
  }

  Widget _fiksturSatiri(FiksturMac m) {
    final orta = m.skorVar
        ? '${m.skor1} - ${m.skor2}'
        : (m.saat.isNotEmpty ? m.saat : (m.tarih ?? '-'));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(m.takim1,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                ),
                const SizedBox(width: 8),
                _logo(m.takim1Logo),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: m.canli ? const Color(0xFFE50914) : const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(orta,
                    style: TextStyle(
                        color: m.canli ? Colors.white : Colors.grey.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5)),
                if (!m.skorVar && m.tarih != null && m.tarih!.isNotEmpty && m.saat.isNotEmpty)
                  Text(m.tarih!, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                if (m.canli)
                  const Text('CANLI', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _logo(m.takim2Logo),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(m.takim2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo(String url) => SizedBox(
        width: 22,
        height: 22,
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                width: 22,
                height: 22,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 16, color: Colors.grey),
              )
            : const Icon(Icons.shield, size: 16, color: Colors.grey),
      );

  Widget _anaSekmeButon(PuandurumuController c, String label, String key) {
    return Obx(() {
      final selected = c.anaSekme.value == key;
      return GestureDetector(
        onTap: () => c.selectAnaSekme(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    });
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
