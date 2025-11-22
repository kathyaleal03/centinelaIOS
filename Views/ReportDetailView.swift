import SwiftUI
import MapKit

struct ReportDetailView: View {
    let report: Report
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var commentVM = CommentViewModel()
    @State private var newCommentText: String = ""
    @State private var editingCommentId: String? = nil
    @State private var editingText: String = ""
    @State private var showCommentError: Bool = false

    // Keep a resolvedReport when the server has assigned an id for a locally-created report
    @State private var resolvedReport: Report? = nil
    @State private var isResolvingReport: Bool = false

    private var effectiveReport: Report {
        return resolvedReport ?? report
    }
    
    private var tipoIcon: String {
        let tipo = effectiveReport.tipo.lowercased()
        if tipo.contains("clima") || tipo.contains("weather") { return "cloud.rain.fill" }
        if tipo.contains("camino") || tipo.contains("road") { return "road.lanes" }
        if tipo.contains("inundación") || tipo.contains("flood") { return "water.waves" }
        if tipo.contains("árbol") || tipo.contains("tree") { return "tree.fill" }
        return "exclamationmark.circle.fill"
    }
    
    private var tipoColor: Color {
        let tipo = effectiveReport.tipo.lowercased()
        if tipo.contains("clima") { return .blue }
        if tipo.contains("camino") { return .orange }
        if tipo.contains("inundación") { return .cyan }
        if tipo.contains("árbol") { return .green }
        return .purple
    }

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
                VStack(spacing: 16) {
                    // Image preview card
                    if let foto = effectiveReport.fotoUrl, let url = URL(string: foto) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .frame(height: 200)
                                    ProgressView()
                                }
                            case .success(let img):
                                img
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            case .failure:
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                    Text("No se pudo cargar la imagen")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color.white)
                                .cornerRadius(16)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(height: 200)
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("Sin imagen")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }

                    // Type and ID card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: tipoIcon)
                                .foregroundColor(tipoColor)
                            Text("Tipo de Reporte")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text(effectiveReport.tipo)
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            if let rid = effectiveReport.reporteId {
                                Text("#\(rid)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(tipoColor)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if let estado = report.estado as String? {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(estado)
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
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
                        
                        Text(effectiveReport.descripcion)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Location card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                            Text("Ubicación")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Latitud:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.6f", effectiveReport.latitud))
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Longitud:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.6f", effectiveReport.longitud))
                                    .fontWeight(.medium)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // User info card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("Reportado por")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        if let usuario = effectiveReport.usuario {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(usuario.nombre)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                if let correo = usuario.correo, !correo.isEmpty {
                                    Text(correo)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else if let uid = report.usuarioId {
                            Text("Usuario #\(uid)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Sin información de usuario")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Map action button
                    if effectiveReport.latitud != 0 || effectiveReport.longitud != 0 {
                        Button(action: openInMaps) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Ver en Mapas")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }

                    // COMMENTS SECTION
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .foregroundColor(.blue)
                            Text("Comentarios")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        // Add new comment
                        let canComment = effectiveReport.reporteId != nil
                        HStack(spacing: 12) {
                            TextField("Escribe un comentario...", text: $newCommentText)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .disabled(!canComment || commentVM.isLoading)
                            
                            Button(action: {
                                Task {
                                    guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                    guard let rid = effectiveReport.reporteId else { return }
                                    let success = await commentVM.add(message: newCommentText, reportId: rid, usuarioId: authVM.user?.id, user: authVM.user, token: authVM.token)
                                    if success { newCommentText = "" }
                                }
                            }) {
                                if commentVM.isLoading {
                                    ProgressView()
                                        .frame(width: 44, height: 44)
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "paperplane.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(!canComment || newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || commentVM.isLoading)
                        }
                        
                        if !canComment {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.orange)
                                Text("Los comentarios estarán disponibles después de que el reporte tenga un ID asignado.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if commentVM.isLoading && commentVM.comments.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                        
                        ForEach(commentVM.comments) { comment in
                            let authorText: String = {
                                if let name = comment.usuario?.nombre { return name }
                                if let uid = comment.usuarioId, uid > 0 { return "Usuario #\(uid)" }
                                if comment.commentId == nil { return "Enviando..." }
                                return "Usuario desconocido"
                            }()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.blue)
                                        Text(authorText)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    Spacer()
                                    if let fecha = comment.fecha {
                                        Text(fecha)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if editingCommentId == comment.id {
                                    VStack(spacing: 8) {
                                        TextField("Editar comentario", text: $editingText)
                                            .padding(10)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                        HStack {
                                            Button("Cancelar") {
                                                editingCommentId = nil
                                            }
                                            .foregroundColor(.red)
                                            Spacer()
                                            Button("Guardar") {
                                                Task {
                                                    let _ = await commentVM.update(comment: comment, newMessage: editingText, token: authVM.token)
                                                    editingCommentId = nil
                                                }
                                            }
                                            .foregroundColor(.blue)
                                            .fontWeight(.semibold)
                                        }
                                    }
                                } else {
                                    Text(comment.mensaje)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                if let uid = authVM.user?.id, let cUid = comment.usuarioId, uid == cUid, comment.commentId != nil {
                                    HStack(spacing: 16) {
                                        Button(action: {
                                            editingCommentId = comment.id
                                            editingText = comment.mensaje
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "pencil")
                                                Text("Editar")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                        Button(action: {
                                            Task {
                                                let _ = await commentVM.delete(comment: comment, token: authVM.token)
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "trash")
                                                Text("Eliminar")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6).opacity(0.5))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding()
            }
            .onAppear {
                Task {
                    // Prevent repeated resolve attempts from re-entering the task
                    if isResolvingReport { return }
                    isResolvingReport = true
                    defer { isResolvingReport = false }

                    // If the passed-in report already has an id, load comments immediately
                    if let rid = report.reporteId {
                        await commentVM.load(reportId: rid, token: authVM.token)
                        return
                    }

                    // Otherwise try to resolve the report on the server by matching coordinates and description
                    print("[ReportDetailView] -> resolving report id on appear for local report (no id)")
                    do {
                        let all = try await APIService.shared.fetchReports(token: authVM.token)
                        // Match by coordinates within small epsilon and by description
                        let eps = 0.0005
                        if let found = all.first(where: { r in
                            abs(r.latitud - effectiveReport.latitud) <= eps && abs(r.longitud - effectiveReport.longitud) <= eps && r.descripcion == effectiveReport.descripcion
                        }) {
                            print("[ReportDetailView] -> Resolved server report id: \(String(describing: found.reporteId))")
                            resolvedReport = found
                            if let rid = found.reporteId {
                                await commentVM.load(reportId: rid, token: authVM.token)
                            }
                        } else {
                            print("[ReportDetailView] -> Could not resolve report on server; user may need to wait until server assigns id.")
                        }
                    } catch {
                        print("[ReportDetailView] -> Error resolving report: \(error)")
                    }
                }
            }
        }
        .navigationTitle(effectiveReport.reporteId != nil ? "Reporte #\(effectiveReport.reporteId!)" : "Reporte")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: commentVM.errorMessage) { new in
            showCommentError = new != nil
        }
        .alert(isPresented: $showCommentError) {
            Alert(title: Text("Error"), message: Text(commentVM.errorMessage ?? "Error desconocido"), dismissButton: .default(Text("OK"), action: {
                commentVM.errorMessage = nil
            }))
        }
    }

    private func openInMaps() {
        let lat = effectiveReport.latitud
        let lon = effectiveReport.longitud
        guard lat.isFinite && lon.isFinite else { return }
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
