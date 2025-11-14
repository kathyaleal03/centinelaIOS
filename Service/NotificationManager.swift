import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() { super.init() }

    func requestAuthorizationAndRegister() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
#if canImport(UIKit)
                    UIApplication.shared.registerForRemoteNotifications()
                    print("[NotificationManager] permiso otorgado para notificaciones remotas")
#else
                    print("[NotificationManager] permiso otorgado but UIApplication not available on this platform")
#endif
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
        // Persist token locally so we can (re)attach it to a user later
        Self.saveDeviceToken(tokenString)

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

    // Save the device token string to UserDefaults for later re-registration
    private static let deviceTokenKey = "device_token_hex"

    static func saveDeviceToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: deviceTokenKey)
    }

    static func getSavedDeviceToken() -> String? {
        UserDefaults.standard.string(forKey: deviceTokenKey)
    }

    /// Register the saved device token with the server and optionally attach it to a userId.
    /// Call this after successful login so the server can link the token to the authenticated user.
    func registerSavedTokenWithServer(userId: Int?) {
        guard let token = Self.getSavedDeviceToken() else {
            // Provide more diagnostic information to help debug why the token is missing.
            let raw = UserDefaults.standard.object(forKey: Self.deviceTokenKey)
            print("[NotificationManager] no saved device token to register")
            print("[NotificationManager] deviceTokenKey=\(Self.deviceTokenKey). UserDefaults value (raw): \(String(describing: raw))")
            // Also provide a short dump of keys so we can see what was persisted
            let keys = Array(UserDefaults.standard.dictionaryRepresentation().keys).sorted()
            print("[NotificationManager] UserDefaults keys (sample): \(keys.prefix(20))")
            return
        }
        Task {
            do {
                try await APIService.shared.registerDeviceToken(deviceToken: token, userId: userId)
                print("[NotificationManager] saved token registered with server for userId=\(userId.map(String.init) ?? "nil")")
            } catch {
                print("[NotificationManager] failed to register saved token: \(error)")
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
