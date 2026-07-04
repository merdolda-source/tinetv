import 'dart:async';
import 'package:get/get.dart';
import '../../core/models/series_model.dart';
import '../../core/services/dramaflix_service.dart';

class TineflixController extends GetxController {
  final _service = DramaflixService();

  final seriesList = <Series>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final selectedLang = 'TR'.obs; // 'TR' | 'EN'
  final dublajOnly = false.obs;
  final searchQuery = ''.obs;

  Timer? _debounce;
  int _offset = 0;
  static const _pageSize = 24;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> loadInitial() async {
    isLoading.value = true;
    _offset = 0;
    _hasMore = true;
    final result = await _fetch(offset: 0);
    seriesList.value = result;
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    _offset += _pageSize;
    final result = await _fetch(offset: _offset);
    if (result.isEmpty) _hasMore = false;
    seriesList.addAll(result);
    isLoadingMore.value = false;
  }

  Future<List<Series>> _fetch({required int offset}) {
    return _service.fetchSeries(
      lang: selectedLang.value,
      search: dublajOnly.value
          ? 'dublaj'
          : (searchQuery.value.isEmpty ? null : searchQuery.value),
      limit: _pageSize,
      offset: offset,
    );
  }

  void selectLang(String lang) {
    if (selectedLang.value == lang) return;
    selectedLang.value = lang;
    loadInitial();
  }

  void toggleDublaj() {
    dublajOnly.value = !dublajOnly.value;
    loadInitial();
  }

  // Arama her harfte ağ isteği atmasın diye 400ms bekletilir — anında
  // tuşa-tuşa gitmek yerine yazma bitince tek seferde sonuç getirir.
  void search(String query) {
    searchQuery.value = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadInitial);
  }
}
