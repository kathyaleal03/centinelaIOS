import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var nombre: String = ""
    @State private var correo: String = ""
    @State private var telefono: String = ""
    @State private var departamento: String = ""
    @State private var ciudad: String = ""
    @State private var selectedRegion: Region? = nil
    @State private var statusMessage: String = ""
    @State private var showLogoutAlert: Bool = false
    // Password change fields
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var passwordMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información personal")) {
                    TextField("Nombre", text: $nombre)
                    TextField("Correo", text: $correo)
                        .keyboardType(.emailAddress)
                    TextField("Teléfono", text: $telefono)
                        .keyboardType(.phonePad)
                }

                Section(header: Text("Ubicación")) {
                    TextField("Departamento", text: $departamento)
                    TextField("Ciudad", text: $ciudad)
                    Picker("Región", selection: Binding(get: {
                        selectedRegion ?? Region.norte
                    }, set: { new in
                        selectedRegion = new
                    })) {
                        Text("Norte").tag(Region.norte)
                        Text("Sur").tag(Region.sur)
                        Text("Este").tag(Region.este)
                        Text("Oeste").tag(Region.oeste)
                    }
                }

                Section {
                    if authVM.cargando {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    } else {
                        Button(action: save) {
                            Text("Guardar cambios")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!authVM.isAuthenticated)
                    }

                    if !authVM.mensajeError.isEmpty {
                        Text(authVM.mensajeError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                Section(header: Text("Cambiar contraseña")) {
                    SecureField("Contraseña actual (opcional)", text: $currentPassword)
                    SecureField("Nueva contraseña", text: $newPassword)
                    SecureField("Confirmar nueva contraseña", text: $confirmPassword)

                    if !passwordMessage.isEmpty {
                        Text(passwordMessage)
                            .font(.caption)
                            .foregroundColor(passwordMessage.contains("error") || passwordMessage.contains("Error") ? .red : .green)
                    }

                    Button(action: changePasswordTapped) {
                        Text("Cambiar contraseña")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!authVM.isAuthenticated || newPassword.isEmpty || confirmPassword.isEmpty)
                }

                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        Text("Cerrar sesión")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!authVM.isAuthenticated)
                    .alert("¿Cerrar sesión?", isPresented: $showLogoutAlert) {
                        Button("Cerrar sesión", role: .destructive) {
                            authVM.logout()
                        }
                        Button("Cancelar", role: .cancel) { }
                    } message: {
                        Text("¿Estás seguro que quieres cerrar sesión?")
                    }
                }
            }
            .navigationTitle("Mi perfil")
            .onAppear(perform: loadFromAuth)
        }
    }

    private func loadFromAuth() {
        if let u = authVM.user {
            nombre = u.nombre
            correo = u.correo ?? ""
            telefono = u.telefono ?? ""
            departamento = u.departamento ?? ""
            ciudad = u.ciudad ?? ""
            selectedRegion = Region.from(name: u.region ?? "") ?? Region.norte
        } else {
            // If not authenticated, clear fields
            nombre = ""
            correo = ""
            telefono = ""
            departamento = ""
            ciudad = ""
            selectedRegion = Region.norte
        }
    }

    private func save() {
        // Reset status
        statusMessage = ""
        // Call ViewModel to save
        authVM.guardarCambios(nombre: nombre, correo: correo, telefono: telefono.isEmpty ? nil : telefono, departamento: departamento.isEmpty ? nil : departamento, region: selectedRegion, direccion: ciudad.isEmpty ? nil : ciudad)
        // Provide optimistic feedback; actual error message is shown via authVM.mensajeError
        statusMessage = "Solicitando actualización..."

        // Observe authVM changes to update feedback (simple delay to allow network call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if authVM.mensajeError.isEmpty {
                statusMessage = "Perfil actualizado"
            } else {
                statusMessage = ""
            }
        }
    }

    private func changePasswordTapped() {
        passwordMessage = ""
        // Basic client-side validation
        guard !newPassword.isEmpty else {
            passwordMessage = "La nueva contraseña no puede estar vacía"
            return
        }
        guard newPassword == confirmPassword else {
            passwordMessage = "Las contraseñas no coinciden"
            return
        }
        // Optional: enforce minimum length
        if newPassword.count < 6 {
            passwordMessage = "La contraseña debe tener al menos 6 caracteres"
            return
        }

        // Call ViewModel to perform change
        authVM.cambiarContrasena(current: currentPassword.isEmpty ? nil : currentPassword, nueva: newPassword)
        passwordMessage = "Solicitando cambio de contraseña..."

        // Observe result shortly after
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if authVM.mensajeError.isEmpty {
                passwordMessage = "Contraseña actualizada"
                // Clear fields
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            } else {
                passwordMessage = "Error: \(authVM.mensajeError)"
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
