import 'package:get/get.dart';
import '../../core/models/film_model.dart';
import '../../core/services/film_service.dart';

class FilmController extends GetxController {
  final _service = FilmService();

  final films = <Film>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;

  int _page = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    isLoading.value = true;
    _page = 1;
    _hasMore = true;
    final result = await _service.fetchFilms(page: _page);
    films.value = result;
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    _page++;
    final result = await _service.fetchFilms(page: _page);
    if (result.isEmpty) _hasMore = false;
    films.addAll(result);
    isLoadingMore.value = false;
  }
}
