import Foundation
import UIKit

final class ImageUploadService {
	static let shared = ImageUploadService()
	private init() {}

	enum UploadError: Error {
		case invalidImage
	}

	/// Placeholder upload implementation. Converts image to JPEG and returns a fake URL string after a short delay.
	/// Replace this with real multipart/form-data upload to your backend when ready.
	func upload(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
		DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.6) {
			guard let _ = image.jpegData(compressionQuality: 0.8) else {
				completion(.failure(UploadError.invalidImage))
				return
			}
			// Return a fake URL for development/testing
			let fakeURL = "https://example.com/uploads/\(UUID().uuidString).jpg"
			completion(.success(fakeURL))
		}
	}
}

