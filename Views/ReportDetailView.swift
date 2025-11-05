import SwiftUI
import MapKit

struct ReportDetailView: View {
    let report: Report

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image preview
                if let foto = report.fotoUrl, let url = URL(string: foto) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        case .success(let img):
                            img
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                        case .failure:
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                Text("No se pudo cargar la imagen")
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }

                // Metadata
                Group {
                    HStack {
                        Text("Tipo:")
                            .bold()
                        Text(report.tipo)
                        Spacer()
                        if let rid = report.reporteId {
                            Text("#\(rid)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    Text(report.descripcion)
                        .font(.body)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Latitud: \(String(format: "%.6f", report.latitud))")
                            Text("Longitud: \(String(format: "%.6f", report.longitud))")
                        }
                        .font(.caption)
                        Spacer()
                        if let estado = report.estado as String? {
                            Text(estado)
                                .font(.caption2)
                                .padding(6)
                                .background(Color(.systemGray5))
                                .cornerRadius(6)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Usuario")
                            .bold()
                        if let usuario = report.usuario {
                            Text(usuario.nombre)
                            if let correo = usuario.correo, !correo.isEmpty {
                                Text(correo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if let uid = report.usuarioId {
                            Text("ID usuario: \(uid)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Sin información de usuario")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Actions
                if report.latitud != 0 || report.longitud != 0 {
                    Button(action: openInMaps) {
                        HStack {
                            Image(systemName: "map")
                            Text("Ver en Mapas")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(report.reporteId != nil ? "Reporte #\(report.reporteId!)" : "Reporte")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openInMaps() {
        let lat = report.latitud
        let lon = report.longitud
        let urlString = "http://maps.apple.com/?ll=\(lat),\(lon)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct ReportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let r = Report(reporteId: 123, usuarioId: 1, usuario: nil, tipo: "Calle_inundada", descripcion: "Prueba detalle", latitud: 13.692, longitud: -89.218, fotoUrl: nil, estado: "NUEVO")
        NavigationView { ReportDetailView(report: r) }
    }
}
