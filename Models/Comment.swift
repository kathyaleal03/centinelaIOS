import Foundation

// Model matching backend Comentario
struct Comment: Codable, Identifiable {
    // Server numeric id (server uses "comentarioId")
    var commentId: Int?
    var mensaje: String
    var usuarioId: Int?
    var usuario: User?
    var fecha: String? // ISO string from backend; UI can format
    var reporteId: Int?

    // Stable SwiftUI identity (string) — use server id when available, otherwise a UUID
    private var uuid: UUID = UUID()
    var id: String { commentId.map { String($0) } ?? uuid.uuidString }

    enum CodingKeys: String, CodingKey {
        case comentarioId = "comentarioId"
        case mensaje
        case usuarioId
        case usuario
        case fecha
        case reporteId
        case reporte
    }

    // Custom decoding to tolerate either top-level reporteId/usuarioId or nested objects
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // comentarioId -> commentId
        self.commentId = try? container.decodeIfPresent(Int.self, forKey: .comentarioId)
        // mensaje is required
        self.mensaje = (try? container.decode(String.self, forKey: .mensaje)) ?? ""
        // usuario object (prefer nested User)
        self.usuario = try? container.decodeIfPresent(User.self, forKey: .usuario)
        // usuarioId may be top-level or inside usuario
        if let uId = try? container.decodeIfPresent(Int.self, forKey: .usuarioId) {
            self.usuarioId = uId
        } else {
            self.usuarioId = self.usuario?.id
        }
        // fecha
        self.fecha = try? container.decodeIfPresent(String.self, forKey: .fecha)
        // reporteId may be top-level or nested reporte
        if let rId = try? container.decodeIfPresent(Int.self, forKey: .reporteId) {
            self.reporteId = rId
        } else if let reporteObj = try? container.decodeIfPresent(Report.self, forKey: .reporte) {
            self.reporteId = reporteObj.reporteId
        } else {
            self.reporteId = nil
        }
    }
    
    // Custom encoding to match backend keys when sending Comment as JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let v = commentId { try container.encode(v, forKey: .comentarioId) }
        try container.encode(mensaje, forKey: .mensaje)
        if let u = usuario { try container.encode(u, forKey: .usuario) }
        else if let uid = usuarioId { try container.encode(uid, forKey: .usuarioId) }
        if let f = fecha { try container.encode(f, forKey: .fecha) }
        if let r = reporteId { try container.encode(r, forKey: .reporteId) }
    }
}
