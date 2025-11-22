//
//  Report.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation
import CoreLocation

struct Report: Codable, Identifiable {
    // Server-side numeric id (may be nil for transient objects).
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

    // Stable identity across network refreshes:
    // - If the backend id exists, use it.
    // - Otherwise, derive a deterministic key from immutable fields (tipo + descripcion + coords rounded).
    var id: String {
        if let rid = reporteId {
            return "rid:\(rid)"
        }
        let lat = String(format: "%.5f", latitud)
        let lon = String(format: "%.5f", longitud)
        // Lowercase tipo and keep descripcion as-is to distinguish similar reports
        return "tmp:\(tipo.lowercased())|\(descripcion)|\(lat)|\(lon)"
    }

    enum CodingKeys: String, CodingKey {
        // Server uses "reporteId" in its JSON payloads. Map accordingly.
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

