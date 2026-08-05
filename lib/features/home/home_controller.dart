import 'package:get/get.dart';
import 'package:flutter/material.dart';
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
  final currentUrl = ''.obs;
  final hasUrl = false.obs;

  final urlController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    // Android paritesi: Ana ekran artık m3u_playlists / premium_sites kartları
    // üzerinden çalışır. Tek m3u_url (varsa) _buildHome içinde kart olur.
    // Otomatik kanal yüklemesi YOK — hiçbir modda ekranı devralmaz.
    //   login=true  → _buildUrlInputScreen (formalite); link girilince kanal listesi.
    //   login=false → _buildHome (Android liste yapısı); ASLA giriş ekranı yok.
    isLoading.value = false;
    hasUrl.value = false;
  }

  Future<void> loadFromUserUrl(String url) async {
    if (url.trim().isEmpty) return;
    currentUrl.value = url.trim();
    hasUrl.value = true;
    await loadChannels(url.trim());
  }

  Future<void> loadChannels(String url) async {
    isLoading.value = true;
    final result = await _m3uService.fetchChannels(url);
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

  void clearUrl() {
    currentUrl.value = '';
    hasUrl.value = false;
    channels.clear();
    filteredChannels.clear();
    categories.clear();
    urlController.clear();
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

  @override
  void onClose() {
    urlController.dispose();
    super.onClose();
  }
}
