import SwiftUI

@main
struct centinela_SVApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var locationService = LocationService()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isAuthenticated {
                    MainTabView()
                        .environmentObject(authVM)
                        .environmentObject(locationService)
                } else {
                    LoginView()
                        .environmentObject(authVM)
                        .environmentObject(locationService)
                }
            }
            .onAppear {
                // Request notification permission on app launch
                NotificationManager.shared.requestAuthorizationAndRegister()
            }
        }

    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[AppDelegate] didRegisterForRemoteNotificationsWithDeviceToken")
        // Try to read the saved user from AuthViewModel persistence so we can attach a usuarioId to the token
        let saved = AuthViewModel.getSavedUser()
        let userId = saved?.id
        NotificationManager.shared.sendDeviceTokenToServer(deviceToken, userId: userId)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AppDelegate] failed to register remote notifications: \(error.localizedDescription)")
    }

    // Called when a remote notification arrives (background or foreground) and optionally performs a background fetch
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("[AppDelegate] didReceiveRemoteNotification: \(userInfo)")
        // Forward to NotificationManager if needed for additional handling
        completionHandler(.noData)
    }
}

