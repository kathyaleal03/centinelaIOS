import Foundation
import UserNotifications
import UIKit

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() { super.init() }

    func requestAuthorizationAndRegister() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("[NotificationManager] permiso otorgado para notificaciones remotas")
                } else {
                    print("[NotificationManager] permiso denegado: \(error?.localizedDescription ?? "sin error")")
                }
            }
        }
    }

    // Called when a notification is delivered while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Helper to send device token to backend
    func sendDeviceTokenToServer(_ token: Data, userId: Int?) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        print("[NotificationManager] device token hex: \(tokenString)")
        // Send to backend so it can push notifications later
        Task {
            do {
                try await APIService.shared.registerDeviceToken(deviceToken: tokenString, userId: userId)
                print("[NotificationManager] token enviado al servidor")
            } catch {
                print("[NotificationManager] error enviando token: \(error)")
            }
        }
    }

    // Schedule a local notification (useful as a fallback or to show immediate feedback)
    func scheduleLocalNotification(title: String, body: String, userInfo: [AnyHashable:Any]? = nil, inSeconds: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let ui = userInfo as? [String: String] {
            content.userInfo = ui
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.1, inSeconds), repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { error in
            if let e = error {
                print("[NotificationManager] error scheduling local notification: \(e)")
            } else {
                print("[NotificationManager] local notification scheduled: \(title) - \(body)")
            }
        }
    }
}
