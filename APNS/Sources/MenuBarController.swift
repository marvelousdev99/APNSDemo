import AppKit

final class MenuBarController {
	private let statusItem: NSStatusItem
	private let userDefaults = UserDefaults.standard

	init() {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		statusItem.button?.title = "APNS"
		statusItem.menu = buildMenu()
	}

	private func buildMenu() -> NSMenu {
		let menu = NSMenu()
		menu.addItem(NSMenuItem(title: "Copy Device Token", action: #selector(copyToken), keyEquivalent: "t"))
		menu.addItem(.separator())
		menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
		menu.items.forEach { $0.target = self }
		return menu
	}

	@objc private func copyToken() {
		let token = userDefaults.string(forKey: "apnsDeviceToken") ?? "No token yet"
		NSPasteboard.general.clearContents()
		NSPasteboard.general.setString(token, forType: .string)
	}

	@objc private func quit() {
		NSApp.terminate(nil)
	}
} 