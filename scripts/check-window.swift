import AppKit

let deadline = Date().addingTimeInterval(30)
var foundWindow = false
while Date() < deadline {
  let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "ai.antiburn.desktop")
  guard
    let windows =
      CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]]
  else {
    fatalError("macOS did not return its window list")
  }
  foundWindow = windows.contains { window in
    guard let pid = window[kCGWindowOwnerPID as String] as? pid_t,
      apps.contains(where: { $0.processIdentifier == pid }),
      let layer = window[kCGWindowLayer as String] as? Int,
      layer == 0,
      let bounds = window[kCGWindowBounds as String] as? [String: Double],
      let width = bounds["Width"], let height = bounds["Height"]
    else {
      return false
    }
    return width > 100 && height > 100
  }
  if foundWindow { break }
  Thread.sleep(forTimeInterval: 1)
}
guard foundWindow else {
  fatalError("antiburn did not display an application window")
}
print("antiburn displayed an application window")
