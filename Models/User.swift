//
//  User.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

struct User: Codable, Identifiable {
    let id: Int
    let nombre: String
    // Some backend responses include only usuarioId and nombre; make correo optional to tolerate that.
    let correo: String?
    let contrasena: String?
    let telefono: String?
    let departamento: String?
    let ciudad: String?
    let region: String?

    enum CodingKeys: String, CodingKey {
        case id = "usuarioId"
        case nombre, correo, contrasena, telefono, departamento, ciudad, region
    }
}
