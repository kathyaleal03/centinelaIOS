import Foundation
import Combine

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var reportId: Int?

    func load(reportId: Int, token: String?) async {
        self.reportId = reportId
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await APIService.shared.fetchComments(reportId: reportId, token: token)
            self.comments = fetched
        } catch {
            self.errorMessage = "No se pudieron cargar los comentarios: \(error)"
        }
    }

    // Now add requires an explicit reportId to avoid relying on prior `load` having run.
    func add(message: String, reportId: Int, usuarioId: Int?, user: User?, token: String?) async -> Bool {
        let rid = reportId
    // Build payload matching the backend's expected shape: embed reporte and usuario objects
    // Backend JPA mapping expects a nested 'reporte' entity (not just a top-level reporteId),
    // so send { "reporte": { "reporteId": <id> }, "mensaje": "...", "usuario": { "usuarioId": <id> } }
    var payload: [String:Any] = ["mensaje": message]
    payload["reporte"] = ["reporteId": rid]
    if let uid = usuarioId { payload["usuario"] = ["usuarioId": uid] }

        // Debug log to help trace what is being sent
    print("[CommentVM] -> Creating comment payload: \(payload)")
    print("[CommentVM] -> Token: \(token ?? "nil")")

        isLoading = true
        defer { isLoading = false }

        do {
            var created = try await APIService.shared.postCommentPayload(payload, token: token)
            // If server response doesn't include full usuario object, fill optimistic user info so UI shows name immediately
            if created.usuario == nil {
                if let u = user {
                    created.usuario = u
                    created.usuarioId = u.id
                } else if let uid = usuarioId {
                    created.usuarioId = uid
                }
            }
            comments.append(created)
            print("[CommentVM] <- Created comment: \(created)")
            return true
        } catch {
            errorMessage = "Error al crear comentario: \(error)"
            print("[CommentVM] <- Error creating comment: \(error)")
            return false
        }
    }

    func update(comment: Comment, newMessage: String, token: String?) async -> Bool {
        guard let cid = comment.commentId else { return false }
        // Build payload including nested reporte and usuario so JPA mapping on server keeps relations
        var payload: [String:Any] = ["mensaje": newMessage]
        // include comentarioId so server can identify which comment to update
        payload["comentarioId"] = cid
        if let fecha = comment.fecha { payload["fecha"] = fecha }
        if let rid = comment.reporteId { payload["reporte"] = ["reporteId": rid] }
        if let uid = comment.usuarioId { payload["usuario"] = ["usuarioId": uid] }
        do {
            let updated = try await APIService.shared.updateComment(commentId: cid, payload: payload, token: token)
            if let idx = comments.firstIndex(where: { $0.id == updated.id }) {
                comments[idx] = updated
            }
            return true
        } catch {
            errorMessage = "Error al actualizar comentario: \(error)"
            return false
        }
    }

    func delete(comment: Comment, token: String?) async -> Bool {
        guard let cid = comment.commentId else { return false }
        print("[CommentVM] -> Deleting comentarioId: \(cid)")
        do {
            let _ = try await APIService.shared.deleteComment(commentId: cid, token: token)
            comments.removeAll { $0.commentId == cid }
            return true
        } catch {
            // On failure (404), fetch server comments for the report to help diagnostics
            errorMessage = "Error al eliminar comentario: \(error)"
            print("[CommentVM] <- Delete failed: \(error). Fetching server comments for diagnosis...")
            if let rid = comment.reporteId {
                do {
                    let serverComments = try await APIService.shared.fetchComments(reportId: rid, token: token)
                    print("[CommentVM] -> Server comments for reporteId \(rid): \(serverComments.map { $0.commentId ?? -1 })")
                } catch {
                    print("[CommentVM] -> Failed to fetch server comments for diagnosis: \(error)")
                }
            }
            return false
        }
    }
}
