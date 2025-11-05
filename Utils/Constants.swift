//
//  Constants.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation

struct APIConstants {
    // Point to local Spring Boot API (use your machine IP on the same LAN)
    static let baseURL = "http://192.168.1.25:8080" // example: http://192.168.1.25:8080
    // Increase timeout temporarily for debugging slow or LAN servers
    static let timeout: TimeInterval = 60
}
