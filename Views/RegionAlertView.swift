//
//  RegionAlertView.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import SwiftUI

struct RegionAlertView: View {
    @ObservedObject var viewModel = WeatherViewModel()
    // Store region as String in AppStorage, but convert when used
    @AppStorage("region") var userRegion: String = ""
    
    var body: some View {
        VStack {
            Text("Alertas para \(userRegion)")
                .font(.headline)
                .padding()
            
            if viewModel.alertas.isEmpty {
                Text("Sin alertas activas")
                    .foregroundColor(.gray)
            } else {
                // Filter alerts by selected region (match API region.regionId to Region.id)
                let regionModel = Region.from(name: userRegion) ?? .norte
                let filtered = viewModel.alertas.filter { $0.region?.regionId == regionModel.id }

                if filtered.isEmpty {
                    Text("No hay alertas para esta región")
                        .foregroundColor(.secondary)
                } else {
                    List(filtered) { alerta in
                        VStack(alignment: .leading) {
                            Text(alerta.titulo ?? "-")
                                .bold()
                            Text(alerta.descripcion ?? "-")
                            Text("Nivel: \(alerta.nivel ?? "-")")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                }
            }
            NavigationLink(destination: AlertsListView()) {
                Text("Ver todas las alertas")
                    .font(.subheadline)
                    .padding(.vertical, 8)
            }
        }
        .onAppear {
            // Convert stored string to Region model; default to .norte
            let regionModel = Region.from(name: userRegion) ?? .norte
            viewModel.obtenerAlertas(region: regionModel)
        }
    }
}
