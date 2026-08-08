/// Premium spor (Boss / Patron-Taraftarium / genel premium) tek tip öğe.
/// Android'deki `HashMap<String,String>` kanal öğesinin birebir karşılığı.
///
///  - [mediaUrl]      : resolver endpoint'i VEYA doğrudan m3u8 (oynatıcı çözer/oynatır)
///  - [embedUrl]      : resolver/m3u8 tutmazsa düşülecek webview embed'i (yedek)
///  - [directEmbedUrl]: doldurulmuşsa resolver ATLANIR, doğrudan webview açılır (embedOnly)
///  - [referer]/[origin]/[userAgent] : CDN'in beklediği başlıklar
///  - [sport]         : YALNIZCA maçlarda doldurulur (kanal ise boş). Futbol filtresi bunu kullanır.
class PremiumItem {
  final String title;
  final String mediaUrl;
  final String embedUrl;
  final String directEmbedUrl;
  final String thumb;
  final String referer;
  final String origin;
  final String userAgent;
  final String group;
  final String sport;
  // Zeus maçı: media_url boş gelir; tıklamada bu uçtan m3u8 çözülür (ZeusSource
  // .resolveMatch). Kanal/diğer kaynaklarda boştur.
  final String zeusMatchUrl;
  final String zeusCdn;

  const PremiumItem({
    required this.title,
    this.mediaUrl = '',
    this.embedUrl = '',
    this.directEmbedUrl = '',
    this.thumb = '',
    this.referer = '',
    this.origin = '',
    this.userAgent = '',
    this.group = '',
    this.sport = '',
    this.zeusMatchUrl = '',
    this.zeusCdn = '',
  });

  PremiumItem copyWith({
    String? mediaUrl,
    String? referer,
    String? origin,
    String? userAgent,
  }) =>
      PremiumItem(
        title: title,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        embedUrl: embedUrl,
        directEmbedUrl: directEmbedUrl,
        thumb: thumb,
        referer: referer ?? this.referer,
        origin: origin ?? this.origin,
        userAgent: userAgent ?? this.userAgent,
        group: group,
        sport: sport,
      );
}

/// Oynatıcıya verilecek çözülmüş kaynak: gerçek stream + HTTP başlıkları.
class PlayResource {
  final String url;
  final Map<String, String> headers;
  const PlayResource(this.url, this.headers);
}
