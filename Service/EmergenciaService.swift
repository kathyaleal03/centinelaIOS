import Foundation

/// Servicio simple para consumir la API REST de emergencias.
/// Usa `async/await` y `URLSession`.
public final class EmergenciaService {

    // Base url apuntando al API central definido en `APIConstants`
    public var baseURL: URL

    public init() {
        // APIConstants.baseURL contiene "https://apicentinela.onrender.com"
        // Los endpoints en el servidor esperan el prefijo "/api/..."
        let full = APIConstants.baseURL + "/api/emergencias"
        self.baseURL = URL(string: full) ?? URL(string: "https://apicentinela.onrender.com/api/emergencias")!
    }

    private var jsonDecoder: JSONDecoder {
        let d = JSONDecoder()
        // Tolerar snake_case del backend y decodificar fechas ISO8601
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private var jsonEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    public func getAll() async throws -> [Emergencia] {
        let (data, response) = try await URLSession.shared.data(from: baseURL)
        try validate(response: response)
        return try jsonDecoder.decode([Emergencia].self, from: data)
    }

    public func getById(_ id: Int) async throws -> Emergencia {
        let url = baseURL.appendingPathComponent("\(id)")
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response: response)
        return try jsonDecoder.decode(Emergencia.self, from: data)
    }

    public func create(_ emergencia: Emergencia) async throws -> Emergencia {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(emergencia)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response)
        return try jsonDecoder.decode(Emergencia.self, from: data)
    }

    /// Update parcial/total: construye un JSON sólo con las propiedades no-nil
    public func update(id: Int, with update: EmergenciaUpdate) async throws -> Emergencia {
        let url = baseURL.appendingPathComponent("\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Construir diccionario sólo con los campos no-nil
        var dict: [String: Any] = [:]
        if let mensaje = update.mensaje { dict["mensaje"] = mensaje }
        if let latitud = update.latitud { dict["latitud"] = latitud }
        if let longitud = update.longitud { dict["longitud"] = longitud }
        if let atendido = update.atendido { dict["atendido"] = atendido }

        request.httpBody = try JSONSerialization.data(withJSONObject: dict, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response)
        return try jsonDecoder.decode(Emergencia.self, from: data)
    }

    public func delete(id: Int) async throws {
        let url = baseURL.appendingPathComponent("\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response: response)
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
