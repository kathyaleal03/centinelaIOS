//
//  AuthViewModel.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    // Authentication state
    @Published var isAuthenticated: Bool = false
    @Published var user: User?
    @Published var token: String?

    // Spanish-named properties used by existing Views (RegisterView.swift)
    @Published var nombre: String = ""
    @Published var correo: String = ""
    @Published var contrasena: String = ""
    @Published var departamento: String = ""
    @Published var region: Region = .norte
    @Published var direccion: String = "" // this holds 'ciudad' per backend
    @Published var telefono: String = ""
    @Published var cargando: Bool = false
    @Published var mensajeError: String = ""
    @Published var registroExitoso: Bool = false

    init() {
        // Load saved user/token from UserDefaults
        if let saved = Self.getSavedUser() {
            self.user = saved
            self.token = Self.getToken()
            self.isAuthenticated = (self.token != nil)
        } else {
            self.isAuthenticated = false
        }
    }
    
    func register(nombre: String, correo: String, contrasena: String, departamento: String, region: Region, direccion: String) async {
        // Ajuste de payload para la API Spring Boot: usar los campos esperados por el backend
        // El backend expone campos como usuarioId, nombre, correo, contrasena, telefono, departamento, ciudad, region
        // Build payload. The backend accepts region as a String like "Santa_Ana_Norte".
        var payload: [String:Any] = [
            "nombre": nombre,
            "correo": correo,
            "contrasena": contrasena,
            // backend espera 'ciudad' en lugar de 'direccion'
            "ciudad": direccion,
            // incluir telefono si el formulario lo proporciona
            "telefono": telefono,
            "departamento": departamento
        ]

        // Include region by id (backend expects integer id for region)
        payload["region"] = region.id
        do {
            let created = try await APIService.shared.registerUser(payload)
            // If backend returns created user or wrapper, adapt accordingly.
            self.user = created
            // No token assumed; require login next
            self.isAuthenticated = false
            self.mensajeError = ""
            self.registroExitoso = true
            self.cargando = false
        } catch let apiError as APIError {
            switch apiError {
            case .requestFailed(let msg):
                self.mensajeError = "Error al registrar: \(msg)"
            case .invalidURL:
                self.mensajeError = "Error interno: URL inválida"
            case .decodingError(_):
                self.mensajeError = "Error interno: respuesta inesperada del servidor"
            }
            self.registroExitoso = false
            self.cargando = false
        } catch {
            // Fallback for unknown errors
            self.mensajeError = "Error al registrar: \(error.localizedDescription)"
            self.registroExitoso = false
            self.cargando = false
        }
    }
    
    func login(correo: String, contrasena: String) async {
        do {
            let resp = try await APIService.shared.login(email: correo, password: contrasena)
            self.user = resp.user
            // Backend may or may not return a token. Save only if present.
            if let t = resp.token, !t.isEmpty {
                // Trim whitespace and newlines which sometimes appear in server tokens
                let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
                self.token = trimmed
                Self.saveToken(trimmed)
            } else {
                self.token = nil
                Self.clearToken()
            }
            Self.saveUser(resp.user)
            self.isAuthenticated = true
            self.mensajeError = ""

            // After a successful login, re-register any saved device token so the backend can link it to this user
            NotificationManager.shared.registerSavedTokenWithServer(userId: resp.user.id)
            

        } catch let apiError as APIError {
            // Surface server message when possible
            switch apiError {
            case .requestFailed(let msg):
                self.mensajeError = "Error al iniciar sesión: \(msg)"
            case .invalidURL:
                self.mensajeError = "Error interno: URL inválida"
            case .decodingError(_):
                self.mensajeError = "Error interno: respuesta inesperada del servidor"
            }
            self.isAuthenticated = false
            print("[AuthViewModel] login failed with APIError: \(apiError). mensajeError='\(self.mensajeError)'")
        } catch {
            self.mensajeError = "Error al iniciar sesión: \(error.localizedDescription)"
            self.isAuthenticated = false
            print("[AuthViewModel] login failed with Error: \(error)")
        }
    }
    
    func logout() {
        Self.clearToken()
        Self.clearUser()
        self.token = nil
        self.user = nil
        self.isAuthenticated = false
    }

    // MARK: - Helpers: simple UserDefaults persistence (replaceable with Keychain)
    private static let tokenKey = "auth_token"
    private static let userKey = "auth_user"

    static func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    static func saveToken(_ token: String?) {
        if let t = token {
            UserDefaults.standard.set(t, forKey: tokenKey)
        } else {
            UserDefaults.standard.removeObject(forKey: tokenKey)
        }
    }

    static func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }

    static func getSavedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    static func saveUser(_ user: User?) {
        if let u = user, let data = try? JSONEncoder().encode(u) {
            UserDefaults.standard.set(data, forKey: userKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userKey)
        }
    }

    static func clearUser() {
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    // Convenience bridging method used by the Spanish UI
    func registrarUsuario() {
        // Reset UI state
        self.mensajeError = ""
        self.registroExitoso = false
        self.cargando = true

        Task {
            await register(nombre: nombre, correo: correo, contrasena: contrasena, departamento: departamento, region: region, direccion: direccion)
        }
    }

    // MARK: - Profile update
    /// Update the current user's profile on the server and persist locally.
    /// - Parameters:
    ///   - nombre: Updated display name
    ///   - correo: Updated email
    ///   - telefono: Optional phone
    ///   - departamento: Optional department
    ///   - region: Optional region
    ///   - direccion: Optional city/address
    ///   - newPassword: If provided, the backend will update the user's password
    func updateProfile(nombre: String, correo: String, telefono: String?, departamento: String?, region: Region?, direccion: String?, newPassword: String? = nil) async {
        guard let uid = user?.id else {
            self.mensajeError = "No hay usuario autenticado"
            return
        }

        self.cargando = true
        self.mensajeError = ""

        var payload: [String:Any] = [
            "nombre": nombre,
            "correo": correo
        ]
        if let t = telefono { payload["telefono"] = t }
        if let d = departamento { payload["departamento"] = d }
        if let c = direccion { payload["ciudad"] = c }
    if let r = region { payload["region"] = r.id }
        if let np = newPassword, !np.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["contrasena"] = np
        }

        do {
            let updated = try await APIService.shared.updateUser(userId: uid, payload: payload, token: token)
            // Update local state and persist
            self.user = updated
            Self.saveUser(updated)
            self.mensajeError = ""
        } catch let apiError as APIError {
            switch apiError {
            case .requestFailed(let msg):
                self.mensajeError = "Error al actualizar: \(msg)"
            case .invalidURL:
                self.mensajeError = "Error interno: URL inválida"
            case .decodingError(_):
                self.mensajeError = "Error interno: respuesta inesperada del servidor"
            }
        } catch {
            self.mensajeError = "Error al actualizar: \(error.localizedDescription)"
        }

        self.cargando = false
    }

    /// UI-friendly wrapper to call updateProfile from Views
    func guardarCambios(nombre: String, correo: String, telefono: String?, departamento: String?, region: Region?, direccion: String?, newPassword: String? = nil) {
        Task {
            await updateProfile(nombre: nombre, correo: correo, telefono: telefono, departamento: departamento, region: region, direccion: direccion, newPassword: newPassword)
        }
    }
}
