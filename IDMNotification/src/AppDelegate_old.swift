import AppKit
import UserNotifications

final class AppDelegate2: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate
{
    
    private let logger = LoggerFactory.make()
    private var reRegTimer: Timer?
    private var activityToken: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent App Nap and idle system sleep for this process
        let opts: ProcessInfo.ActivityOptions = [
            .background, .idleSystemSleepDisabled,
            .userInitiatedAllowingIdleSystemSleep,
        ]
        let token = ProcessInfo.processInfo.beginActivity(options: opts, reason: "APNs listener")
        self.activityToken = token as NSObjectProtocol
        
        UNUserNotificationCenter.current().delegate = self
        
        logger.info("App launched → requesting notification authorization...")
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) { granted, err in
            if let err = err {
                self.logger.info("Authorization error: \(err.localizedDescription)")
                return
            }
            guard granted else {
                self.logger.warning("Notification authorization denied by user")
                return
            }
            self.logger.info("Notification authorization granted")
            
            DispatchQueue.main.async {
                self.registerForAPNs()
                
                // Periodic re-registration to keep APNs channel fresh (every 4h)
                self.reRegTimer?.invalidate()
                self.reRegTimer = Timer.scheduledTimer(
                    withTimeInterval: 4 * 60 * 60, repeats: true
                ) { _ in
                    self.refreshAPNsRegistration()
                }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token as! NSObject)
        }
        logger.info("Application will terminate")
    }
    
    // MARK: APNs Registration
    
    private func registerForAPNs() {
        logger.info("Registering for remote notifications…")
        NSApplication.shared.registerForRemoteNotifications()
    }
    
    private func refreshAPNsRegistration() {
        logger.info("Forcing APNs re-registration…")
        NSApplication.shared.unregisterForRemoteNotifications()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.registerForAPNs()
        }
    }
    
    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        logger.info("APNs token registered: \(token)")
        
        
        
        // TODO: send token to your backend
        // sendTokenToBackend(token)
    }
    
    func application(
        _ application: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("Failed to register for remote notifications:\(error.localizedDescription)")
        refreshAPNsRegistration()
    }
    
    // MARK: Notification Handling
    
    // Foreground notifications (you can customize presentation options)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        let content = notification.request.content
        logger.info("Foreground notification: \(content)")
        completionHandler([.banner, .badge, .sound])
    }
    
    // Clicked notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        logger.info("User clicked notification: \(content)")
        completionHandler()
    }
    
    // Silent/background notifications (requires correct payload from server)
    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        logger.info("Background/silent notification: \(userInfo)")
        
        if let aps = userInfo["aps"] as? [String: Any],
           let contentAvailable = aps["content-available"] as? Int,
           contentAvailable == 1
        {
            
            // Handle background operations
            handleBackgroundOperation(userInfo)
            
        } else if let aps = userInfo["aps"] as? [String: Any],
                  let alert = aps["alert"] as? [String: Any]
        {
            
            // This is a regular notification with alert content
            let title = alert["title"] as? String ?? ""
            let subtitle = alert["subtitle"] as? String ?? ""
            let body = alert["body"] as? String ?? ""
            
            logger.info(
                "Processing notification with alert - Title: \(title), Body: \(body)"
            )
            //showLocalNotification(title: title, subtitle: subtitle, body: body, iconName: "" )
            
        }
        
    }
    
    private func handleBackgroundOperation(_ userInfo: [String: Any]) {
        guard let data = userInfo["data"] as? [String: Any] else {
            logger.info("No data in background notification")
            return
        }
        
        let message = data["message"] as? String ?? ""
        let type = data["type"] as? String ?? ""
        let user = data["user"] as? String ?? ""
        
        logger.info(
            "Processing background operation - Type: \(type), Message: \(message), User: \(user)"
        )
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Applications/idemeum MFA.app/Contents/MacOS/idemeum MFA")
        process.arguments = [type]
        
        do{
            try process.run()
            process.waitUntilExit()
        } catch (let error){
            logger.error("Error running process: \(error)")
        }
    }
    
    private func showLocalNotification(title: String, subtitle: String? = nil, body: String, iconName: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        content.body = body
        content.sound = .default
        
        // Set custom icon if provided
        if let iconName = iconName,
           let iconURL = Bundle.main.url(forResource: iconName, withExtension: "png") {
            do {
                let attachment = try UNNotificationAttachment(identifier: "icon", url: iconURL , options: nil)
                content.attachments = [attachment]
            } catch {
                logger.info("Failed to attach icon: \(error.localizedDescription)")
            }
        }
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.info("Failed to show local notification: \(error.localizedDescription)")
            } else {
                self.logger.info("Local notification shown: \(title)")
            }
        }
    }
}
