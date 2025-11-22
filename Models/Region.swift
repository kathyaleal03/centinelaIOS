import Foundation

// Nueva representación de región basada en la nueva BD (regiones table)
struct Region: Codable, Identifiable, Equatable, Hashable {
    var id: Int
    var nombre: String
    var descripcion: String?
    var latitud: Double?
    var longitud: Double?

    var displayName: String { nombre }

    /// Short label used for compact UI (e.g. "Norte", "Sur")
    var shortName: String {
        // Try to use the last word of the full name (e.g. "Santa Ana Norte" -> "Norte").
        let parts = nombre.split(separator: " ")
        if let last = parts.last {
            return String(last)
        }
        return nombre
    }
}

// Helper local con opciones por defecto (puedes cargar desde API en tiempo de ejecución)
extension Region {
    static let norte = Region(id: 1, nombre: "Santa Ana Norte", descripcion: "Zona norte del departamento de Santa Ana", latitud: 13.9833, longitud: -89.55)
    static let sur = Region(id: 2, nombre: "Santa Ana Sur", descripcion: "Zona sur del departamento de Santa Ana", latitud: 13.95, longitud: -89.5667)
    static let este = Region(id: 3, nombre: "Santa Ana Este", descripcion: "Zona este del departamento de Santa Ana", latitud: 13.9833, longitud: -89.5167)
    static let oeste = Region(id: 4, nombre: "Santa Ana Oeste", descripcion: "Zona oeste del departamento de Santa Ana", latitud: 13.9833, longitud: -89.5833)
}

extension Region {
    static func from(name: String) -> Region? {
        let all = [Region.norte, Region.sur, Region.este, Region.oeste]
        // Accept either the display name (e.g. "Santa Ana Norte") or the API-style name (e.g. "Santa_Ana_Norte")
        return all.first { $0.nombre == name || $0.apiValue == name }
    }
}

extension Region {
    /// Value used by the backend API to identify a region (spaces -> underscores)
    var apiValue: String {
        nombre.replacingOccurrences(of: " ", with: "_")
    }
    
    /// Convenience to create from an API value
    static func fromApiValue(_ apiValue: String) -> Region? {
        return from(name: apiValue)
    }
}
