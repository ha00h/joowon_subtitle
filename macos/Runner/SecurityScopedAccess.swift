import Cocoa
import FlutterMacOS

class SecurityScopedAccessPlugin: NSObject, FlutterPlugin {
  private var accessedUrls: [String: URL] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "joowon_subtitle/security_scoped_access",
      binaryMessenger: registrar.messenger
    )
    let instance = SecurityScopedAccessPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickDirectory":
      pickDirectory(call, result: result)
    case "restoreBookmark":
      restoreBookmark(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickDirectory(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let dialog = NSOpenPanel()
    if let initial = args?["initialDirectory"] as? String, !initial.isEmpty {
      dialog.directoryURL = URL(fileURLWithPath: initial)
    }
    dialog.canChooseDirectories = true
    dialog.canChooseFiles = false
    dialog.allowsMultipleSelection = false
    dialog.title = "찬양 작업 폴더 선택"

    guard let window = NSApp.keyWindow ?? NSApp.windows.first else {
      result(nil)
      return
    }

    dialog.beginSheetModal(for: window) { response in
      guard response == .OK, let url = dialog.url else {
        result(nil)
        return
      }
      result(self.makePickResult(url: url))
    }
  }

  private func restoreBookmark(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let bookmark = args["bookmark"] as? String else {
      result(nil)
      return
    }
    result(resolveBookmark(bookmark))
  }

  private func makePickResult(url: URL) -> [String: String] {
    let bookmark = createBookmark(url: url) ?? ""
    _ = url.startAccessingSecurityScopedResource()
    accessedUrls[url.path] = url
    return ["path": url.path, "bookmark": bookmark]
  }

  private func createBookmark(url: URL) -> String? {
    do {
      let data = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      return data.base64EncodedString()
    } catch {
      return nil
    }
  }

  private func resolveBookmark(_ base64: String) -> String? {
    guard let data = Data(base64Encoded: base64) else { return nil }
    var isStale = false
    do {
      let url = try URL(
        resolvingBookmarkData: data,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      guard url.startAccessingSecurityScopedResource() else { return nil }
      accessedUrls[url.path] = url
      return url.path
    } catch {
      return nil
    }
  }
}
