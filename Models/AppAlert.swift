import Foundation

struct AppAlert: Codable, Identifiable {
    // Map server's `alertaId` to `id` so SwiftUI lists work correctly
    var id: Int?
    var titulo: String?
    var descripcion: String?
    var nivel: String?
    var fecha: String?
    var usuario: User?
    var region: APIRegion?

    private enum CodingKeys: String, CodingKey {
        case id = "alertaId"
        case titulo, descripcion, nivel, fecha, usuario, region
    }

    struct APIRegion: Codable {
        var regionId: Int?
        var nombre: String?
        var descripcion: String?
        var latitud: Double?
        var longitud: Double?
    }
}
