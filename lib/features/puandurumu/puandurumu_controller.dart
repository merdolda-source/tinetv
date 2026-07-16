import 'package:get/get.dart';
import '../../core/models/puanlig_model.dart';
import '../../core/services/puanlig_service.dart';

class PuandurumuController extends GetxController {
  final _service = PuanligService();

  final veri = Rxn<PuanDurumuVeri>();
  final isLoading = true.obs;
  final aktifLig = ''.obs;
  final aktifSekme = 'genel'.obs; // genel | icSaha | disSaha

  // ── Fikstür (Android'deki dual-tab: Puan Durumu / Fikstür) ────────────────
  final anaSekme = 'puan'.obs; // puan | fikstur
  final fikstur = Rxn<FiksturVeri>();
  final fiksturLoading = false.obs;
  final aktifHafta = 0.obs; // 0 = sunucudan güncel hafta

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
    // Lig değişince fikstür haftası da değişebilir → sıfırla, güncel haftayı al.
    aktifHafta.value = 0;
    fikstur.value = null;
    load(lig: key);
    if (anaSekme.value == 'fikstur') loadFikstur();
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

  // ── Fikstür işlemleri ─────────────────────────────────────────────────────
  void selectAnaSekme(String s) {
    if (anaSekme.value == s) return;
    anaSekme.value = s;
    if (s == 'fikstur' && fikstur.value == null) loadFikstur();
  }

  Future<void> loadFikstur({int? hafta}) async {
    fiksturLoading.value = true;
    final result = await _service.fetchFikstur(
      lig: aktifLig.value.isNotEmpty ? aktifLig.value : null,
      hafta: hafta ?? aktifHafta.value,
    );
    if (result != null) {
      fikstur.value = result;
      aktifHafta.value = result.hafta;
    }
    fiksturLoading.value = false;
  }

  void selectHafta(int h) {
    if (h == aktifHafta.value) return;
    aktifHafta.value = h;
    loadFikstur(hafta: h);
  }
}
