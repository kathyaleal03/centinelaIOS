//
//  AuthService.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation

class AuthService {
    static let shared = AuthService()
    // Use central APIConstants base URL
    private var baseURL: String {
        return APIConstants.baseURL + "/api/usuarios"
    }
    
    // New registrar that accepts a numeric region id (preferred)
    func registrar(nombre: String, correo: String, contrasena: String, departamento: String, regionId: Int, ciudad: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/registro") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "nombre": nombre,
            "correo": correo,
            "contrasena": contrasena,
            "departamento": departamento,
            "region": regionId,
            "ciudad": ciudad
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }

    // Compatibility overload: accept region as String and attempt to convert to Int.
    // If conversion fails, this will call completion(false).
    func registrar(nombre: String, correo: String, contrasena: String, departamento: String, region: String, ciudad: String, completion: @escaping (Bool) -> Void) {
        if let id = Int(region) {
            registrar(nombre: nombre, correo: correo, contrasena: contrasena, departamento: departamento, regionId: id, ciudad: ciudad, completion: completion)
        } else {
            // Attempt to extract digits if the string contains something like "region_3"
            let digits = region.compactMap { $0.wholeNumberValue }.map(String.init).joined()
            if let id = Int(digits) {
                registrar(nombre: nombre, correo: correo, contrasena: contrasena, departamento: departamento, regionId: id, ciudad: ciudad, completion: completion)
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}
