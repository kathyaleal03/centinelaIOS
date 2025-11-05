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
    case decodingError
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
        let (data, response) = try await URLSession.shared.data(for: req)
        let elapsed = Date().timeIntervalSince(start)
        print("[APIService] <- Response in \(String(format: "%.2fs", elapsed)) for \(req.url?.absoluteString ?? "")")
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            let message = "HTTP \( (response as? HTTPURLResponse)?.statusCode ?? -1): \(bodyString)"
            print("[APIService] Decoding error: response body: \(bodyString)")
            throw APIError.requestFailed(message)
        }
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            // Provide body context for debugging
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            print("[APIService] Decoding error: \(error). Response body: \(bodyString)")
            throw APIError.decodingError
        }
    }
    
    // MARK: - Public API wrappers
    
    // Register user -> returns created User (or wrapper)
    func registerUser(_ payload: [String:Any]) async throws -> User {
        let endpoint = "/api/usuarios"
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
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await request(endpoint, method: "POST", body: body, token: token)
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

    // Fetch reports (optionally authenticated)
    func fetchReports(token: String?) async throws -> [Report] {
        let endpoint = "/api/reportes"
        return try await request(endpoint, method: "GET", token: token)
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
