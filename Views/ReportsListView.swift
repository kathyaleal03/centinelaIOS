import SwiftUI

struct ReportsListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var vm: ReportViewModel
    @State private var selectedType: String = "Todos"

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
                
                VStack(spacing: 0) {
                    // Type filter section
                    let tipos = ["Todos"] + Array(Set(vm.reports.map { $0.tipo })).sorted()
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.white)
                            Text("Filtrar por tipo")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        Picker("Tipo", selection: $selectedType) {
                            ForEach(tipos, id: \.self) { t in
                                Text(t).tag(t)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    
                    // Reports list
                    if vm.reports.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Cargando reportes...")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                let filtered = vm.filteredReports(type: selectedType)
                                ForEach(filtered) { report in
                                    NavigationLink(destination: ReportDetailView(report: report)) {
                                        ReportCard(report: report)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Reportes")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                vm.fetchReports(token: authVM.token)
            }
            .onAppear {
                vm.fetchReports(token: authVM.token)
            }
            .onReceive(NotificationCenter.default.publisher(for: .didCreateReport)) { _ in
                vm.fetchReports(token: authVM.token)
            }
        }
    } // body
} // struct

// MARK: - Report Card Component
struct ReportCard: View {
    let report: Report
    
    private var tipoIcon: String {
        let tipo = report.tipo.lowercased()
        if tipo.contains("clima") || tipo.contains("weather") { return "cloud.rain.fill" }
        if tipo.contains("camino") || tipo.contains("road") { return "road.lanes" }
        if tipo.contains("inundación") || tipo.contains("flood") { return "water.waves" }
        if tipo.contains("árbol") || tipo.contains("tree") { return "tree.fill" }
        return "exclamationmark.circle.fill"
    }
    
    private var tipoColor: Color {
        let tipo = report.tipo.lowercased()
        if tipo.contains("clima") { return .blue }
        if tipo.contains("camino") { return .orange }
        if tipo.contains("inundación") { return .cyan }
        if tipo.contains("árbol") { return .green }
        return .purple
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Report type icon
                ZStack {
                    Circle()
                        .fill(tipoColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: tipoIcon)
                        .font(.title3)
                        .foregroundColor(tipoColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.tipo)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let id = report.reporteId {
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.caption2)
                            Text("\(id)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            
            // Description
            Text(report.descripcion)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Divider()
            
            // Metadata
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.caption)
                    Text(report.usuario?.nombre ?? "Usuario \(report.usuarioId ?? 0)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "location.circle")
                        .font(.caption)
                    Text(String(format: "%.4f, %.4f", report.latitud, report.longitud))
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct ReportsListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsListView()
    }
}
