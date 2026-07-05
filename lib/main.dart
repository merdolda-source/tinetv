import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'firebase_options.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/ad_free_service.dart';
import 'core/services/progress_service.dart';
import 'features/main_nav/main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await AdFreeService().initialize();
  await ProgressService.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await RemoteConfigService().initialize();

  // ATT izni iste
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await Future.delayed(const Duration(milliseconds: 500));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  await AdService().gatherConsent();
  await AdService().initialize();

  runApp(const TineTVApp());
}

class TineTVApp extends StatefulWidget {
  const TineTVApp({super.key});

  @override
  State<TineTVApp> createState() => _TineTVAppState();
}

class _TineTVAppState extends State<TineTVApp> with WidgetsBindingObserver {
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sadece arka plandan dönüşte gösterilir — soğuk açılışta asla değil.
    if (state == AppLifecycleState.paused) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      AdService().showAppOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TİNE TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE50914),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const MainNavScreen(),
    );
  }
}
