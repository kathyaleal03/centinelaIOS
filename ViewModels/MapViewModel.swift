//
//  MapViewModel.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation
import CoreLocation

@MainActor
class MapViewModel: ObservableObject {
    @Published var refugios: [Refuge] = []
    @Published var reportes: [Report] = []
    @Published var loading = false
    @Published var error: String?
    
    // Load refuges by Region model
    func loadRefuges(region: Region) {
        Task {
            await fetchRefuges(regionId: region.id)
        }
    }

    // Load refuges by region id
    func loadRefuges(regionId: Int) {
        Task {
            await fetchRefuges(regionId: regionId)
        }
    }

    private func fetchRefuges(regionId: Int) async {
        loading = true
        do {
            let rr = try await APIService.shared.fetchRefuges(regionId: regionId)
            self.refugios = rr
            self.error = nil
        } catch {
            self.error = "Error al cargar refugios: \(error.localizedDescription)"
            self.refugios = []
        }
        loading = false
    }
}
