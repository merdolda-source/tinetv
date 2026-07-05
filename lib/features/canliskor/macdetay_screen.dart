import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/canliskor_model.dart';
import '../../core/services/canliskor_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/widgets/native_ad_card.dart';

class MacDetayScreen extends StatefulWidget {
  final MacVeri mac;
  const MacDetayScreen({super.key, required this.mac});

  @override
  State<MacDetayScreen> createState() => _MacDetayScreenState();
}

class _MacDetayScreenState extends State<MacDetayScreen> {
  final _service = CanliskorService();
  MacDetay? _detay;
  bool _isLoading = true;
  String _aktifSekme = 'olaylar'; // olaylar | puanDurumu | kadrolar
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    final result = await _service.fetchDetail(widget.mac.macUrl);
    if (!mounted) return;
    setState(() {
      if (result != null) _detay = result;
      _isLoading = false;
    });
    _timer?.cancel();
    final ms = RemoteConfigService().canliSkorRefreshMs;
    _timer = Timer(Duration(milliseconds: ms > 0 ? ms : 1000), _fetch);
  }

  @override
  Widget build(BuildContext context) {
    final mac = widget.mac;
    final canli = mac.durum == 'canli';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text('${mac.takim1} - ${mac.takim2}', style: const TextStyle(color: Colors.white, fontSize: 15)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _takimBaslik(mac.takim1, mac.takim1Logo)),
                Column(
                  children: [
                    Text(mac.skorYazisi,
                        style: TextStyle(
                            color: canli ? const Color(0xFFE50914) : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text(mac.durumYazisi,
                        style: TextStyle(color: canli ? const Color(0xFFE50914) : Colors.grey, fontSize: 12)),
                  ],
                ),
                Expanded(child: _takimBaslik(mac.takim2, mac.takim2Logo)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: NativeAdCard(),
          ),
          Row(
            children: [
              Expanded(child: _sekmeButon('Olaylar', 'olaylar')),
              Expanded(child: _sekmeButon('Puan Durumu', 'puanDurumu')),
              Expanded(child: _sekmeButon('Kadrolar', 'kadrolar')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                : _icerik(),
          ),
        ],
      ),
    );
  }

  Widget _takimBaslik(String isim, String logo) {
    return Column(
      children: [
        if (logo.isNotEmpty)
          CachedNetworkImage(
            imageUrl: logo,
            width: 36,
            height: 36,
            errorWidget: (_, __, ___) => const Icon(Icons.shield, color: Colors.grey, size: 28),
          )
        else
          const Icon(Icons.shield, color: Colors.grey, size: 28),
        const SizedBox(height: 6),
        Text(isim,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _sekmeButon(String label, String key) {
    final selected = _aktifSekme == key;
    return GestureDetector(
      onTap: () => setState(() => _aktifSekme = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: selected ? const Color(0xFFE50914) : Colors.transparent, width: 2),
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
  }

  Widget _icerik() {
    final detay = _detay;
    if (detay == null) {
      return const Center(child: Text('Maç detayı bulunamadı', style: TextStyle(color: Colors.grey)));
    }
    switch (_aktifSekme) {
      case 'puanDurumu':
        return _puanDurumuListesi(detay.puanDurumu);
      case 'kadrolar':
        return _kadrolarListesi(detay.kadroEv, detay.kadroMisafir);
      default:
        return _olaylarListesi(detay.olaylar);
    }
  }

  Widget _olaylarListesi(List<OlayVeri> olaylar) {
    if (olaylar.isEmpty) {
      return const Center(child: Text('Henüz gol/kart bilgisi yok.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: olaylar.length,
      itemBuilder: (context, index) {
        final o = olaylar[index];
        final ev = o.taraf == 'ev';
        String simge;
        switch (o.tip) {
          case 'gol':
            simge = '⚽';
            break;
          case 'sarikart':
            simge = '🟨';
            break;
          case 'kirmizikart':
            simge = '🟥';
            break;
          case 'degisiklik':
            simge = '🔄';
            break;
          default:
            simge = '•';
        }
        final metin = '$simge  ${o.aciklama}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(ev ? metin : '', textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5)),
              ),
              SizedBox(
                width: 42,
                child: Text("${o.dakika}'", textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
              ),
              Expanded(
                child: Text(!ev ? metin : '',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _puanDurumuListesi(List<MacPuanSatiri> liste) {
    if (liste.isEmpty) {
      return const Center(child: Text('Puan durumu bulunamadı.', style: TextStyle(color: Colors.grey)));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in liste)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text('${p.sira}', style: const TextStyle(color: Colors.grey, fontSize: 11.5))),
                    const SizedBox(width: 8),
                    if (p.logo.isNotEmpty)
                      CachedNetworkImage(imageUrl: p.logo, width: 18, height: 18)
                    else
                      const Icon(Icons.shield, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 140,
                      child: Text(p.takim,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: p.vurgulu ? FontWeight.bold : FontWeight.normal)),
                    ),
                    _puanHucre('${p.oynanan}'),
                    _puanHucre('${p.galibiyet}'),
                    _puanHucre('${p.berabere}'),
                    _puanHucre('${p.maglubiyet}'),
                    _puanHucre('${p.puan}', bold: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _puanHucre(String text, {bool bold = false}) {
    return SizedBox(
      width: 28,
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _kadrolarListesi(List<KadroVeri> ev, List<KadroVeri> misafir) {
    if (ev.isEmpty && misafir.isEmpty) {
      return const Center(child: Text('Kadro bilgisi bulunamadı.', style: TextStyle(color: Colors.grey)));
    }
    Widget kolon(List<KadroVeri> oyuncular) => Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: oyuncular.length,
            itemBuilder: (context, index) {
              final k = oyuncular[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text('${k.numara}',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(k.isim,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
    return Row(children: [kolon(ev), kolon(misafir)]);
  }
}
