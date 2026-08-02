import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    silenceSystemKeyboardConstraintLogs()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Silences UIKit's "Unable to simultaneously satisfy constraints" console spam.
  ///
  /// The only Auto Layout in this process belongs to Apple: TextInputUI (the `TUI*`
  /// classes) loads into the app and lays out the system keyboard's candidate /
  /// QuickType bar. It ships with a broken constraint set — a `TUIPredictionViewCell`
  /// whose width is 0 while its `TUICandidateGradientContentLabel` is pinned 6pt from
  /// both edges — so every keyboard presentation logs several unsatisfiable-constraint
  /// blocks (ISA-40: opening the caption editor from a selected scene). Every widget
  /// this app draws is a Flutter layer, not a `UIView` with constraints, so there is
  /// nothing on our side to fix and nothing of ours to lose by muting the log.
  ///
  /// `_UIConstraintBasedLayoutLogUnsatisfiable` is the flag UIKit itself checks before
  /// logging. It is read from `NSUserDefaults`, so `NSArgumentDomain` still outranks
  /// what we write here: pass `-_UIConstraintBasedLayoutLogUnsatisfiable YES` in the
  /// Xcode scheme's launch arguments to get the logs back while debugging a native
  /// plugin's own constraints.
  ///
  /// Debug-only, so release builds keep stock UIKit diagnostics and the App Store
  /// binary contains no reference to a private default.
  private func silenceSystemKeyboardConstraintLogs() {
    #if DEBUG
      UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    #endif
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
