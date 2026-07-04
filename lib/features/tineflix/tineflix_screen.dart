import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'tineflix_controller.dart';
import 'tineflix_detail_screen.dart';
import '../../core/models/series_model.dart';

class TineflixScreen extends StatefulWidget {
  const TineflixScreen({super.key});

  @override
  State<TineflixScreen> createState() => _TineflixScreenState();
}

class _TineflixScreenState extends State<TineflixScreen> {
  final _scrollController = ScrollController();
  late final TineflixController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TineflixController());
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300) {
        controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'TİNEFLİX',
          style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              onChanged: controller.search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Dizi ara...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip('TR', controller.selectedLang.value == 'TR' && !controller.dublajOnly.value,
                        () => controller.selectLang('TR')),
                    _chip('EN', controller.selectedLang.value == 'EN' && !controller.dublajOnly.value,
                        () => controller.selectLang('EN')),
                    _chip('🎙️ Türkçe Dublaj', controller.dublajOnly.value, controller.toggleDublaj),
                  ],
                )),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE50914)),
                );
              }
              if (controller.seriesList.isEmpty) {
                return const Center(
                  child: Text('Dizi bulunamadı', style: TextStyle(color: Colors.grey)),
                );
              }
              return GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: controller.seriesList.length + (controller.isLoadingMore.value ? 3 : 0),
                itemBuilder: (context, index) {
                  if (index >= controller.seriesList.length) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE50914),
                        strokeWidth: 2,
                      ),
                    );
                  }
                  return _SeriesCard(series: controller.seriesList[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
  }
}

class _SeriesCard extends StatelessWidget {
  final Series series;
  const _SeriesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => TineflixDetailScreen(slug: series.slug)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (series.coverImage.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: series.coverImage,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.movie, color: Colors.grey, size: 36),
                    )
                  else
                    const Icon(Icons.movie, color: Colors.grey, size: 36),
                  if (series.isDubbed)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('🎙️ TR',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${series.totalEpisodes} Bölüm',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                series.title,
                style: const TextStyle(color: Colors.white, fontSize: 11.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
