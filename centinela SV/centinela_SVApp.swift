import SwiftUI

@main
struct centinela_SVApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var reportVM = ReportViewModel()
    @StateObject private var locationService = LocationService()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    // Primera vez → mostrar onboarding
                    LoginView()
                        .environmentObject(authVM)
                        .environmentObject(reportVM)
                        .environmentObject(locationService)
                } else {
                    // Después del onboarding
                    if authVM.isAuthenticated {
                        MainTabView()
                            .environmentObject(authVM)
                            .environmentObject(reportVM)
                            .environmentObject(locationService)
                    } else {
                        // Usuario no autenticado → LoginView
                        LoginView()
                            .environmentObject(authVM)
                            .environmentObject(reportVM)
                            .environmentObject(locationService)
                    }
                }
            }

            
            .onAppear {
                // Request notification permission on app launch
                NotificationManager.shared.requestAuthorizationAndRegister()
                // Debug: check weather API key presence
                if WeatherAPI.apiKey.isEmpty {
                    print("[App] Weather API key NOT found. Set OPENWEATHER_API_KEY in Info.plist or use WeatherAPI.setFallbackKey(_:) for testing.")
                } else {
                    print("[App] Weather API key present (length: \(WeatherAPI.apiKey.count))")
                }
                // Also accept API key from environment variables (useful for Xcode scheme Run env vars)
                if let envKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"], !envKey.isEmpty {
                    WeatherAPI.setFallbackKey(envKey)
                    print("[App] Weather API key loaded from environment variables (scheme)")
                }
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

