//
//  MapView.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import SwiftUI
import MapKit

struct MapViewWrapper: View {
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var vm: ReportViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 13.9946, longitude: -89.5597), // Santa Ana
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedReport: Report?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Only annotate reports that have finite coordinates to avoid passing NaN to Map/CG
                Map(coordinateRegion: $region, annotationItems: vm.reports.filter { $0.latitud.isFinite && $0.longitud.isFinite }) { report in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: report.latitud, longitude: report.longitud)) {
                        Button(action: {
                            selectedReport = report
                        }) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(colorForTipo(report.tipo))
                                Text(shorten(report.tipo))
                                    .font(.caption2)
                                    .padding(2)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Button(action: recenterMap) {
                            Image(systemName: "location.fill")
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        Spacer()
                        NavigationLink(destination: ReportView()
                            .environmentObject(authVM)
                            .environmentObject(locationService)) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.blue)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 40)
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                vm.fetchReports(token: authVM.token)
                if let loc = locationService.userLocation, loc.latitude.isFinite && loc.longitude.isFinite {
                    region.center = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                }
            }
            .sheet(item: $selectedReport) { report in
                ReportDetailSheet(report: report)
            }
        }
    }
    
    func recenterMap() {
        if let loc = locationService.userLocation, loc.latitude.isFinite && loc.longitude.isFinite {
            region.center = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        }
    }
    
    func colorForTipo(_ tipo: String) -> Color {
        switch tipo {
        case "Calle inundada": return .blue
        case "Paso cerrado": return .orange
        case "Refugio disponible": return .green
        default: return .gray
        }
    }
    
    func shorten(_ tipo: String) -> String {
        switch tipo {
        case "Calle inundada": return "Inund."
        case "Paso cerrado": return "Paso"
        case "Refugio disponible": return "Refugio"
        default: return "Otro"
        }
    }
}

// MARK: - Sheet con detalles del reporte
struct ReportDetailSheet: View {
    let report: Report
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(report.tipo)
                    .font(.title2)
                    .bold()
                Text(report.descripcion)
                    .font(.body)
                
                if let foto = report.fotoUrl, let url = URL(string: foto) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit().cornerRadius(8)
                    } placeholder: {
                        ProgressView().frame(height: 180)
                    }
                }
                
                Divider()
                Text("Estado: \(report.estado)")
                    .font(.headline)
              
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
        }
    }
    
    func formattedDate(_ dateStr: String?) -> String {
        guard let dateStr = dateStr else { return "" }
        if let date = ISO8601DateFormatter().date(from: dateStr) {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: date)
        }
        return dateStr
    }
}
