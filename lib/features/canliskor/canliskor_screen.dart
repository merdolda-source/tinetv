import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'canliskor_controller.dart';
import '../../core/models/canliskor_model.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/widgets/native_ad_card.dart';
import 'macdetay_screen.dart';

abstract class _Row {}

class _HeaderRow extends _Row {
  final TurnuvaVeri turnuva;
  _HeaderRow(this.turnuva);
}

class _MacRow extends _Row {
  final MacVeri mac;
  _MacRow(this.mac);
}

class _AdRow extends _Row {}

// Her turnuva başlığından sonra kendi maçları, N maçta bir de native
// reklam satırı gelecek şekilde düzleştirilmiş liste oluşturur.
List<_Row> _rowsOlustur(List<TurnuvaVeri> turnuvalar) {
  final aralik = RemoteConfigService().gridNativeAdInterval;
  final rows = <_Row>[];
  int macSayaci = 0;
  for (final t in turnuvalar) {
    rows.add(_HeaderRow(t));
    for (final m in t.maclar) {
      rows.add(_MacRow(m));
      macSayaci++;
      if (aralik > 0 && macSayaci % aralik == 0) rows.add(_AdRow());
    }
  }
  return rows;
}

class CanliskorScreen extends StatelessWidget {
  const CanliskorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CanliskorController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'CANLI SKOR',
          style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip('Tümü', 'tumu', controller),
                    _chip('Canlı', 'canli', controller),
                    _chip('Bitti', 'bitti', controller),
                    _chip('Başlamadı', 'baslamadi', controller),
                  ],
                )),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
              }
              final liste = controller.filtrelenmisListe;
              if (liste.isEmpty) {
                return const Center(
                  child: Text('Maç bulunamadı', style: TextStyle(color: Colors.grey)),
                );
              }
              final rows = _rowsOlustur(liste);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  if (row is _HeaderRow) return _TurnuvaBasligi(turnuva: row.turnuva);
                  if (row is _MacRow) return _MacKarti(mac: row.mac);
                  return const NativeAdCard();
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String key, CanliskorController controller) {
    return Obx(() {
      final selected = controller.aktifFiltre.value == key;
      return GestureDetector(
        onTap: () => controller.selectFiltre(key),
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
    });
  }
}

class _TurnuvaBasligi extends StatelessWidget {
  final TurnuvaVeri turnuva;
  const _TurnuvaBasligi({required this.turnuva});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (turnuva.bayrak.isNotEmpty)
            CachedNetworkImage(imageUrl: turnuva.bayrak, width: 18, height: 18),
          const SizedBox(width: 8),
          Text(turnuva.ad,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(width: 6),
          Text(turnuva.ulke, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MacKarti extends StatelessWidget {
  final MacVeri mac;
  const _MacKarti({required this.mac});

  @override
  Widget build(BuildContext context) {
    final canli = mac.durum == 'canli';
    return GestureDetector(
      onTap: () => Get.to(() => MacDetayScreen(mac: mac)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: canli ? Border.all(color: const Color(0xFFE50914), width: 1) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (mac.takim1Logo.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: mac.takim1Logo,
                      width: 20,
                      height: 20,
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 16, color: Colors.grey),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(mac.takim1,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  mac.skorYazisi,
                  style: TextStyle(
                    color: canli ? const Color(0xFFE50914) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  mac.durumYazisi,
                  style: TextStyle(
                    color: canli ? const Color(0xFFE50914) : Colors.grey,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(mac.takim2,
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  if (mac.takim2Logo.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: mac.takim2Logo,
                      width: 20,
                      height: 20,
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
