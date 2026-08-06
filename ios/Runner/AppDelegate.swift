import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  var inmobiBridge: InMobiBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Bağımsız InMobi köprüsü (native SDK ↔ Flutter).
    if let controller = window?.rootViewController as? FlutterViewController {
      inmobiBridge = InMobiBridge(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
