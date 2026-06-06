import 'package:get/get.dart';
import '../../core/models/channel_model.dart';
import '../../core/services/m3u_service.dart';


class HomeController extends GetxController {
  final _m3uService = M3uService();
  

  final channels = <Channel>[].obs;
  final filteredChannels = <Channel>[].obs;
  final categories = <String>[].obs;
  final selectedCategory = 'Tümü'.obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadChannels();
  }

  Future<void> loadChannels() async {
    isLoading.value = true;
    final result = await _m3uService.fetchChannels();
    channels.value = result;

    final groups = result.map((c) => c.group ?? 'Diğer').toSet().toList();
    categories.value = ['Tümü', ...groups];

    filteredChannels.value = result;
    isLoading.value = false;
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void search(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void _applyFilters() {
    var result = channels.toList();

    if (selectedCategory.value != 'Tümü') {
      result = result
          .where((c) => (c.group ?? 'Diğer') == selectedCategory.value)
          .toList();
    }

    if (searchQuery.value.isNotEmpty) {
      result = result
          .where(
            (c) =>
                c.name.toLowerCase().contains(searchQuery.value.toLowerCase()),
          )
          .toList();
    }

    filteredChannels.value = result;
  }
}
