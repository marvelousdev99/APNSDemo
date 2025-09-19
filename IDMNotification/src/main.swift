import AppKit

let app = NSApplication.shared

// Hide Dock icon / menu bar (UIElement app) – keep it headless
NSApp.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
