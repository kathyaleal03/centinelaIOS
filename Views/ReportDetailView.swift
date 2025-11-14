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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image preview
                if let foto = effectiveReport.fotoUrl, let url = URL(string: foto) {
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
                        Text(effectiveReport.tipo)
                        Spacer()
                        if let rid = effectiveReport.reporteId {
                            Text("#\(rid)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    Text(effectiveReport.descripcion)
                        .font(.body)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Latitud: \(String(format: "%.6f", effectiveReport.latitud))")
                            Text("Longitud: \(String(format: "%.6f", effectiveReport.longitud))")
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
                        if let usuario = effectiveReport.usuario {
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
                if effectiveReport.latitud != 0 || effectiveReport.longitud != 0 {
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

                // COMMENTS SECTION
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comentarios")
                        .font(.headline)

                    // Add new comment
                    let canComment = effectiveReport.reporteId != nil
                    HStack {
                        TextField("Escribe un comentario...", text: $newCommentText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!canComment || commentVM.isLoading)
                        Button(action: {
                            print("[ReportDetailView] -> Send button tapped. Message: \(newCommentText)")
                            Task {
                                guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                guard let rid = effectiveReport.reporteId else {
                                    print("[ReportDetailView] -> No reportId available, cannot send comment")
                                    return
                                }
                                let success = await commentVM.add(message: newCommentText, reportId: rid, usuarioId: authVM.user?.id, user: authVM.user, token: authVM.token)
                                if success { newCommentText = "" }
                            }
                        }) {
                            if commentVM.isLoading {
                                ProgressView()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .disabled(!canComment || newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || commentVM.isLoading)
                    }

                    if !canComment {
                        Text("Los comentarios estarán disponibles después de que el reporte tenga un ID asignado por el servidor.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if commentVM.isLoading {
                        ProgressView()
                    }

                    ForEach(commentVM.comments) { comment in
                        // compute author text as a plain String to keep the view builder simpler
                        let authorText: String = {
                            if let name = comment.usuario?.nombre { return name }
                            if let uid = comment.usuarioId, uid > 0 { return "Usuario #\(uid)" }
                            if comment.commentId == nil { return "Enviando..." }
                            return "Usuario desconocido"
                        }()

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(authorText)
                                    .bold()
                                Spacer()
                                if let fecha = comment.fecha {
                                    Text(fecha)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if editingCommentId == comment.id {
                                TextField("Editar comentario", text: $editingText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                HStack {
                                    Button("Cancelar") {
                                        editingCommentId = nil
                                    }
                                    Spacer()
                                    Button("Guardar") {
                                        Task {
                                            let _ = await commentVM.update(comment: comment, newMessage: editingText, token: authVM.token)
                                            editingCommentId = nil
                                        }
                                    }
                                }
                            } else {
                                Text(comment.mensaje)
                            }

                            // Edit/Delete for own comments
                            // Only allow edit/delete when the comment has a server id and belongs to the current user
                            if let uid = authVM.user?.id, let cUid = comment.usuarioId, uid == cUid, comment.commentId != nil {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        editingCommentId = comment.id
                                        editingText = comment.mensaje
                                    }) {
                                        Image(systemName: "pencil")
                                    }
                                    Button(action: {
                                        Task {
                                            let _ = await commentVM.delete(comment: comment, token: authVM.token)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }

                Spacer()
            }
            .padding()
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
                            abs(r.latitud - report.latitud) <= eps && abs(r.longitud - report.longitud) <= eps && r.descripcion == report.descripcion
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
        .navigationTitle(report.reporteId != nil ? "Reporte #\(report.reporteId!)" : "Reporte")
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
        let lat = report.latitud
        let lon = report.longitud
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
