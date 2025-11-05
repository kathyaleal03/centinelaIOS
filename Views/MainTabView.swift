//
//  MainTabView.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        TabView {
            RegionAlertView()
                .tabItem { Label("Alertas", systemImage: "exclamationmark.triangle.fill") }
            MapViewWrapper()
                .tabItem { Label("Mapa", systemImage: "map.fill") }
            ReportsListView()
                .tabItem { Label("Reportes", systemImage: "list.bullet") }
            EmergencyButtonView()
                .tabItem { Label("Emergencia", systemImage: "phone.fill") }
            CommunityView()
                .tabItem { Label("Comunidad", systemImage: "person.3.fill") }
            InfoCenterView()
                .tabItem { Label("Información", systemImage: "info.circle") }
        }
    }
}
