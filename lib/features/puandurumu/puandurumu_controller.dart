import 'package:get/get.dart';
import '../../core/models/puanlig_model.dart';
import '../../core/services/puanlig_service.dart';

class PuandurumuController extends GetxController {
  final _service = PuanligService();

  final veri = Rxn<PuanDurumuVeri>();
  final isLoading = true.obs;
  final aktifLig = ''.obs;
  final aktifSekme = 'genel'.obs; // genel | icSaha | disSaha

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({String? lig}) async {
    isLoading.value = true;
    final result = await _service.fetch(lig: lig);
    veri.value = result;
    if (result != null && result.ligler.isNotEmpty && aktifLig.value.isEmpty) {
      aktifLig.value = lig ?? result.ligler.first.key;
    }
    isLoading.value = false;
  }

  void selectLig(String key) {
    if (aktifLig.value == key) return;
    aktifLig.value = key;
    load(lig: key);
  }

  void selectSekme(String sekme) {
    aktifSekme.value = sekme;
  }

  List<PuanSatiri> get aktifListe {
    final v = veri.value;
    if (v == null) return [];
    switch (aktifSekme.value) {
      case 'icSaha':
        return v.icSaha;
      case 'disSaha':
        return v.disSaha;
      default:
        return v.genel;
    }
  }
}
