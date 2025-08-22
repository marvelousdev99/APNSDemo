import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
	private var menuBarController: MenuBarController?
	private let notificationCenter = UNUserNotificationCenter.current()
	private let userDefaults = UserDefaults.standard

	func applicationDidFinishLaunching(_ notification: Notification) {
		NSApp.setActivationPolicy(.accessory)

		menuBarController = MenuBarController()

		notificationCenter.delegate = self
		requestNotificationAuthorization()
		NSApplication.shared.registerForRemoteNotifications()
	}

	private func requestNotificationAuthorization() {
		let options: UNAuthorizationOptions = [.alert, .badge, .sound]
		notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
			if let error = error {
				print("[Notifications] Authorization error: \(error)")
			}
			print("[Notifications] Authorization granted: \(granted)")
		}
	}

	func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
		print("[APNs] Device token: \(tokenString)")
		userDefaults.set(tokenString, forKey: "apnsDeviceToken")
	}

	func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print("[APNs] Failed to register: \(error)")
	}

	func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
		print("[APNs] Received remote notification: \(userInfo)")

		let content = UNMutableNotificationContent()
		content.title = (userInfo["aps"] as? [String: Any])?["alert"] as? String ?? "Push Notification"
		content.body = (userInfo["message"] as? String) ?? ""
		content.sound = .default

		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
		notificationCenter.add(request) { error in
			if let error = error { print("[Notifications] Failed to show: \(error)") }
		}
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.banner, .sound, .badge, .list])
	}

	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		completionHandler()
	}
} 