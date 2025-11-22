import UIKit

/// Simple helper for persisting a profile image locally using UserDefaults.
/// If you later add server sync, you can extend this to upload/download.
struct ProfileImageStore {
    static let key = "profileImageData"
    /// Save image as compressed JPEG (default quality 0.8) to UserDefaults.
    static func save(_ image: UIImage, compression: CGFloat = 0.8) {
        guard let data = image.jpegData(compressionQuality: compression) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    /// Load previously stored profile image.
    static func load() -> UIImage? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return UIImage(data: data)
    }
    /// Delete stored profile image.
    static func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
