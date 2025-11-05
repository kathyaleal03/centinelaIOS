//
//  AuthService.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation

class AuthService {
    static let shared = AuthService()
    private let baseURL = "https://tuservidorapi.com/api/usuarios"
    
    func registrar(nombre: String, correo: String, contrasena: String, departamento: String, region: String, ciudad: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/registro") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "nombre": nombre,
            "correo": correo,
            "contrasena": contrasena,
            "departamento": departamento,
            "region": region,
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
}
