import Foundation

@MainActor
class AlertsViewModel: ObservableObject {
    @Published var alertas: [AppAlert] = []
    @Published var loading: Bool = false
    @Published var error: String?

    func loadAll() {
        loading = true
        error = nil
        Task {
            do {
                let res = try await APIService.shared.fetchAllAlerts()
                // sort by fecha if possible (ISO8601), newest first
                let df = ISO8601DateFormatter()
                self.alertas = res.sorted { a, b in
                    if let sa = a.fecha, let sb = b.fecha,
                       let da = df.date(from: sa), let db = df.date(from: sb) {
                        return da > db
                    }
                    return (a.id ?? 0) > (b.id ?? 0)
                }
            } catch {
                self.error = "No se pudieron obtener alertas: \(error.localizedDescription)"
                self.alertas = []
            }
            self.loading = false
        }
    }

    func create(titulo: String, descripcion: String, nivel: String) async throws -> AppAlert {
        var payload: [String:Any] = ["titulo": titulo, "descripcion": descripcion, "nivel": nivel]
        let created = try await APIService.shared.createAlert(payload)
        // insert at top
        alertas.insert(created, at: 0)
        return created
    }

    func delete(id: Int) async throws {
        _ = try await APIService.shared.deleteAlert(id: id)
        alertas.removeAll { $0.id == id }
    }
}
