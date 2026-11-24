import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(name: "mihrab/widgets", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "publish" else { result(FlutterMethodNotImplemented); return }
      guard let raw = call.arguments as? String, let data = raw.data(using: .utf8), data.count <= 65536,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            json["version"] as? Int == 1,
            let days = json["days"] as? [[String: Any]], (1...7).contains(days.count),
            let defaults = UserDefaults(suiteName: "group.kz.zeus.mihrab.widgets"),
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.kz.zeus.mihrab.widgets") != nil else {
        result(FlutterError(code: "widget_publish_failed", message: "App Group unavailable or invalid snapshot", details: nil))
        return
      }
      defaults.set(raw, forKey: "snapshot")
      WidgetCenter.shared.reloadTimelines(ofKind: "MihrabPrayerWidget")
      result(nil)
    }
  }
}
