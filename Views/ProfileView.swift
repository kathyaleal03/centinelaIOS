import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var reportVM: ReportViewModel

    @State private var nombre: String = ""
    @State private var correo: String = ""
    @State private var telefono: String = ""
    @State private var departamento: String = ""
    @State private var ciudad: String = ""
    @State private var selectedRegion: Region? = nil
    @State private var statusMessage: String = ""
    @State private var showLogoutAlert: Bool = false
    @State private var isEditing: Bool = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var passwordError: String? = nil
    @State private var showUserReportsSheet: Bool = false
    @State private var showRankingSheet: Bool = false
    @AppStorage("isProUser") private var appIsProUser: Bool = false
    // store proSince as TimeInterval (seconds since 1970) so AppStorage can observe it
    @AppStorage("proSince") private var proSinceInterval: Double = 0
    // Persisted profile image raw data (JPEG). Using AppStorage for automatic view updates.
    @AppStorage("profileImageData") private var profileImageData: Data?
    // In-memory UIImage for display
    @State private var profileImage: UIImage? = nil
    // Selected photo picker item
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // Computed property to get user's report count (tolerates nested usuario.id when usuarioId is missing)
    private var userReportsCount: Int {
        guard let userId = authVM.user?.id else { return 0 }
        // Include both top-level usuarioId and nested usuario?.id to handle backend variations
        return reportVM.reports.filter { ($0.usuarioId ?? $0.usuario?.id) == userId }.count
    }
    
    // Computed property for user title/badge
    private var userTitle: (title: String, icon: String, color: Color)? {
        if userReportsCount >= 5 {
            return ("Usuario Estrella", "star.fill", .yellow)
        } else if userReportsCount >= 3 {
            return ("Usuario Fiable", "checkmark.shield.fill", .blue)
        }
        return nil
    }
    
    // Progress to next level (0.0 to 1.0)
    private var progressToNextLevel: CGFloat {
        if userReportsCount >= 5 {
            return 1.0
        } else if userReportsCount >= 3 {
            // Progress from 3 to 5
            return CGFloat(userReportsCount - 3) / 2.0
        } else {
            // Progress from 0 to 3
            return CGFloat(userReportsCount) / 3.0
        }
    }
    
    // User's reports list with same tolerant matching
    private var userReports: [Report] {
        guard let userId = authVM.user?.id else { return [] }
        return reportVM.reports.filter { ($0.usuarioId ?? $0.usuario?.id) == userId }
            .sorted { a, b in
                if let da = a.fechaDate, let db = b.fechaDate { return da > db }
                if let ra = a.reporteId, let rb = b.reporteId { return ra > rb }
                return true
            }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Weather-themed background gradient
                LinearGradient(
                    colors: [Color(#colorLiteral(red: 0.4745, green: 0.8392, blue: 0.9765, alpha: 1.0)), Color(#colorLiteral(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0))],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header card with user info
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    Group {
                                        if let uiImg = profileImage {
                                            Image(uiImage: uiImg)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.white)
                                                .padding(10)
                                        }
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(
                                        Circle().fill(LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                                    // Edit overlay button (camera icon)
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .semibold))
                                        )
                                        .padding(4)
                                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                                }
                            }
                            .disabled(!authVM.isAuthenticated)
                            
                            Text(nombre.isEmpty ? "Usuario" : nombre)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // User title/badge
                            if let badge = userTitle {
                                HStack(spacing: 6) {
                                    Image(systemName: badge.icon)
                                        .foregroundColor(badge.color)
                                    Text(badge.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(badge.color)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(badge.color.opacity(0.15))
                                .cornerRadius(20)
                            }
                            
                            Text(correo.isEmpty ? "correo@ejemplo.com" : correo)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        // Info cards
                        VStack(spacing: 16) {
                            // Personal info card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                    Text("Información Personal")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                CustomTextField(icon: "person", placeholder: "Nombre", text: $nombre)
                                    .disabled(!isEditing)
                                CustomTextField(icon: "envelope", placeholder: "Correo", text: $correo, keyboardType: .emailAddress)
                                    .disabled(!isEditing)
                                CustomTextField(icon: "phone", placeholder: "Teléfono", text: $telefono, keyboardType: .phonePad)
                                    .disabled(!isEditing)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            // Location card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                    Text("Ubicación")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                CustomTextField(icon: "building.2", placeholder: "Departamento", text: $departamento)
                                    .disabled(!isEditing)
                                CustomTextField(icon: "map", placeholder: "Ciudad", text: $ciudad)
                                    .disabled(!isEditing)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "scope")
                                            .foregroundColor(.blue)
                                            .frame(width: 24)
                                        Text("Región")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Picker("Región", selection: Binding(get: {
                                        selectedRegion ?? Region.norte
                                    }, set: { new in
                                        selectedRegion = new
                                    })) {
                                        HStack {
                                            Image(systemName: "arrow.up.circle.fill")
                                            Text("Norte")
                                        }.tag(Region.norte)
                                        HStack {
                                            Image(systemName: "arrow.down.circle.fill")
                                            Text("Sur")
                                        }.tag(Region.sur)
                                        HStack {
                                            Image(systemName: "arrow.right.circle.fill")
                                            Text("Este")
                                        }.tag(Region.este)
                                        HStack {
                                            Image(systemName: "arrow.left.circle.fill")
                                            Text("Oeste")
                                        }.tag(Region.oeste)
                                    }
                                    .pickerStyle(.menu)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .disabled(!isEditing)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            // User statistics and activity card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(.blue)
                                    Text("Tu Actividad")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Menu {
                                        Button(action: { showUserReportsSheet = true }) {
                                            Label("Ver mi historial", systemImage: "doc.text")
                                        }
                                        Button(action: { showRankingSheet = true }) {
                                            Label("Ver ranking", systemImage: "trophy")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                }
                                // Loading / empty states for activity
                                if reportVM.loadingReports {
                                    HStack(spacing: 12) {
                                        ProgressView()
                                        Text("Cargando reportes...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else if !reportVM.loadingReports && userReportsCount == 0 {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Aún no tienes reportes registrados.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                HStack(spacing: 20) {
                                    // Reports count
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 60, height: 60)
                                            
                                            Text("\(userReportsCount)")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("Reportes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Divider()
                                        .frame(height: 60)
                                    
                                    // Progress to next level
                                    VStack(alignment: .leading, spacing: 8) {
                                        if userReportsCount >= 5 {
                                            HStack {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                Text("¡Nivel máximo alcanzado!")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                        } else if userReportsCount >= 3 {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Siguiente nivel: Usuario Estrella")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text("\(5 - userReportsCount) reportes más")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        } else {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Siguiente nivel: Usuario Fiable")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text("\(3 - userReportsCount) reportes más")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        // Progress bar
                                        if userReportsCount < 5 {
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(height: 8)
                                                    
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                                                        .frame(width: geo.size.width * progressToNextLevel, height: 8)
                                                }
                                            }
                                            .frame(height: 8)
                                        }
                                        // Debug summary for troubleshooting (won't show to user unless in console)
                                        let _ = {
                                            print("[ProfileView] -> userReportsCount=\(userReportsCount), loadingReports=\(reportVM.loadingReports)")
                                            return 0
                                        }()
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                            // Password change card (only in edit mode)
                            if isEditing {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.blue)
                                        Text("Cambiar contraseña")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }

                                    VStack(spacing: 12) {
                                        SecureField("Nueva contraseña", text: $newPassword)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(10)

                                        SecureField("Confirmar contraseña", text: $confirmPassword)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(10)

                                        if let passwordError = passwordError, !passwordError.isEmpty {
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundColor(.red)
                                                Text(passwordError)
                                            }
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(8)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                            
                            // Subscription card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "star.circle.fill")
                                        .foregroundColor(.yellow)
                                    Text("Suscripción")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                if appIsProUser {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text("Pro")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundColor(.blue)
                                            }
                                            if proSinceInterval > 0 {
                                                let since = Date(timeIntervalSince1970: proSinceInterval)
                                                Text("Activo desde: \(since.formatted(.dateTime.year().month().day()))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        NavigationLink(destination: ManageSubscriptionView()) {
                                            HStack {
                                                Text("Gestionar")
                                                Image(systemName: "chevron.right")
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(LinearGradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(12)
                                } else {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Suscripción Pro")
                                                .font(.headline)
                                            Text("$3.99/mes — Sin anuncios")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        NavigationLink(destination: SubscriptionView(mode: .subscribe)) {
                                            Text("Suscribirme")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 20)
                                                .background(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing))
                                                .cornerRadius(10)
                                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            // Action buttons
                            VStack(spacing: 12) {
                                if authVM.cargando {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                } else {
                                    if isEditing {
                                        Button(action: save) {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                Text("Guardar cambios")
                                                    .fontWeight(.semibold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                        }
                                        .disabled(!authVM.isAuthenticated)
                                        .opacity(authVM.isAuthenticated ? 1.0 : 0.5)
                                    }
                                }
                                
                                if !authVM.mensajeError.isEmpty {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text(authVM.mensajeError)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                if !statusMessage.isEmpty {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text(statusMessage)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(8)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                Button(action: { showLogoutAlert = true }) {
                                    HStack {
                                        Image(systemName: "arrow.right.square")
                                        Text("Cerrar sesión")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .disabled(!authVM.isAuthenticated)
                                .opacity(authVM.isAuthenticated ? 1.0 : 0.5)
                                .alert("¿Cerrar sesión?", isPresented: $showLogoutAlert) {
                                    Button("Cerrar sesión", role: .destructive) {
                                        authVM.logout()
                                    }
                                    Button("Cancelar", role: .cancel) { }
                                } message: {
                                    Text("¿Estás seguro que quieres cerrar sesión?")
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Hecho" : "Editar") {
                        withAnimation(.spring()) {
                            if isEditing {
                                // Reset password edits when leaving edit mode
                                newPassword = ""
                                confirmPassword = ""
                                passwordError = nil
                            }
                            isEditing.toggle()
                        }
                    }
                }
            }
            .onAppear {
                loadFromAuth()
                // Load previously saved profile image
                if let data = profileImageData, let ui = UIImage(data: data) {
                    profileImage = ui
                }
                // Trigger report fetch if needed
                if reportVM.reports.isEmpty && !reportVM.loadingReports {
                    print("[ProfileView] -> Fetching reports for activity section")
                    reportVM.fetchReports(token: authVM.token)
                }
            }
            // Handle selection changes from PhotosPicker
            .onChange(of: selectedPhotoItem) { newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                        // Compress to JPEG (quality 0.8) to reduce storage footprint
                        let compressedData = ui.jpegData(compressionQuality: 0.8) ?? data
                        profileImageData = compressedData
                        profileImage = UIImage(data: compressedData)
                        print("[ProfileView] -> Profile image updated & persisted (")
                    }
                }
            }
            .sheet(isPresented: $showUserReportsSheet) {
                UserReportsHistoryView(reports: userReports)
            }
            .sheet(isPresented: $showRankingSheet) {
                UsersRankingView()
                    .environmentObject(reportVM)
            }
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

    // Helpers removed: using @AppStorage properties so view updates automatically

    private func save() {
        // Reset status
        statusMessage = ""
        // Validate password if provided
        if !newPassword.isEmpty || !confirmPassword.isEmpty {
            guard newPassword.count >= 6 else {
                passwordError = "La contraseña debe tener al menos 6 caracteres"
                return
            }
            guard newPassword == confirmPassword else {
                passwordError = "Las contraseñas no coinciden"
                return
            }
        }
        passwordError = nil
        // Call ViewModel to save
        authVM.guardarCambios(
            nombre: nombre,
            correo: correo,
            telefono: telefono.isEmpty ? nil : telefono,
            departamento: departamento.isEmpty ? nil : departamento,
            region: selectedRegion,
            direccion: ciudad.isEmpty ? nil : ciudad,
            newPassword: newPassword.isEmpty ? nil : newPassword
        )
        // Provide optimistic feedback; actual error message is shown via authVM.mensajeError
        statusMessage = "Solicitando actualización..."

        // Observe authVM changes to update feedback (simple delay to allow network call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if authVM.mensajeError.isEmpty {
                statusMessage = "Perfil actualizado"
                withAnimation(.spring()) {
                    isEditing = false
                    newPassword = ""
                    confirmPassword = ""
                }
            } else {
                statusMessage = ""
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

// MARK: - Custom TextField Component
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

