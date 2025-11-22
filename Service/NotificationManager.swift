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
        print("[NotificationManager] saved device token to UserDefaults: \(token.prefix(8))...")

        // If a user is already saved locally, try to register the token immediately.
        // AuthViewModel is @MainActor so call it from an async Task and await the main-actor-isolated method.
        Task {
            if let savedUser = await AuthViewModel.getSavedUser() {
                let userId = savedUser.id
                do {
                    try await APIService.shared.registerDeviceToken(deviceToken: token, userId: userId)
                    print("[NotificationManager] saved token immediately registered with server for userId=\(userId)")
                } catch {
                    print("[NotificationManager] immediate registration failed: \(error)")
                }
            }
        }
    }

    static func getSavedDeviceToken() -> String? {
        UserDefaults.standard.string(forKey: deviceTokenKey)
    }

    /// Register the saved device token with the server and optionally attach it to a userId.
    /// Call this after successful login so the server can link the token to the authenticated user.
    func registerSavedTokenWithServer(userId: Int?) {
        // Try to fetch the token; if missing we'll retry a few times because of possible race between APNs callback and login
        let maxAttempts = 3
        var attempt = 0

        func attemptRegister(after delay: TimeInterval) {
            attempt += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let token = Self.getSavedDeviceToken() {
                    Task {
                        do {
                            try await APIService.shared.registerDeviceToken(deviceToken: token, userId: userId)
                            print("[NotificationManager] saved token registered with server for userId=\(userId.map(String.init) ?? "nil")")
                        } catch {
                            print("[NotificationManager] failed to register saved token: \(error)")
                        }
                    }
                } else {
                    if attempt < maxAttempts {
                        let nextDelay = pow(2.0, Double(attempt - 1)) // 1s,2s,...
                        print("[NotificationManager] no saved device token yet (attempt \(attempt)). Retrying in \(nextDelay)s")
                        attemptRegister(after: nextDelay)
                    } else {
                        // Final diagnostic dump
                        let raw = UserDefaults.standard.object(forKey: Self.deviceTokenKey)
                        print("[NotificationManager] no saved device token to register after \(attempt) attempts")
                        print("[NotificationManager] deviceTokenKey=\(Self.deviceTokenKey). UserDefaults value (raw): \(String(describing: raw))")
                        let keys = Array(UserDefaults.standard.dictionaryRepresentation().keys).sorted()
                        print("[NotificationManager] UserDefaults keys (sample): \(keys.prefix(30))")

                        // Also print notification settings to help debugging on device
                        UNUserNotificationCenter.current().getNotificationSettings { settings in
                            // 'provisional' is not a property on UNNotificationSettings; check via authorizationStatus
                            let authRaw = settings.authorizationStatus.rawValue
                            let isProvisional = (settings.authorizationStatus == .provisional)
                            let alertRaw = settings.alertSetting.rawValue
                            print("[NotificationManager] notification settings: authStatus=\(authRaw), isProvisional=\(isProvisional), alertSetting=\(alertRaw)")
                        }
                    }
                }
            }
        }

        // Start first attempt immediately
        attemptRegister(after: 0)
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
