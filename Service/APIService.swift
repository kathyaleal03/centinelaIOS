//
//  APIService.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation
import CoreLocation

enum APIError: Error {
    case invalidURL
    case requestFailed(String)
    case decodingError(String)
}

class APIService {
    static let shared = APIService()
    private init() {}
    
    private func request<T: Decodable>(_ endpoint: String,
                                       method: String = "GET",
                                       body: Data? = nil,
                                       token: String? = nil) async throws -> T {
        guard let url = URL(string: APIConstants.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url, timeoutInterval: APIConstants.timeout)
        req.httpMethod = method
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        // Debug logging for requests
        print("[APIService] -> Request: \(req.httpMethod ?? "GET") \(req.url?.absoluteString ?? "")")
        print("[APIService] -> Headers: \(req.allHTTPHeaderFields ?? [:])")
        if let b = req.httpBody, let s = String(data: b, encoding: .utf8) {
            print("[APIService] -> Body: \(s)")
        }
        let start = Date()
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            // Log the low-level networking error details for easier diagnosis (URLError / NSError)
            if let urlErr = error as? URLError {
                print("[APIService] URLSession error: \(urlErr), code: \(urlErr.code.rawValue)")
            } else {
                let ns = error as NSError
                print("[APIService] URLSession error: domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
            }
            throw error
        }
        let elapsed = Date().timeIntervalSince(start)
        print("[APIService] <- Response in \(String(format: "%.2fs", elapsed)) for \(req.url?.absoluteString ?? "")")
        // Print response headers and body size for better diagnostics
        if let httpResp = response as? HTTPURLResponse {
            print("[APIService] <- Response headers: \(httpResp.allHeaderFields)")
        }
        print("[APIService] <- Response body length: \(data.count) bytes")

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let message = "HTTP \(status): \(bodyString)"
            print("[APIService] <- Non-2xx response (\(status)) for \(req.url?.absoluteString ?? ""): \(bodyString)")
            throw APIError.requestFailed(message)
        }
        // Log successful response bodies (helpful for POST/PUT to inspect server reply)
        if data.count == 0 {
            print("[APIService] <- Success response body: <empty>")
        } else if let bodyString = String(data: data, encoding: .utf8), !bodyString.isEmpty {
            // Try to pretty-print JSON if possible
            if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: []),
               let pretty = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted]),
               let prettyStr = String(data: pretty, encoding: .utf8) {
                print("[APIService] <- Success response body: \n\(prettyStr)")
            } else {
                print("[APIService] <- Success response body: \(bodyString)")
            }
        } else {
            // Fallback: print base64 so we can inspect non-UTF8 data
            print("[APIService] <- Success response body (non-utf8): \(data.base64EncodedString())")
        }
        do {
            let decoder = JSONDecoder()
            // tolerate snake_case keys from backend (e.g. usuario_id) and map to camelCase CodingKeys
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            // Provide body context for debugging
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            print("[APIService] Decoding error: \(error). Response body: \(bodyString)")
            throw APIError.decodingError(bodyString)
        }
    }
    
    // MARK: - Public API wrappers
    
    // Register user -> returns created User (or wrapper)
    func registerUser(_ payload: [String:Any]) async throws -> User {
        let endpoint = "/api/usuarios/createUser"
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await request(endpoint, method: "POST", body: body, token: nil)
    }
    
    // Login -> try to return token + user; tolerate backends that return only a User object
    struct LoginResponse: Codable {
        let token: String?
        let user: User
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        // Backend login endpoint
        let endpoint = "/api/usuarios/login"
        // Build request manually so we can try multiple decode strategies
        func makeRequest(urlString: String, method: String, body: Data?) throws -> URLRequest {
            guard let url = URL(string: APIConstants.baseURL + urlString) else { throw APIError.invalidURL }
            var req = URLRequest(url: url, timeoutInterval: APIConstants.timeout)
            req.httpMethod = method
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let b = body { req.httpBody = b }
            return req
        }

        let bodyDict: [String:Any] = ["correo": email, "contrasena": password]
        let body = try JSONSerialization.data(withJSONObject: bodyDict)

        // Local helper to perform request and try decoding
        func performRequest(_ req: URLRequest) async throws -> LoginResponse {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let bodyString = String(data: data, encoding: .utf8) ?? ""
                let message = "HTTP \( (response as? HTTPURLResponse)?.statusCode ?? -1): \(bodyString)"
                throw APIError.requestFailed(message)
            }

            // First try the token+user wrapper
            let decoder = JSONDecoder()
            // Backend may use snake_case like `usuario_id` inside `user` object
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let loginResp = try? decoder.decode(LoginResponse.self, from: data) {
                return loginResp
            }

            // If that fails, try decoding a bare User (some backends return the user object directly)
            if let userOnly = try? decoder.decode(User.self, from: data) {
                return LoginResponse(token: nil, user: userOnly)
            }

            // If neither decoded, return a decoding error with body for diagnostics
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.requestFailed("Decoding error; response body: \(bodyString)")
        }

        // Try POST first
        do {
            let req = try makeRequest(urlString: endpoint, method: "POST", body: body)
            return try await performRequest(req)
        } catch let apiError as APIError {
            // If server rejects POST (405) try a GET fallback using query params (some backends expect GET)
            switch apiError {
            case .requestFailed(let msg) where msg.contains("405") || msg.lowercased().contains("method not allowed"):
                let eCorreo = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
                let ePass = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? password
                let getEndpoint = "\(endpoint)?correo=\(eCorreo)&contrasena=\(ePass)"
                let req = try makeRequest(urlString: getEndpoint, method: "GET", body: nil)
                return try await performRequest(req)
            default:
                throw apiError
            }
        }
    }
    
    // Get alerts by region id (nuevo esquema usa region_id)
    func fetchAlerts(regionId: Int) async throws -> [AppAlert] {
        let endpoint = "/api/alertas?region_id=\(regionId)"
        return try await request(endpoint, method: "GET")
    }

    // Backwards-compatible helper when caller has Region model
    func fetchAlerts(region: Region) async throws -> [AppAlert] {
        return try await fetchAlerts(regionId: region.id)
    }

    // Get refuges by region id
    func fetchRefuges(regionId: Int) async throws -> [Refuge] {
        let endpoint = "/api/refugios?region_id=\(regionId)"
        return try await request(endpoint, method: "GET")
    }

    func fetchRefuges(region: Region) async throws -> [Refuge] {
        return try await fetchRefuges(regionId: region.id)
    }
    
    // Post report (multipart not implemented here - example uses JSON with fotoURL)
    func postReport(report: Report, token: String?) async throws -> Report {
        let endpoint = "/api/reportes"
        let encoder = JSONEncoder()
        let body = try encoder.encode(report)
        return try await request(endpoint, method: "POST", body: body, token: token)
    }

    // Post report using a flexible payload dictionary matching server expectations
    func postReportPayload(_ payload: [String:Any], token: String?) async throws -> Report {
        let endpoint = "/api/reportes"
        guard let url = URL(string: APIConstants.baseURL + endpoint) else { throw APIError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: APIConstants.timeout)
        req.httpMethod = "POST"
        if let token = token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try JSONSerialization.data(withJSONObject: payload)
        req.httpBody = body
        // Logging request once
        print("[APIService] -> Request: POST \(req.url?.absoluteString ?? "")")
        print("[APIService] -> Headers: \(req.allHTTPHeaderFields ?? [:])")
        if let s = String(data: body, encoding: .utf8) { print("[APIService] -> Body: \(s)") }

        // Retry loop for transient networking errors (exponential backoff)
        let maxAttempts = 3
        var attempt = 0
        let baseDelaySeconds: Double = 1.0
        var lastError: Error?

        while attempt < maxAttempts {
            attempt += 1
            let start = Date()
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                let elapsed = Date().timeIntervalSince(start)
                print("[APIService] <- Response in \(String(format: "%.2fs", elapsed)) for \(req.url?.absoluteString ?? "") (attempt \(attempt))")

                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    let bodyString = String(data: data, encoding: .utf8) ?? ""
                    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("[APIService] <- Non-2xx response (\(status)) for \(req.url?.absoluteString ?? ""): \(bodyString)")
                    throw APIError.requestFailed("HTTP \(status): \(bodyString)")
                }

                // If server returned an empty body (201 with no JSON), build optimistic Report
                if data.count == 0 {
                    var temp: [String:Any] = [:]
                    if let tipo = payload["tipo"] as? String { temp["tipo"] = tipo }
                    if let descripcion = payload["descripcion"] as? String { temp["descripcion"] = descripcion }
                    if let lat = payload["latitud"] as? Double { temp["latitud"] = lat }
                    if let lon = payload["longitud"] as? Double { temp["longitud"] = lon }
                    if let foto = payload["fotoUrl"] as? String { temp["fotoUrl"] = foto }
                    if let estado = payload["estado"] as? String { temp["estado"] = estado }
                    if let usuarioId = payload["usuarioId"] as? Int { temp["usuarioId"] = usuarioId }
                    else if let usuario = payload["usuario"] as? [String:Any], let uid = usuario["usuarioId"] as? Int { temp["usuarioId"] = uid }

                    if let tmpData = try? JSONSerialization.data(withJSONObject: temp),
                       let decoded = try? JSONDecoder().decode(Report.self, from: tmpData) {
                        print("[APIService] <- Empty response body; returning optimistic Report: \(decoded)")
                        return decoded
                    } else {
                        let payloadStr = (try? JSONSerialization.data(withJSONObject: payload)).flatMap { String(data: $0, encoding: .utf8) } ?? "<unavailable>"
                        print("[APIService] <- Empty response body and could not build optimistic Report from payload: \(payloadStr)")
                        throw APIError.decodingError("Empty response and could not build optimistic Report from payload: \(payloadStr)")
                    }
                }

                // Otherwise decode normally (tolerant to snake_case)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    let decoded = try decoder.decode(Report.self, from: data)
                    if let bodyString = String(data: data, encoding: .utf8) {
                        print("[APIService] <- Success response body: \(bodyString)")
                    }
                    return decoded
                } catch {
                    let bodyString = String(data: data, encoding: .utf8) ?? ""
                    print("[APIService] Decoding error for Report: \(error). Response body: \(bodyString)")
                    throw APIError.decodingError(bodyString)
                }

            } catch {
                lastError = error
                // Determine if error is transient (URLError variants)
                var isTransient = false
                if let urlErr = error as? URLError {
                    let code = urlErr.code
                    isTransient = (code == .networkConnectionLost || code == .timedOut || code == .cannotFindHost || code == .cannotConnectToHost || code == .dnsLookupFailed || code == .notConnectedToInternet)
                    print("[APIService] Attempt \(attempt) - URLError: \(urlErr), code: \(urlErr.code.rawValue), userInfo: \(urlErr.userInfo)")
                } else {
                    let ns = error as NSError
                    print("[APIService] Attempt \(attempt) - Error: domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription) userInfo=\(ns.userInfo)")
                }

                if attempt < maxAttempts && isTransient {
                    // Exponential backoff before retrying
                    let backoff = baseDelaySeconds * pow(2.0, Double(attempt - 1))
                    print("[APIService] Transient error detected, will retry after \(backoff)s (attempt \(attempt + 1) of \(maxAttempts))")
                    let nanos = UInt64(backoff * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: nanos)
                    continue
                }

                // Not transient or out of attempts: rethrow with context
                if let urlErr = error as? URLError {
                    throw urlErr
                }
                throw error
            }
        }

        // If we exit loop without returning, throw last error
        if let err = lastError {
            print("[APIService] postReportPayload failed after \(maxAttempts) attempts: \(err)")
            throw err
        }
        throw APIError.requestFailed("Unknown error in postReportPayload")
    }

    // Register device token with backend so server can send push notifications later
    func registerDeviceToken(deviceToken: String, userId: Int?) async throws -> Bool {
        let endpoint = "/api/device-tokens"
        var payload: [String:Any] = ["deviceToken": deviceToken, "platform": "ios"]
        if let uid = userId { payload["usuarioId"] = uid }
        let body = try JSONSerialization.data(withJSONObject: payload)
        // We don't expect a complex response; just check for 2xx
        guard let url = URL(string: APIConstants.baseURL + endpoint) else { throw APIError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: APIConstants.timeout)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.requestFailed("HTTP \( (response as? HTTPURLResponse)?.statusCode ?? -1): \(bodyString)")
        }
        return true
    }

    // Update existing user by id (PUT). Backend may accept /api/usuarios/{id}
    func updateUser(userId: Int, payload: [String:Any], token: String?) async throws -> User {
        let endpoint = "/api/usuarios/\(userId)"
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await request(endpoint, method: "PUT", body: body, token: token)
    }

    // Fetch reports (optionally authenticated)
    func fetchReports(token: String?) async throws -> [Report] {
        let endpoint = "/api/reportes"
        return try await request(endpoint, method: "GET", token: token)
    }

    // MARK: - Comentarios (comments)
    // Fetch comments for a specific report
    func fetchComments(reportId: Int, token: String?) async throws -> [Comment] {
        // The backend controller exposes GET /api/comentarios (no query param for reporteId).
        // Request all comments and filter client-side by reporteId to match controller behavior.
        let endpoint = "/api/comentarios"
        let all: [Comment] = try await request(endpoint, method: "GET", token: token)
        return all.filter { $0.reporteId == reportId }
    }

    // Post a new comment (payload should include mensaje, usuarioId, reporteId and optionally fecha)
    func postCommentPayload(_ payload: [String:Any], token: String?) async throws -> Comment {
        let endpoint = "/api/comentarios"
        guard let url = URL(string: APIConstants.baseURL + endpoint) else { throw APIError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: APIConstants.timeout)
        req.httpMethod = "POST"
        if let token = token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try JSONSerialization.data(withJSONObject: payload)
        req.httpBody = body

        // Logging
        print("[APIService] -> Request: POST \(req.url?.absoluteString ?? "")")
        print("[APIService] -> Headers: \(req.allHTTPHeaderFields ?? [:])")
        if let s = String(data: body, encoding: .utf8) {
            print("[APIService] -> Body: \(s)")
        }

        let start = Date()
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            if let urlErr = error as? URLError {
                print("[APIService] POST /api/comentarios URLSession error: \(urlErr), code: \(urlErr.code.rawValue)")
            } else {
                let ns = error as NSError
                print("[APIService] POST /api/comentarios URLSession error: domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
            }
            throw error
        }
        let elapsed = Date().timeIntervalSince(start)
        print("[APIService] <- Response in \(String(format: "%.2fs", elapsed)) for \(req.url?.absoluteString ?? "")")

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let message = "HTTP \(status): \(bodyString)"
            print("[APIService] <- Non-2xx response (\(status)) for \(req.url?.absoluteString ?? ""): \(bodyString)")
            throw APIError.requestFailed(message)
        }

        // If server returned an empty body (some servers reply with 201 and no JSON), create an optimistic Comment
        if data.count == 0 {
            let mensaje = payload["mensaje"] as? String ?? ""
            // payload now embeds usuario and reporte as nested objects: { "usuario": { "usuarioId": X }, "reporte": { "reporteId": Y } }
            let usuarioId = (payload["usuario"] as? [String:Any])?["usuarioId"] as? Int
            let reporteId = (payload["reporte"] as? [String:Any])?["reporteId"] as? Int
            let iso = ISO8601DateFormatter().string(from: Date())
            // Build a temporary JSON dictionary and decode into Comment so we don't rely on a synthesized memberwise init
            var temp: [String:Any] = ["mensaje": mensaje, "fecha": iso]
            if let u = usuarioId { temp["usuario"] = ["usuarioId": u] }
            if let r = reporteId { temp["reporte"] = ["reporteId": r] }
            if let tmpData = try? JSONSerialization.data(withJSONObject: temp),
               let decoded = try? JSONDecoder().decode(Comment.self, from: tmpData) {
                print("[APIService] <- Empty response body; returning optimistic Comment: \(decoded)")
                return decoded
            } else {
                // As a last resort, create a minimal Comment-like object by decoding a simple JSON string
                let fallbackJSON = "{ \"mensaje\": \"\(mensaje)\", \"fecha\": \"\(iso)\" }".data(using: .utf8) ?? Data()
                let decoded = try JSONDecoder().decode(Comment.self, from: fallbackJSON)
                print("[APIService] <- Empty response body; returning optimistic Comment (fallback): \(decoded)")
                return decoded
            }
        }

        if let bodyString = String(data: data, encoding: .utf8) {
            print("[APIService] <- Success response body: \(bodyString)")
        }

        do {
            let decoded = try JSONDecoder().decode(Comment.self, from: data)
            return decoded
        } catch {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            print("[APIService] Decoding error for Comment: \(error). Response body: \(bodyString)")
            throw APIError.decodingError(bodyString)
        }
    }

    // Update comment by id (PUT)
    func updateComment(commentId: Int, payload: [String:Any], token: String?) async throws -> Comment {
        let endpoint = "/api/comentarios/\(commentId)"
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await request(endpoint, method: "PUT", body: body, token: token)
    }

    // Delete comment by id
    func deleteComment(commentId: Int, token: String?) async throws -> Bool {
        let endpoint = "/api/comentarios/\(commentId)"
        // We don't expect a body; just call request for a Bool (server could return success flag)
        // Use a lightweight implementation: perform request manually to accept empty body
        guard let url = URL(string: APIConstants.baseURL + endpoint) else { throw APIError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: APIConstants.timeout)
        req.httpMethod = "DELETE"
        if let token = token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            if let urlErr = error as? URLError {
                print("[APIService] DELETE /api/comentarios URLSession error: \(urlErr), code: \(urlErr.code.rawValue)")
            } else {
                let ns = error as NSError
                print("[APIService] DELETE /api/comentarios URLSession error: domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
            }
            throw error
        }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.requestFailed("HTTP \( (response as? HTTPURLResponse)?.statusCode ?? -1): \(bodyString)")
        }
        return true
    }
    
    // Post emergency (simple payload)
    struct EmergencyResponse: Codable {
        let success: Bool
        let message: String?
    }
    func postEmergency(payload: [String:Any], token: String?) async throws -> EmergencyResponse {
        let endpoint = "/api/emergencias"
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await request(endpoint, method: "POST", body: body, token: token)
    }
}
