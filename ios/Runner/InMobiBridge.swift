import Foundation
import Flutter
import UIKit
import InMobiSDK

/// Bağımsız (standalone) InMobi köprüsü — GEÇİŞ (interstitial) + ÖDÜL (rewarded).
/// InMobi iOS'ta ödüllü de `IMInterstitial` ile servis edilir; ödül
/// `interstitial(_:rewardActionCompletedWithRewards:)` ile bildirilir.
/// MethodChannel adı: "tinetv/inmobi".
class InMobiBridge: NSObject {
    private let channel: FlutterMethodChannel
    private var inited = false

    private var interstitial: IMInterstitial?
    private var rewarded: IMInterstitial?
    private var rewardEarned = false

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "tinetv/inmobi", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result)
        }
    }

    private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        switch call.method {
        case "init":
            ensureInit((args?["accountId"] as? String) ?? "")
            result(true)
        case "loadInterstitial":
            loadInterstitial(int64(args?["placementId"]))
            result(nil)
        case "isInterstitialReady":
            result(interstitial?.isReady() ?? false)
        case "showInterstitial":
            result(showInterstitial())
        case "loadRewarded":
            loadRewarded(int64(args?["placementId"]))
            result(nil)
        case "isRewardedReady":
            result(rewarded?.isReady() ?? false)
        case "showRewarded":
            result(showRewarded())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func int64(_ v: Any?) -> Int64 {
        if let n = v as? NSNumber { return n.int64Value }
        if let s = v as? String, let n = Int64(s) { return n }
        return 0
    }

    private func ensureInit(_ accountId: String) {
        if inited || accountId.isEmpty { return }
        IMSdk.initWithAccountID(accountId, consentDictionary: [:], andCompletionHandler: { _ in })
        inited = true
    }

    /// En üstteki görünür view controller (reklamı sunmak için).
    private func topVC() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow })
            ?? scenes.first?.windows.first
        var vc = window?.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }

    // ── GEÇİŞ (interstitial) ──────────────────────────────────────────────────
    private func loadInterstitial(_ pid: Int64) {
        if !inited || pid == 0 { return }
        let ad = IMInterstitial(placementId: pid)
        ad.delegate = self
        interstitial = ad
        ad.load()
    }

    private func showInterstitial() -> Bool {
        guard let ad = interstitial, ad.isReady(), let vc = topVC() else { return false }
        ad.show(from: vc)
        return true
    }

    // ── ÖDÜL (rewarded = IMInterstitial + ödül callback) ──────────────────────
    private func loadRewarded(_ pid: Int64) {
        if !inited || pid == 0 { return }
        let ad = IMInterstitial(placementId: pid)
        ad.delegate = self
        rewarded = ad
        rewardEarned = false
        ad.load()
    }

    private func showRewarded() -> Bool {
        guard let ad = rewarded, ad.isReady(), let vc = topVC() else { return false }
        rewardEarned = false
        ad.show(from: vc)
        return true
    }
}

extension InMobiBridge: IMInterstitialDelegate {
    func interstitialDidFinishLoading(_ ad: IMInterstitial) {
        channel.invokeMethod(ad === rewarded ? "onRewardedLoaded" : "onInterstitialLoaded", arguments: nil)
    }

    func interstitial(_ ad: IMInterstitial, didFailToLoadWithError error: IMRequestStatus) {
        channel.invokeMethod(ad === rewarded ? "onRewardedFailed" : "onInterstitialFailed",
                             arguments: error.localizedDescription)
    }

    func interstitial(_ ad: IMInterstitial, rewardActionCompletedWithRewards rewards: [AnyHashable: Any]) {
        rewardEarned = true
        channel.invokeMethod("onRewardEarned", arguments: nil)
    }

    func interstitialDidDismiss(_ ad: IMInterstitial) {
        if ad === rewarded {
            channel.invokeMethod("onRewardedDismissed", arguments: rewardEarned)
        } else {
            channel.invokeMethod("onInterstitialDismissed", arguments: nil)
        }
    }

    func interstitial(_ ad: IMInterstitial, didFailToPresentWithError error: IMRequestStatus) {
        channel.invokeMethod(ad === rewarded ? "onRewardedDismissed" : "onInterstitialDismissed",
                             arguments: ad === rewarded ? rewardEarned : nil)
    }
}
