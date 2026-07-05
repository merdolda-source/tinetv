class PuanLig {
  final String key;
  final String ad;

  PuanLig({required this.key, required this.ad});

  factory PuanLig.fromJson(Map<String, dynamic> json) => PuanLig(
        key: json['key'] as String? ?? '',
        ad: json['ad'] as String? ?? '',
      );
}

class PuanSatiri {
  final int sira;
  final String logo;
  final String takim;
  final String takimUrl;
  final int oynanan;
  final int galibiyet;
  final int berabere;
  final int maglubiyet;
  final int attigi;
  final int yedigi;
  final int averaj;
  final int puan;

  PuanSatiri({
    required this.sira,
    required this.logo,
    required this.takim,
    required this.takimUrl,
    required this.oynanan,
    required this.galibiyet,
    required this.berabere,
    required this.maglubiyet,
    required this.attigi,
    required this.yedigi,
    required this.averaj,
    required this.puan,
  });

  factory PuanSatiri.fromJson(Map<String, dynamic> json, String baseUrl) => PuanSatiri(
        sira: (json['sira'] as num?)?.toInt() ?? 0,
        logo: _tamUrl(json['logo'] as String? ?? '', baseUrl),
        takim: json['takim'] as String? ?? '',
        takimUrl: json['takimUrl'] as String? ?? '',
        oynanan: (json['oynanan'] as num?)?.toInt() ?? 0,
        galibiyet: (json['galibiyet'] as num?)?.toInt() ?? 0,
        berabere: (json['berabere'] as num?)?.toInt() ?? 0,
        maglubiyet: (json['maglubiyet'] as num?)?.toInt() ?? 0,
        attigi: (json['attigi'] as num?)?.toInt() ?? 0,
        yedigi: (json['yedigi'] as num?)?.toInt() ?? 0,
        averaj: (json['averaj'] as num?)?.toInt() ?? 0,
        puan: (json['puan'] as num?)?.toInt() ?? 0,
      );

  // "logo" alanı sunucudan göreli path olarak geliyor (örn. "gorsel.php?u=...")
  // — tabanUrl ile birleştirip tam URL'e çeviriyoruz.
  static String _tamUrl(String path, String baseUrl) {
    if (path.isEmpty || path.startsWith('http')) return path;
    return Uri.parse(baseUrl).resolve(path).toString();
  }
}

class PuanDurumuVeri {
  final List<PuanLig> ligler;
  final List<PuanSatiri> genel;
  final List<PuanSatiri> icSaha;
  final List<PuanSatiri> disSaha;

  PuanDurumuVeri({
    required this.ligler,
    required this.genel,
    required this.icSaha,
    required this.disSaha,
  });
}
