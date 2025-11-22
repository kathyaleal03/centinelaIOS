import SwiftUI

struct AlertDetailView: View {
    let alerta: AppAlert

    var body: some View {
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header icon with level color
                    ZStack {
                        Circle()
                            .fill(nivelColor.opacity(0.3))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(nivelColor)
                    }
                    .padding(.top, 20)
                    
                    // Title card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text("Título")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text(alerta.titulo ?? "-")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Level and date card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gauge.high")
                                .foregroundColor(.blue)
                            Text("Información")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nivel")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(alerta.nivel?.uppercased() ?? "-")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(nivelColor)
                            }
                            
                            Spacer()
                            
                            if let fecha = alerta.fecha {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Fecha")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(prettyDate(fecha))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Description card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.blue)
                            Text("Descripción")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Text(alerta.descripcion ?? "-")
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // User info card (if available)
                    if let usuario = alerta.usuario {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Creado por")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(usuario.nombre)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                if let correo = usuario.correo {
                                    Text(correo)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Detalle de Alerta")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var nivelColor: Color {
        guard let nivel = alerta.nivel?.lowercased() else { return .orange }
        switch nivel {
        case "alto", "high": return .red
        case "medio", "medium": return .orange
        case "bajo", "low": return .yellow
        default: return .orange
        }
    }

    private func prettyDate(_ iso: String) -> String {
        if let d = ISO8601DateFormatter().date(from: iso) {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: d)
        }
        return iso
    }
}

struct AlertDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let a = AppAlert(id: 1, titulo: "Alerta de prueba", descripcion: "Prueba de alerta", nivel: "alto", fecha: ISO8601DateFormatter().string(from: Date()))
        NavigationView { AlertDetailView(alerta: a) }
    }
}
