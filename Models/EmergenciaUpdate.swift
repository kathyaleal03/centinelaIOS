import Foundation

// DTO para actualizaciones parciales (PUT/PATCH). Todas las propiedades son opcionales
public struct EmergenciaUpdate: Codable {
    public var mensaje: String?
    public var latitud: Double?
    public var longitud: Double?
    public var atendido: Bool?

    public init(mensaje: String? = nil,
                latitud: Double? = nil,
                longitud: Double? = nil,
                atendido: Bool? = nil) {
        self.mensaje = mensaje
        self.latitud = latitud
        self.longitud = longitud
        self.atendido = atendido
    }
}
