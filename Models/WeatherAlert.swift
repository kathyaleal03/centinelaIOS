//
//  WeatherAlert.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation

struct WeatherAlertResponse: Codable {
    // Example from OpenWeatherMap; adapt según tu API
    let id: Int?
    let title: String?
    let description: String?
    let level: String?
    
    // If you use OpenWeather 'alerts' structure, adapta aquí.
}
