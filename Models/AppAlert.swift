import Foundation

struct AppAlert: Codable, Identifiable {
    var id: Int?
    var titulo: String?
    var descripcion: String?
    var nivel: String?
    var fecha: String?
}
