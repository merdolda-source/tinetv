class MacVeri {
  final String id;
  final String durum;
  final String durumYazisi;
  final int dakika;
  final String takim1;
  final String takim2;
  final String takim1Logo;
  final String takim2Logo;
  final String skorYazisi;
  final int? skor1;
  final int? skor2;
  final String macUrl;

  MacVeri({
    required this.id,
    required this.durum,
    required this.durumYazisi,
    required this.dakika,
    required this.takim1,
    required this.takim2,
    required this.takim1Logo,
    required this.takim2Logo,
    required this.skorYazisi,
    required this.skor1,
    required this.skor2,
    required this.macUrl,
  });

  factory MacVeri.fromJson(Map<String, dynamic> json, String baseUrl) => MacVeri(
        id: json['id']?.toString() ?? '',
        durum: json['durum'] as String? ?? '',
        durumYazisi: json['durumYazisi'] as String? ?? '',
        dakika: (json['dakika'] as num?)?.toInt() ?? 0,
        takim1: json['takim1'] as String? ?? '',
        takim2: json['takim2'] as String? ?? '',
        takim1Logo: tamUrl(json['takim1Logo'] as String? ?? '', baseUrl),
        takim2Logo: tamUrl(json['takim2Logo'] as String? ?? '', baseUrl),
        skorYazisi: json['skorYazisi'] as String? ?? '-',
        skor1: (json['skor1'] as num?)?.toInt(),
        skor2: (json['skor2'] as num?)?.toInt(),
        macUrl: json['macUrl'] as String? ?? '',
      );
}

class TurnuvaVeri {
  final String ad;
  final String ulke;
  final String bayrak;
  final List<MacVeri> maclar;

  TurnuvaVeri({required this.ad, required this.ulke, required this.bayrak, required this.maclar});

  factory TurnuvaVeri.fromJson(Map<String, dynamic> json, String baseUrl) {
    final maclarJson = (json['maclar'] as List?) ?? const [];
    return TurnuvaVeri(
      ad: json['turnuvaAdi'] as String? ?? '',
      ulke: json['ulke'] as String? ?? '',
      bayrak: tamUrl(json['bayrak'] as String? ?? '', baseUrl),
      maclar: maclarJson
          .whereType<Map>()
          .map((e) => MacVeri.fromJson(e.cast<String, dynamic>(), baseUrl))
          .toList(),
    );
  }
}

class OlayVeri {
  final int dakika;
  final String tip;
  final String aciklama;
  final String taraf;

  OlayVeri({required this.dakika, required this.tip, required this.aciklama, required this.taraf});

  factory OlayVeri.fromJson(Map<String, dynamic> json) => OlayVeri(
        dakika: (json['dakika'] as num?)?.toInt() ?? 0,
        tip: json['tip'] as String? ?? 'diger',
        aciklama: json['aciklama'] as String? ?? '',
        taraf: json['taraf'] as String? ?? 'misafir',
      );
}

class MacPuanSatiri {
  final int sira;
  final String logo;
  final String takim;
  final int oynanan;
  final int galibiyet;
  final int berabere;
  final int maglubiyet;
  final int attigi;
  final int yedigi;
  final int averaj;
  final int puan;
  final bool vurgulu;

  MacPuanSatiri({
    required this.sira,
    required this.logo,
    required this.takim,
    required this.oynanan,
    required this.galibiyet,
    required this.berabere,
    required this.maglubiyet,
    required this.attigi,
    required this.yedigi,
    required this.averaj,
    required this.puan,
    required this.vurgulu,
  });

  factory MacPuanSatiri.fromJson(Map<String, dynamic> json, String baseUrl) => MacPuanSatiri(
        sira: (json['sira'] as num?)?.toInt() ?? 0,
        logo: tamUrl(json['logo'] as String? ?? '', baseUrl),
        takim: json['takim'] as String? ?? '',
        oynanan: (json['oynanan'] as num?)?.toInt() ?? 0,
        galibiyet: (json['galibiyet'] as num?)?.toInt() ?? 0,
        berabere: (json['berabere'] as num?)?.toInt() ?? 0,
        maglubiyet: (json['maglubiyet'] as num?)?.toInt() ?? 0,
        attigi: (json['attigi'] as num?)?.toInt() ?? 0,
        yedigi: (json['yedigi'] as num?)?.toInt() ?? 0,
        averaj: (json['averaj'] as num?)?.toInt() ?? 0,
        puan: (json['puan'] as num?)?.toInt() ?? 0,
        vurgulu: json['vurgulu'] as bool? ?? false,
      );
}

class KadroVeri {
  final int numara;
  final String bayrak;
  final String isim;

  KadroVeri({required this.numara, required this.bayrak, required this.isim});

  factory KadroVeri.fromJson(Map<String, dynamic> json, String baseUrl) => KadroVeri(
        numara: (json['numara'] as num?)?.toInt() ?? 0,
        bayrak: tamUrl(json['bayrak'] as String? ?? '', baseUrl),
        isim: json['isim'] as String? ?? '',
      );
}

class MacDetay {
  final List<OlayVeri> olaylar;
  final List<MacPuanSatiri> puanDurumu;
  final List<KadroVeri> kadroEv;
  final List<KadroVeri> kadroMisafir;

  MacDetay({
    required this.olaylar,
    required this.puanDurumu,
    required this.kadroEv,
    required this.kadroMisafir,
  });
}

// "logo"/"bayrak" alanları sunucudan göreli path olarak geliyor
// (örn. "gorsel.php?u=..."), tabanUrl ile birleştirip tam URL yapıyoruz.
String tamUrl(String path, String baseUrl) {
  if (path.isEmpty || path.startsWith('http')) return path;
  return Uri.parse(baseUrl).resolve(path).toString();
}
