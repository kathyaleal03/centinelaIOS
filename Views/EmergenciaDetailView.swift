import SwiftUI

struct EmergenciaDetailView: View {
    @ObservedObject var vm: EmergenciaViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var mensaje: String
    @State private var latitudText: String
    @State private var longitudText: String
    @State private var atendido: Bool
    private let originalAtendido: Bool
    @State private var showConfirmAtendido: Bool = false
    @State private var pendingAtendidoChange: Bool = false

    let emergencia: Emergencia

    init(vm: EmergenciaViewModel, emergencia: Emergencia) {
        self.vm = vm
        self.emergencia = emergencia
        _mensaje = State(initialValue: emergencia.mensaje ?? "")
        _latitudText = State(initialValue: emergencia.latitud.map { String($0) } ?? "")
        _longitudText = State(initialValue: emergencia.longitud.map { String($0) } ?? "")
        let orig = emergencia.atendido ?? false
        _atendido = State(initialValue: orig)
        self.originalAtendido = orig
    }

    var body: some View {
        ZStack {
            // Emergency-themed gradient background
            LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)),
                    Color(#colorLiteral(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: (emergencia.atendido ?? false) ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // Status badge (read-only)
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: (emergencia.atendido ?? false) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            Text((emergencia.atendido ?? false) ? "Atendida" : "Activa")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                        Spacer()
                    }
                    
                    // Message (read-only)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .foregroundColor(.red)
                            Text("Mensaje")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text(emergencia.mensaje ?? "(sin mensaje)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Location (read-only)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.red)
                            Text("Ubicación")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Latitud")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(emergencia.latitud.map { String(format: "%.6f", $0) } ?? "-")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Longitud")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(emergencia.longitud.map { String(format: "%.6f", $0) } ?? "-")
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.red)
                            Text("Creada")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text(emergencia.createdAt.map { Self.dateFormatter.string(from: $0) } ?? "-")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding()
            }
        }
        .navigationTitle("Detalle de Emergencia")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        guard let id = emergencia.id else { return }
        let lat = Double(latitudText)
        let lon = Double(longitudText)
        // If the emergencia was already marked as attended, do not allow changing it back.
        let atendidoToSend: Bool? = originalAtendido ? true : atendido

        let update = EmergenciaUpdate(mensaje: mensaje.isEmpty ? nil : mensaje,
                                      latitud: lat,
                                      longitud: lon,
                                      atendido: atendidoToSend)

        vm.update(id: id, with: update) { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async { dismiss() }
            case .failure(let err):
                // Puedes mostrar un alert más adelante; por ahora logueamos
                print("Error updating emergencia: \(err)")
            }
        }
    }

    private func delete() {
        guard let id = emergencia.id else { return }
        vm.delete(id: id) { result in
            switch result {
            case .success():
                DispatchQueue.main.async { dismiss() }
            case .failure(let err):
                print("Error deleting emergencia: \(err)")
            }
        }
    }

    private func attendCancel() {
        // revert any pending change
        pendingAtendidoChange = false
        atendido = originalAtendido
    }

    private static var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
}

struct EmergenciaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = Emergencia(id: 1, mensaje: "Incendio en edificio", latitud: 13.700, longitud: -89.200, atendido: false, createdAt: Date())
        let vm = EmergenciaViewModel()
        return NavigationView {
            EmergenciaDetailView(vm: vm, emergencia: sample)
        }
    }
}
