import 'dart:async';
import 'package:get/get.dart';
import '../../core/models/canliskor_model.dart';
import '../../core/services/canliskor_service.dart';
import '../../core/services/remote_config_service.dart';

class CanliskorController extends GetxController {
  final _service = CanliskorService();

  final tumTurnuvalar = <TurnuvaVeri>[].obs;
  final isLoading = true.obs;
  final aktifFiltre = 'tumu'.obs; // tumu | canli | bitti | baslamadi

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _fetch();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _fetch() async {
    final result = await _service.fetchList();
    tumTurnuvalar.value = result;
    isLoading.value = false;
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final ms = RemoteConfigService().canliSkorRefreshMs;
    _timer = Timer(Duration(milliseconds: ms > 0 ? ms : 1000), _fetch);
  }

  void selectFiltre(String filtre) {
    aktifFiltre.value = filtre;
  }

  void refreshNow() {
    _fetch();
  }

  List<TurnuvaVeri> get filtrelenmisListe {
    if (aktifFiltre.value == 'tumu') return tumTurnuvalar;
    final sonuc = <TurnuvaVeri>[];
    for (final t in tumTurnuvalar) {
      final maclar = t.maclar.where((m) => m.durum == aktifFiltre.value).toList();
      if (maclar.isNotEmpty) {
        sonuc.add(TurnuvaVeri(ad: t.ad, ulke: t.ulke, bayrak: t.bayrak, maclar: maclar));
      }
    }
    return sonuc;
  }

  void pause() => _timer?.cancel();
  void resume() => _scheduleNext();
}
