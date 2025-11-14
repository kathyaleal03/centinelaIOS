import SwiftUI

struct ReportsListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ReportViewModel()
    @State private var selectedType: String = "Todos"

    var body: some View {
        NavigationView {
            VStack {
                // Type filter picker
                let tipos = ["Todos"] + Array(Set(vm.reports.map { $0.tipo })).sorted()
                Picker("Tipo", selection: $selectedType) {
                    ForEach(tipos, id: \.self) { t in
                        Text(t).tag(t)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)

                // Date filters quick actions (1 día, 3 días, 7 días, todo)
                HStack(spacing: 10) {
                    Button("1 día") {
                        vm.startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                        vm.endDate = Date()
                    }
                    .buttonStyle(.bordered)

                    Button("3 días") {
                        vm.startDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
                        vm.endDate = Date()
                    }
                    .buttonStyle(.bordered)

                    Button("Última semana") {
                        vm.startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
                        vm.endDate = Date()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Todo") {
                        vm.startDate = nil
                        vm.endDate = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                List {
                    if vm.reports.isEmpty {
                        Text("Cargando reportes...")
                            .foregroundColor(.gray)
                    } else {
                        // Use ViewModel helper which sorts by date (newest first) and applies optional date range and type filters
                        let filtered = vm.filteredReports(type: selectedType)
                        ForEach(filtered) { report in
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
            } // VStack
        } // NavigationView
    } // body
} // struct

struct ReportsListView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsListView()
    }
}
