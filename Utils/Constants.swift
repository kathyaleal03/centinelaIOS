//
//  Constants.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation

struct APIConstants {
    // Base URL for the deployed cloud API (no trailing /api segment here;
    // endpoints in the code already include the "/api/..." prefix)
    static let baseURL = "https://apicentinela.onrender.com"
    // Increase timeout temporarily for debugging slow or LAN servers
    static let timeout: TimeInterval = 60
}

// Cloudinary configuration - set these values before using Cloudinary uploads.
// For unsigned uploads create an upload preset in your Cloudinary dashboard and set
// `uploadPreset` to that preset's name. Do NOT commit secrets (API secret) to the repo.
struct Cloudinary {
    // Example: "my-cloud-name"
    static let cloudName: String = "dizfzyxrf"
    // Example: "unsigned_preset_name"
    static let uploadPreset: String = "imagenes"
    static var uploadURL: String { "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload" }
}

// Weather API configuration. Fill `apiKey` with your OpenWeatherMap API key or another provider's key.
// Do NOT commit real secrets in public repositories. For local testing you may hardcode the key here
// or load it from a protected source (Keychain, environment, or Info.plist) before building.
struct WeatherAPI {
    // Example: "your_openweathermap_api_key"
        // Example: "your_openweathermap_api_key"
        // Preferred: set the key in your Info.plist under the key `OPENWEATHER_API_KEY`.
        // Fallback: you can also set this value directly here for quick testing (not recommended for public repos).
        private static var fallbackKey: String = "57d7a9de85bf52c405fbce861dd3c971"

        static var apiKey: String {
            // 1) Try Info.plist (recommended)
            if let k = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String, !k.isEmpty {
                return k
            }
            // 2) Fallback to compiled-in key (useful for quick local testing)
            return fallbackKey
        }

    static let baseURL = "https://api.openweathermap.org/data/2.5"

        // Helper to set fallback key programmatically (useful for tests)
        static func setFallbackKey(_ key: String) {
            fallbackKey = key
        }
}
