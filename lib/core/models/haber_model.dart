import 'canliskor_model.dart' show tamUrl;

class HaberOzet {
  final String id;
  final String baslik;
  final String gorsel;
  final String detayPath;

  HaberOzet({required this.id, required this.baslik, required this.gorsel, required this.detayPath});

  factory HaberOzet.fromJson(Map<String, dynamic> json, String baseUrl) => HaberOzet(
        id: json['id']?.toString() ?? '',
        baslik: json['baslik'] as String? ?? '',
        gorsel: tamUrl(json['gorsel'] as String? ?? '', baseUrl),
        detayPath: json['detay'] as String? ?? '',
      );
}

class HaberDetay {
  final String baslik;
  final String gorsel;
  final List<String> paragraflar;

  HaberDetay({required this.baslik, required this.gorsel, required this.paragraflar});

  factory HaberDetay.fromJson(Map<String, dynamic> json, String baseUrl) => HaberDetay(
        baslik: json['baslik'] as String? ?? '',
        gorsel: tamUrl(json['gorsel'] as String? ?? '', baseUrl),
        // "__AD_BREAK__" işareti korunuyor — ekran tarafında tam bu noktada
        // gerçek bir native reklam kartına çevriliyor (Android'deki gibi).
        paragraflar: ((json['paragraf'] as List?) ?? const []).whereType<String>().toList(),
      );

  static const adBreakMarker = '__AD_BREAK__';
}
