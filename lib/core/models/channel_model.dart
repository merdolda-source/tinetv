class Channel {
  final String name;
  final String url;
  final String? logo;
  final String? group;
  final String? tvgId;
  // Android PlayerActivity paritesi: #EXTVLCOPT'ten gelen oynatma başlıkları.
  // Çoğu korsan/CDN yayını Referer/Origin/User-Agent olmadan 403 döner.
  final String? referer;
  final String? origin;
  final String? userAgent;

  Channel({
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.tvgId,
    this.referer,
    this.origin,
    this.userAgent,
  });
}
