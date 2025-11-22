import SwiftUI

struct EmergenciasListView: View {
    @StateObject private var vm = EmergenciaViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var locationService: LocationService
    @State private var showingCreate = false
    @State private var showingMap = false
    @State private var searchText: String = ""

    private var filteredEmergencias: [Emergencia] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return vm.emergencias }
        let term = searchText.lowercased()
        return vm.emergencias.filter { e in
            (e.mensaje?.lowercased() ?? "").contains(term)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Emergency-themed gradient background (red tones)
                LinearGradient(
                    colors: [
                        Color(#colorLiteral(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)),
                        Color(#colorLiteral(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Group {
                    if vm.isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Cargando emergencias...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    } else if vm.emergencias.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "sos")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("No hay emergencias activas")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Button(action: { vm.loadAll() }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refrescar")
                                }
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                // Search bar only (historial de "mis" emergencias removido)
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.secondary)
                                        TextField("Buscar emergencia por mensaje", text: $searchText)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                        if !searchText.isEmpty {
                                            Button(action: { searchText = "" }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(10)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    HStack {
                                        Text("\(filteredEmergencias.count) resultados")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }

                                ForEach(filteredEmergencias.indices, id: \.self) { idx in
                                    let item = filteredEmergencias[idx]
                                    NavigationLink(destination: EmergenciaDetailView(vm: vm, emergencia: item)) {
                                        EmergenciaCard(emergencia: item)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Emergencias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { vm.loadAll() }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                        }
                        Button(action: { showingMap = true }) {
                            Image(systemName: "map.fill")
                                .foregroundColor(.white)
                        }
                        Button(action: { showingCreate = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateEmergenciaView(vm: vm)
                    .environmentObject(authVM)
                    .environmentObject(locationService)
            }
            .sheet(isPresented: $showingMap) {
                EmergenciasMapView(vm: vm)
                    .environmentObject(locationService)
                    .environmentObject(authVM)
            }
        }
        .onAppear { vm.loadAll() }
        .onChange(of: searchText) { _ in
            print("[EmergenciasListView] search='\(searchText)', filtered=\(filteredEmergencias.count)")
        }
    }
}

// MARK: - Emergencia Card Component
struct EmergenciaCard: View {
    let emergencia: Emergencia
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Emergency icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 50, height: 50)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(emergencia.mensaje ?? "(sin mensaje)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let created = emergencia.createdAt {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(formatDate(created))
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Status badge
                if emergencia.atendido ?? false {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Atendido")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Activa")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            // Location info
            if let lat = emergencia.latitud, let lon = emergencia.longitud {
                HStack(spacing: 8) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.white.opacity(0.9))
                    Text(String(format: "%.4f, %.4f", lat, lon))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EmergenciasListView_Previews: PreviewProvider {
    static var previews: some View {
        EmergenciasListView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocationService())
    }
}

