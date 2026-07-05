import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'film_controller.dart';
import '../../core/models/film_model.dart';
import '../../core/models/site_model.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/widgets/native_ad_card.dart';
import '../sites/site_webview_screen.dart';

const _crossAxisCount = 3;
const _childAspectRatio = 0.6;

// Film posterleri (dikey/kare kart) ile native reklam (yatay küçük şablon)
// birbirine uymadığı için, reklamı tek bir hücreye sıkıştırmak yerine N
// filmde bir tam genişlikte ayrı bir satır olarak araya sokuyoruz — bu
// yüzden liste "SliverGrid parçaları + arada SliverToBoxAdapter" şeklinde
// bölünüyor.
List<Widget> _sliversOlustur(List<Film> films, bool loadingMore) {
  final aralik = RemoteConfigService().gridNativeAdInterval;
  final slivers = <Widget>[];

  if (aralik <= 0) {
    slivers.add(SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          childAspectRatio: _childAspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _FilmCard(film: films[index]),
          childCount: films.length,
        ),
      ),
    ));
  } else {
    for (var start = 0; start < films.length; start += aralik) {
      final end = (start + aralik < films.length) ? start + aralik : films.length;
      final parca = films.sublist(start, end);
      slivers.add(SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount,
            childAspectRatio: _childAspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _FilmCard(film: parca[index]),
            childCount: parca.length,
          ),
        ),
      ));
      if (end < films.length) {
        slivers.add(const SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
          sliver: SliverToBoxAdapter(child: NativeAdCard()),
        ));
      }
    }
  }

  slivers.add(SliverPadding(
    padding: const EdgeInsets.all(12),
    sliver: SliverToBoxAdapter(
      child: loadingMore
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914), strokeWidth: 2))
          : const SizedBox.shrink(),
    ),
  ));

  return slivers;
}

class FilmScreen extends StatefulWidget {
  const FilmScreen({super.key});

  @override
  State<FilmScreen> createState() => _FilmScreenState();
}

class _FilmScreenState extends State<FilmScreen> {
  final _scrollController = ScrollController();
  late final FilmController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FilmController());
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
          'FİLMLER',
          style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }
        if (controller.films.isEmpty) {
          return const Center(
            child: Text('Film bulunamadı', style: TextStyle(color: Colors.grey)),
          );
        }
        return CustomScrollView(
          controller: _scrollController,
          slivers: _sliversOlustur(controller.films, controller.isLoadingMore.value),
        );
      }),
    );
  }
}

class _FilmCard extends StatelessWidget {
  final Film film;
  const _FilmCard({required this.film});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => SiteWebviewScreen(
            site: SiteEntry(title: film.title, url: film.url),
          )),
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
                  if (film.poster.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: film.poster,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.movie, color: Colors.grey, size: 36),
                    )
                  else
                    const Icon(Icons.movie, color: Colors.grey, size: 36),
                  if (film.quality.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(film.quality,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (film.imdb.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('⭐ ${film.imdb}',
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                film.year.isNotEmpty ? '${film.title} (${film.year})' : film.title,
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
