//
//  MainTabView.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var adSim = AdSimulator.shared
    @AppStorage("isProUser") private var isProUser: Bool = false
    @State private var showingSubscriptionSheet: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                TabView {
                    HomeView()
                        .tabItem { Label("Home", systemImage: "house.fill") }
                    AlertsListView()
                        .tabItem { Label("Alertas", systemImage: "exclamationmark.triangle.fill") }
                    MapViewWrapper()
                        .tabItem { Label("Mapa", systemImage: "map.fill") }

                    ReportsListView()
                        .tabItem { Label("Reportes", systemImage: "list.bullet") }
                    EmergenciasListView()
                        .tabItem { Label("Emergencia", systemImage: "phone.fill") }

                    ProfileView()
                        .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
                }

                // Banner ad overlay (only for non-pro users)
                if !isProUser && adSim.showBanner {
                    VStack {
                        BannerAdView(type: adSim.bannerType, onSubscribe: { showingSubscriptionSheet = true })
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
                }

                // Interstitial modal
                if !isProUser && adSim.showInterstitial {
                    InterstitialAdView(type: adSim.interstitialType)
                        .zIndex(5)
                        .transition(.opacity)
                }
            }
            .sheet(isPresented: $showingSubscriptionSheet) {
                SubscriptionView(mode: .subscribe)
            }
            .onAppear {
                if !isProUser {
                    adSim.start(intervalSeconds: 40)
                }
            }
            .onDisappear { adSim.stop() }
            .onChange(of: isProUser) { new in
                // Start/stop ad simulator reactively when subscription status changes
                if new {
                    adSim.stop()
                } else {
                    adSim.start(intervalSeconds: 40)
                }
            }


        }
    }
}

