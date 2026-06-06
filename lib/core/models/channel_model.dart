class Channel {
  final String name;
  final String url;
  final String? logo;
  final String? group;
  final String? tvgId;

  Channel({
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.tvgId,
  });
}
