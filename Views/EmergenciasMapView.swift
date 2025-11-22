import SwiftUI
import MapKit

struct EmergenciasMapView: View {
    @ObservedObject var vm: EmergenciaViewModel
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var authVM: AuthViewModel

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 13.9946, longitude: -89.5597),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @State private var selectedEmergencia: Emergencia?

    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: vm.emergencias.filter { ($0.latitud ?? .nan).isFinite && ($0.longitud ?? .nan).isFinite }) { e in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: e.latitud ?? 0, longitude: e.longitud ?? 0)) {
                        Button(action: { selectedEmergencia = e }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor((e.atendido ?? false) ? .green : .red)
                                if let msg = e.mensaje {
                                    Text(msg.prefix(20) + (msg.count > 20 ? "…" : ""))
                                        .font(.caption2)
                                        .padding(4)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea()

                // Small debug/info overlay showing how many emergencias are loaded
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Emergencias: \(vm.emergencias.count)")
                                .font(.caption)
                                .bold()
                                .padding(6)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                            if vm.emergencias.isEmpty {
                                Text("No hay emergencias cargadas")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    Spacer()
                }

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
                    }
                    .padding(.horizontal)
                    .padding(.top, 44)
                    Spacer()
                }
            }
            .navigationBarTitle("Emergencias", displayMode: .inline)
            .onAppear {
                vm.loadAll()
                print("[EmergenciasMapView] onAppear - emergencias count = \(vm.emergencias.count)")
                if let loc = locationService.userLocation, loc.latitude.isFinite && loc.longitude.isFinite {
                    region.center = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                }
            }
            .onChange(of: vm.emergencias) { newValue in
                print("[EmergenciasMapView] emergencias changed, count=\(newValue.count)")
            }
            .sheet(item: $selectedEmergencia) { e in
                NavigationView {
                    EmergenciaDetailView(vm: vm, emergencia: e)
                        .environmentObject(locationService)
                }
            }
        }
    }

    func recenterMap() {
        if let loc = locationService.userLocation, loc.latitude.isFinite && loc.longitude.isFinite {
            region.center = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
        }
    }
}

// Emergencia already conforms to Identifiable in Models/Emergencia.swift

struct EmergenciasMapView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = EmergenciaViewModel()
        vm.emergencias = [
            Emergencia(id: 1, mensaje: "Incendio", latitud: 13.7, longitud: -89.2, atendido: false, createdAt: Date()),
            Emergencia(id: 2, mensaje: "Inundación", latitud: 13.8, longitud: -89.3, atendido: true, createdAt: Date())
        ]
        return EmergenciasMapView(vm: vm)
            .environmentObject(LocationService())
            .environmentObject(AuthViewModel())
    }
}
