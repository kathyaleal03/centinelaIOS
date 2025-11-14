//
//  Report.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation
import CoreLocation

struct Report: Codable, Identifiable {
    // Use an internal UUID for stable identity in SwiftUI collections.
    // This is not part of the server payload and is excluded from Codable via CodingKeys.
    let uuid: UUID = UUID()
    

    // Server-side numeric id (may be nil for transient objects). Mapped from JSON key "id".
    var reporteId: Int?
    var usuarioId: Int?
    var usuario: User?
    var tipo: String
    var descripcion: String
    var latitud: Double
    var longitud: Double
    var fotoUrl: String?
    var estado: String
    // fecha: ISO-8601 string returned by backend (e.g. "2025-11-13T12:34:56Z")
    var fecha: String?
    
    

    // Provide Identifiable conformance using the internal uuid so SwiftUI has a stable identity
    var id: UUID { uuid }

    enum CodingKeys: String, CodingKey {
        // Server uses "reporteId" in its JSON payloads (not "id"). Map accordingly.
        case reporteId = "reporteId"
        case usuarioId
        case usuario
        case tipo
        case descripcion
        case latitud
        case longitud
        case fotoUrl
        case estado
        case fecha
        // note: uuid intentionally omitted so it's not encoded/decoded
    }
}

extension Report {
    /// Parsed Date (ISO8601) for convenience. Returns nil if `fecha` is nil or cannot be parsed.
    var fechaDate: Date? {
        guard let s = fecha else { return nil }
        // Use ISO8601DateFormatter which matches many server responses
        return ISO8601DateFormatter().date(from: s)
    }
}

