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
    static let baseURL = "http://192.168.43.132:8000"
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
