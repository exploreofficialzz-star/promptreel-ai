import UIKit
import Flutter
import GoogleMobileAds

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ── AdMob Initialize ──────────────────────────────────────────────────
    GADMobileAds.sharedInstance().start(completionHandler: nil)

    // ── Flutter Engine ────────────────────────────────────────────────────
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ── Universal Links ───────────────────────────────────────────────────────
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  // ── Custom URL Scheme Deep Links ──────────────────────────────────────────
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
