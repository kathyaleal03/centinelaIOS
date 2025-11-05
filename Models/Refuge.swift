//
//  Refuge.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation
import CoreLocation

struct Refuge: Codable, Identifiable {
    var id: Int?
    var nombre: String
    var direccion: String
    // Nuevo esquema: guardamos la region como id y opcionalmente podemos mapear Region
    var regionId: Int?
    var region: Region?
    var latitud: Double
    var longitud: Double
    var capacidad: Int?
    var disponible: Bool
}
