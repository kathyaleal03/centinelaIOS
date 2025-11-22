import Foundation

// Modelo que representa una Emergencia desde la API
public struct Emergencia: Identifiable, Codable, Equatable {
    public var id: Int?
    public var mensaje: String?
    public var latitud: Double?
    public var longitud: Double?
    public var atendido: Bool?
    public var createdAt: Date?

    public init(id: Int? = nil,
                mensaje: String? = nil,
                latitud: Double? = nil,
                longitud: Double? = nil,
                atendido: Bool? = nil,
                createdAt: Date? = nil) {
        self.id = id
        self.mensaje = mensaje
        self.latitud = latitud
        self.longitud = longitud
        self.atendido = atendido
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, mensaje, latitud, longitud, atendido, createdAt
    }
}
