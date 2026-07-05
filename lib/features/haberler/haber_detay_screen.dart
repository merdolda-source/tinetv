import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/haber_model.dart';
import '../../core/services/haber_service.dart';
import '../../core/widgets/native_ad_card.dart';

class HaberDetayScreen extends StatefulWidget {
  final HaberOzet haber;
  const HaberDetayScreen({super.key, required this.haber});

  @override
  State<HaberDetayScreen> createState() => _HaberDetayScreenState();
}

class _HaberDetayScreenState extends State<HaberDetayScreen> {
  final _service = HaberService();
  HaberDetay? _detay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _service.fetchDetail(widget.haber.detayPath);
    if (!mounted) return;
    setState(() {
      _detay = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _detay == null
              ? _hataGoster()
              : _icerikGoster(_detay!),
    );
  }

  Widget _hataGoster() {
    return Stack(
      children: [
        Positioned(
          top: 40,
          left: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const Center(
          child: Text('Haber içeriği yüklenemedi.', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _icerikGoster(HaberDetay detay) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          expandedHeight: 220,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: detay.gorsel.isNotEmpty
                ? CachedNetworkImage(imageUrl: detay.gorsel, fit: BoxFit.cover)
                : Container(color: const Color(0xFF1A1A1A)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detay.baslik,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                for (final p in detay.paragraflar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: p == HaberDetay.adBreakMarker
                        ? const NativeAdCard()
                        : Text(
                            p,
                            style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.5),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
