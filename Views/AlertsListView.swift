import SwiftUI

struct AlertsListView: View {
    @StateObject private var vm = AlertsViewModel()
    @State private var showingCreate = false
    @State private var selected: AppAlert?
    @State private var searchText: String = ""
    @State private var showOnlyWithNivel: Bool = false

    private var filteredAlerts: [AppAlert] {
        let base = vm.alertas
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !showOnlyWithNivel {
            return base
        }
        let term = searchText.lowercased()
        return base.filter { a in
            var matches = true
            if !term.isEmpty {
                let titulo = a.titulo?.lowercased() ?? ""
                let desc = a.descripcion?.lowercased() ?? ""
                let nivel = a.nivel?.lowercased() ?? ""
                matches = titulo.contains(term) || desc.contains(term) || nivel.contains(term)
            }
            if showOnlyWithNivel {
                matches = matches && (a.nivel != nil && !(a.nivel?.isEmpty ?? true))
            }
            return matches
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Weather-themed gradient background
                LinearGradient(
                    colors: [
                        Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.98, alpha: 1.0)),
                        Color(#colorLiteral(red: 0.3, green: 0.65, blue: 0.85, alpha: 1.0))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Group {
                    if vm.loading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Cargando alertas...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    } else if vm.alertas.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("No hay alertas")
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
                        ScrollView {
                            VStack(spacing: 16) {
                                // Search bar & filters
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.secondary)
                                        TextField("Buscar por título, descripción o nivel", text: $searchText)
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
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(12)

                                    HStack {
                                        Toggle(isOn: $showOnlyWithNivel) {
                                            Text("Solo con nivel definido")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                                        Spacer()
                                        Text("\(filteredAlerts.count) resultados")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal)

                                ForEach(filteredAlerts) { alerta in
                                    Button(action: { selected = alerta }) {
                                        AlertCard(alerta: alerta)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Alertas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreate = true }) {
                        Image(systemName: "")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { vm.loadAll() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateAlertView { titulo, descripcion, nivel in
                    Task {
                        do {
                            _ = try await vm.create(titulo: titulo, descripcion: descripcion, nivel: nivel)
                            showingCreate = false
                        } catch {
                            print("Error creando alerta: \(error)")
                        }
                    }
                }
            }
            .sheet(item: $selected) { a in
                NavigationView { AlertDetailView(alerta: a) }
            }
        }
        .onAppear { vm.loadAll() }
    }

    private func shortDate(_ iso: String) -> String {
        if let d = ISO8601DateFormatter().date(from: iso) {
            let f = DateFormatter()
            f.dateStyle = .short
            f.timeStyle = .short
            return f.string(from: d)
        }
        return iso
    }
}

// MARK: - Alert Card Component
struct AlertCard: View {
    let alerta: AppAlert
    
    private var nivelColor: Color {
        guard let nivel = alerta.nivel?.lowercased() else { return .orange }
        switch nivel {
        case "alto", "high": return .red
        case "medio", "medium": return .orange
        case "bajo", "low": return .yellow
        default: return .orange
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Alert icon with level color
                ZStack {
                    Circle()
                        .fill(nivelColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(nivelColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alerta.titulo ?? "-")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let fecha = alerta.fecha {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(shortDate(fecha))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Level badge
                Text(alerta.nivel?.uppercased() ?? "-")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(nivelColor)
                    .cornerRadius(8)
            }
            
            // Description
            if let desc = alerta.descripcion, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func shortDate(_ iso: String) -> String {
        if let d = ISO8601DateFormatter().date(from: iso) {
            let f = DateFormatter()
            f.dateStyle = .short
            f.timeStyle = .short
            return f.string(from: d)
        }
        return iso
    }
}

struct AlertsListView_Previews: PreviewProvider {
    static var previews: some View {
        AlertsListView()
    }
}

