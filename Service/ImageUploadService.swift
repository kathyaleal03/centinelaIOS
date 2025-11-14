import Foundation

#if canImport(UIKit)
import UIKit

final class ImageUploadService {
	static let shared = ImageUploadService()
	private init() {}

	enum UploadError: Error {
		case invalidImage
		case missingCloudinaryConfig
		case serverError(String)
	}

	/// Upload image to Cloudinary using an unsigned upload preset.
	/// Falls back to an error if Cloudinary constants are not configured.
	func upload(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
		// Validate Cloudinary config
		guard Cloudinary.cloudName != "REPLACE_WITH_YOUR_CLOUD_NAME",
			Cloudinary.uploadPreset != "REPLACE_WITH_YOUR_UPLOAD_PRESET" else {
			// Fallback: return an informative error so developer can configure constants
			completion(.failure(UploadError.missingCloudinaryConfig))
			return
		}

		// Try JPEG first, then PNG, then attempt to re-render the image if needed.
		var imageData: Data? = image.jpegData(compressionQuality: 0.8)
		if imageData == nil {
			// Try PNG fallback
			imageData = image.pngData()
		}
		if imageData == nil {
			// Attempt to re-render into a new UIImage (this can help with some CIImage/CGImage-backed images)
			#if canImport(UIKit)
			let renderer = UIGraphicsImageRenderer(size: image.size)
			let rendered = renderer.image { _ in
				image.draw(in: CGRect(origin: .zero, size: image.size))
			}
			imageData = rendered.jpegData(compressionQuality: 0.8) ?? rendered.pngData()
			#else
			print("[ImageUploadService] re-render fallback not available on this platform")
			imageData = nil
			#endif
		}

		guard let finalImageData = imageData else {
			print("[ImageUploadService] failed to obtain image data. image.size=\(image.size), scale=\(image.scale), cgImage=\(image.cgImage != nil)")
			completion(.failure(UploadError.invalidImage))
			return
		}

		let url = URL(string: Cloudinary.uploadURL)!
		var req = URLRequest(url: url)
		req.httpMethod = "POST"

		let boundary = "Boundary-\(UUID().uuidString)"
		req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

		var body = Data()

		// upload_preset field
		body.appendString("--\(boundary)\r\n")
		body.appendString("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n")
		body.appendString("\(Cloudinary.uploadPreset)\r\n")

		// file field
		let filename = "upload_\(UUID().uuidString).jpg"
		body.appendString("--\(boundary)\r\n")
		body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"")
		body.appendString("\(filename)\"\r\n")
		body.appendString("Content-Type: image/jpeg\r\n\r\n")
		body.append(finalImageData)
		body.appendString("\r\n")

		body.appendString("--\(boundary)--\r\n")

		req.httpBody = body

		let task = URLSession.shared.dataTask(with: req) { data, response, error in
			if let err = error {
				completion(.failure(err))
				return
			}
			guard let http = response as? HTTPURLResponse else {
				completion(.failure(UploadError.serverError("No HTTP response")))
				return
			}
			guard (200...299).contains(http.statusCode), let data = data else {
				let bodyStr = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
				completion(.failure(UploadError.serverError("Status \(http.statusCode): \(bodyStr)")))
				return
			}
			// Parse Cloudinary response JSON
			if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
				let secureUrl = json["secure_url"] as? String {
				completion(.success(secureUrl))
				return
			} else {
				let maybe = String(data: data, encoding: .utf8) ?? "<non-utf8>"
				completion(.failure(UploadError.serverError("Invalid response: \(maybe)")))
				return
			}
		}
		task.resume()
	}

	// Async/await wrapper
	func uploadAsync(image: UIImage) async throws -> String {
		return try await withCheckedThrowingContinuation { cont in
			self.upload(image: image) { result in
				switch result {
				case .success(let url): cont.resume(returning: url)
				case .failure(let err): cont.resume(throwing: err)
				}
			}
		}
	}
}

// Helper to append string to Data for multipart construction
fileprivate extension Data {
	mutating func appendString(_ string: String) {
		if let d = string.data(using: .utf8) { append(d) }
	}
}

#else
// If UIKit is not available, provide a stub so the file compiles on non-UIKit platforms.
// The real ImageUploadService (which depends on UIImage) is only available when UIKit can import.
final class ImageUploadService { }
#endif

