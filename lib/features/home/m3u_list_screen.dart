import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/channel_model.dart';
import '../../core/services/m3u_service.dart';
import '../channel_detail/channel_detail_screen.dart';

/// Belirli bir M3U URL'sini (content_json'daki type=m3u kaynağı) açıp kanal
/// listesi gösterir. Ana Sayfa'daki M3U ekranıyla aynı görünüm; ama bu ekran
/// RC'den gelen ADRESE bağlıdır (kullanıcı girişi değil).
class M3uListScreen extends StatefulWidget {
  final String title;
  final String url;
  const M3uListScreen({super.key, required this.title, required this.url});

  @override
  State<M3uListScreen> createState() => _M3uListScreenState();
}

class _M3uListScreenState extends State<M3uListScreen> {
  final _service = M3uService();
  List<Channel> _all = [];
  List<Channel> _filtered = [];
  List<String> _cats = ['Tümü'];
  String _cat = 'Tümü';
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.fetchChannels(widget.url);
    if (!mounted) return;
    final groups = result.map((c) => c.group ?? 'Diğer').toSet().toList();
    setState(() {
      _all = result;
      _cats = ['Tümü', ...groups];
      _filtered = result;
      _loading = false;
    });
  }

  void _apply() {
    var r = _all.toList();
    if (_cat != 'Tümü') r = r.where((c) => (c.group ?? 'Diğer') == _cat).toList();
    if (_query.isNotEmpty) {
      r = r.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    setState(() => _filtered = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(widget.title,
            style: const TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _all.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Kanal bulunamadı', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _load, child: const Text('Yenile')),
                  ]),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: TextField(
                        onChanged: (v) { _query = v; _apply(); },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Kanal ara...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _cats.length,
                        itemBuilder: (context, i) {
                          final cat = _cats[i];
                          final sel = cat == _cat;
                          return GestureDetector(
                            onTap: () { _cat = cat; _apply(); },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFFE50914) : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                      color: sel ? Colors.white : Colors.grey,
                                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('Kanal bulunamadı', style: TextStyle(color: Colors.grey)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 16 / 9,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final channel = _filtered[index];
                                return GestureDetector(
                                  onTap: () => Get.to(() => ChannelDetailScreen(channel: channel)),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (channel.logo != null)
                                          CachedNetworkImage(
                                            imageUrl: channel.logo!,
                                            height: 48,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.tv, color: Colors.grey, size: 40),
                                          )
                                        else
                                          const Icon(Icons.tv, color: Colors.grey, size: 40),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(channel.name,
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
