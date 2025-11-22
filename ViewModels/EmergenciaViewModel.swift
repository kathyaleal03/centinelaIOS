import Foundation
import Combine

@MainActor
public final class EmergenciaViewModel: ObservableObject {
    @Published public var emergencias: [Emergencia] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private let service: EmergenciaService

    public init(service: EmergenciaService = .init()) {
        self.service = service
    }

    public func loadAll() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let items = try await service.getAll()
                // Deduplicate by id if available; otherwise by a generated signature
                var seen = Set<String>()
                var unique: [Emergencia] = []
                for it in items {
                    let key: String
                    if let id = it.id { key = "id:\(id)" }
                    else {
                        let m = it.mensaje ?? ""
                        let lat = it.latitud.map { String($0) } ?? ""
                        let lon = it.longitud.map { String($0) } ?? ""
                        let created = it.createdAt.map { String($0.timeIntervalSince1970) } ?? ""
                        key = "sig:\(m)|\(lat)|\(lon)|\(created)"
                    }
                    if !seen.contains(key) {
                        seen.insert(key)
                        unique.append(it)
                    }
                }
                // Order by createdAt descending (most recent first)
                self.emergencias = unique.sorted(by: { a, b in
                    if let da = a.createdAt, let db = b.createdAt { return da > db }
                    if let ida = a.id, let idb = b.id { return ida > idb }
                    return false
                })
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    public func getById(_ id: Int, completion: @escaping (Result<Emergencia, Error>) -> Void) {
        Task {
            do {
                let e = try await service.getById(id)
                completion(.success(e))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func create(_ emergencia: Emergencia, completion: ((Result<Emergencia, Error>) -> Void)? = nil) {
        Task {
            do {
                let created = try await service.create(emergencia)
                // append locally
                self.emergencias.append(created)
                // Keep list ordered with newest first
                self.emergencias.sort(by: { a, b in
                    if let da = a.createdAt, let db = b.createdAt { return da > db }
                    if let ida = a.id, let idb = b.id { return ida > idb }
                    return false
                })
                completion?(.success(created))
            } catch {
                completion?(.failure(error))
            }
        }
    }

    public func update(id: Int, with update: EmergenciaUpdate, completion: ((Result<Emergencia, Error>) -> Void)? = nil) {
        Task {
            do {
                let updated = try await service.update(id: id, with: update)
                if let idx = self.emergencias.firstIndex(where: { $0.id == updated.id }) {
                    self.emergencias[idx] = updated
                    // keep ordering after update
                    self.emergencias.sort(by: { a, b in
                        if let da = a.createdAt, let db = b.createdAt { return da > db }
                        if let ida = a.id, let idb = b.id { return ida > idb }
                        return false
                    })
                }
                completion?(.success(updated))
            } catch {
                completion?(.failure(error))
            }
        }
    }

    public func delete(id: Int, completion: ((Result<Void, Error>) -> Void)? = nil) {
        Task {
            do {
                try await service.delete(id: id)
                self.emergencias.removeAll { $0.id == id }
                completion?(.success(()))
            } catch {
                completion?(.failure(error))
            }
        }
    }
}
