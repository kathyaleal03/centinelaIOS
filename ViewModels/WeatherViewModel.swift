//
//  WeatherViewModel.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var alertas: [AppAlert] = []
    @Published var loading: Bool = false
    @Published var error: String?
    
    func obtenerAlertas(region: Region) {
        Task {
            await fetch(regionId: region.id)
        }
    }

    func obtenerAlertas(regionId: Int) {
        Task {
            await fetch(regionId: regionId)
        }
    }

    private func fetch(regionId: Int) async {
        loading = true
        do {
            let res = try await APIService.shared.fetchAlerts(regionId: regionId)
            self.alertas = res
            self.error = nil
        } catch {
            self.error = "No se pudo obtener alertas: \(error.localizedDescription)"
            self.alertas = []
        }
        loading = false
    }
}
