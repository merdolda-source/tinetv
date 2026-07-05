import 'package:get/get.dart';
import '../../core/models/haber_model.dart';
import '../../core/services/haber_service.dart';

class HaberlerController extends GetxController {
  final _service = HaberService();

  final haberler = <HaberOzet>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final result = await _service.fetchList();
    haberler.value = result;
    isLoading.value = false;
  }
}
