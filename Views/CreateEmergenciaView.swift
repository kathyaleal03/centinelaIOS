import SwiftUI
import MapKit
import UIKit
import CoreLocation

struct CreateEmergenciaView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var locationService: LocationService
    @ObservedObject var vm: EmergenciaViewModel

    // `direccion` removed — API expects only lat/long, keep UI minimal
    @State private var descripcion: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String?
    @State private var showAuthAlert: Bool = false
    @State private var showLoginSheet: Bool = false

    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 13.9946, longitude: -89.5597), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @State private var showingGeocodeProgress = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Map selector: user can move map so crosshair points to chosen location
                ZStack {
                    Map(coordinateRegion: $region)
                        .frame(height: 260)
                        .cornerRadius(8)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(.blue)
                        .offset(x: 0, y: -20)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: useCurrentLocation) {
                                Image(systemName: "location.fill")
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                        }
                        Spacer()
                    }
                }
                .padding()

                Form {
                    // Mostrar coordenadas seleccionadas (solo usadas como lat/lon)
                    Section(header: Text("Coordenadas")) {
                        HStack {
                            Text("Lat:")
                            Spacer()
                            Text(String(format: "%.6f", region.center.latitude))
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Lon:")
                            Spacer()
                            Text(String(format: "%.6f", region.center.longitude))
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Button(action: copyCoordsToClipboard) { Text("Copiar coordenadas") }
                            Spacer()
                        }
                    }
                    // quick actions are in the Coordenadas section above

                    Section(header: Label("Descripcion", systemImage: "doc.text")) {
                        TextEditor(text: $descripcion)
                            .frame(minHeight: 120)
                    }

                    if let err = errorMessage {
                        Section { Text(err).foregroundColor(.red) }
                    }

                    Section {
                        Button(action: submit) {
                            HStack { Spacer(); if isSending { ProgressView() } else { Text("Enviar") }; Spacer() }
                        }
                        .disabled(isSending || descripcion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("Crear Emergencia")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .alert("Necesitas iniciar sesión", isPresented: $showAuthAlert) {
                Button("Iniciar sesión") { showLoginSheet = true }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Debes iniciar sesión para poder enviar una emergencia.")
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView()
                    .environmentObject(authVM)
                    .environmentObject(locationService)
            }
            .onAppear {
                if let loc = locationService.userLocation {
                    region.center = loc
                }
            }
        }
    }

    private func useCurrentLocation() {
        if let loc = locationService.userLocation {
            region.center = loc
        } else {
            // Request once and update when available
            locationService.requestOnce { coord in
                if let c = coord {
                    DispatchQueue.main.async { region.center = c }
                }
            }
        }
    }

    private func copyCoordsToClipboard() {
        let lat = region.center.latitude
        let lon = region.center.longitude
        let s = String(format: "%.6f, %.6f", lat, lon)
        UIPasteboard.general.string = s
    }

    // reverse-geocoding removed: API requires only lat/long; keep view minimal

    private func submit() {
        isSending = true
        errorMessage = nil

        // Require authentication before sending
        if !authVM.isAuthenticated {
            isSending = false
            showAuthAlert = true
            return
        }

        var payload: [String: Any] = [:]
        // Server expects only coordinates for location plus the message.
        payload["mensaje"] = descripcion
        payload["latitud"] = region.center.latitude
        payload["longitud"] = region.center.longitude

        // Default attended state as boolean false (server expects boolean)
        payload["atendido"] = false

        // Attach the user expected by the backend as nested object { "usuario": { "usuarioId": X } }
        if let uid = authVM.user?.id {
            payload["usuario"] = ["usuarioId": uid]
        } else {
            // If there's no authenticated user, send usuario with id 0 as safe default
            payload["usuario"] = ["usuarioId": 0]
        }

        Task {
            do {
                let token = authVM.token
                let _ = try await APIService.shared.postEmergency(payload: payload, token: token)
                // refresh list and close view
                await MainActor.run {
                    vm.loadAll()
                    isSending = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al enviar: \(error.localizedDescription)"
                    isSending = false
                }
            }
        }
    }

}

struct CreateEmergenciaView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = EmergenciaViewModel()
        CreateEmergenciaView(vm: vm)
            .environmentObject(AuthViewModel())
            .environmentObject(LocationService())
    }
}
