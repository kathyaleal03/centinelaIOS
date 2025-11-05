import SwiftUI

struct ReportsListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ReportViewModel()

    var body: some View {
        NavigationView {
            List {
                if vm.reports.isEmpty {
                    Text("Cargando reportes...")
                        .foregroundColor(.gray)
                } else {
                    ForEach(vm.reports) { report in
                        NavigationLink(destination: ReportDetailView(report: report)) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(report.tipo)
                                        .font(.headline)
                                    Spacer()
                                    if let id = report.reporteId {
                                        Text("#\(id)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }

                                Text(report.descripcion)
                                    .font(.subheadline)

                                HStack {
                                    Text("Creado por: \(report.usuario?.nombre ?? String(report.usuarioId ?? 0))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "Lat: %.4f", report.latitud))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Reportes")
            .refreshable {
                vm.fetchReports(token: authVM.token)
            }
            .onAppear {
                vm.fetchReports(token: authVM.token)
            }
            .onReceive(NotificationCenter.default.publisher(for: .didCreateReport)) { _ in
                // When a report is created elsewhere, refresh the list
                vm.fetchReports(token: authVM.token)
            }
        }
    }
}

struct ReportsListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsListView()
    }
}
