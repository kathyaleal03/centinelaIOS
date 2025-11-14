//
//  ReportView.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import SwiftUI
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

// Notification name used to notify other views when a report is created
extension Notification.Name {
    static let didCreateReport = Notification.Name("didCreateReport")
}

struct ReportView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var locationService: LocationService
    @StateObject private var vm = ReportViewModel()

    @State private var tipo: String = "Calle inundada"
    @State private var descripcion: String = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var imageURL: String = ""
    @State private var latitud: Double?
    @State private var longitud: Double?
    @State private var mensaje: String?

    private let tipos = ["Calle inundada", "Refugio disponible", "Paso cerrado", "Otro"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Tipo de reporte", selection: $tipo) {
                        ForEach(tipos, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)

                    TextEditor(text: $descripcion)
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // Image URL input + picker preview area
                    VStack(spacing: 8) {
                        HStack {
                            TextField("URL de la imagen (opcional)", text: $imageURL)
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            Button("Previsualizar") { /* no-op, preview updates automatically */ }
                        }
                        .padding(.horizontal)

                        if let ui = selectedImage {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                                .padding(.horizontal)

                            Button("Eliminar foto") { selectedImage = nil }
                                .foregroundColor(.red)
                        } else if let url = URL(string: imageURL), !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                case .failure:
                                    VStack {
                                        Image(systemName: "exclamationmark.triangle")
                                        Text("No se pudo cargar la imagen")
                                    }
                                    .frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Button(action: { showingImagePicker = true }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Agregar foto (opcional)")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }

                    HStack {
                        Button("Usar mi ubicación") {
                            locationService.requestOnce()
                            if let c = locationService.userLocation {
                                latitud = c.latitude
                                longitud = c.longitude
                                mensaje = "Ubicación agregada."
                            } else {
                                mensaje = "Solicitando ubicación... espera unos segundos y vuelve a intentar si no aparece."
                            }
                        }
                        .padding(.horizontal)

                        Spacer()

                        if let la = latitud, let lo = longitud {
                            Text(String(format: "Lat: %.4f, Lon: %.4f", la, lo))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.trailing)
                        } else {
                            Text("Ubicación no seteada")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.trailing)
                        }
                    }

                    Button(action: submitReport) {
                        if vm.sending {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Enviar reporte")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .disabled(vm.sending)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)

                    if let err = vm.error {
                        Text(err)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    if let res = vm.lastPosted {
                        Text("Reporte enviado (id: \(res.reporteId ?? 0))")
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    }
                    if let msg = mensaje {
                        Text(msg).font(.caption).foregroundColor(.gray).padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Reportar incidente")
            .sheet(isPresented: $showingImagePicker) { ImagePicker(image: $selectedImage) }
            .onReceive(vm.$lastPosted) { newReport in
                guard let created = newReport else { return }
                // Schedule a local notification to inform the user (fallback if server push not configured)
                let creatorName = authVM.user?.nombre ?? "Usuario"
                NotificationManager.shared.scheduleLocalNotification(title: "Reporte creado", body: "Nuevo reporte creado por \(creatorName)")

                // Notify other parts of the app (ReportsListView) to refresh
                NotificationCenter.default.post(name: .didCreateReport, object: created)
            }
        }
    }

    func submitReport() {
        // Basic validation
        guard let uid = authVM.user?.id else {
            vm.error = "Debes iniciar sesión para enviar reportes."
            return
        }
        guard let la = latitud, let lo = longitud else {
            vm.error = "Agrega una ubicación al reporte (usar 'Usar mi ubicación')."
            return
        }
        vm.error = nil
        vm.sending = true

        // prefer imageURL when provided
        let trimmed = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let _ = URL(string: trimmed) {
            var usuarioObj: [String:Any] = ["usuarioId": uid]
            if let u = authVM.user {
                usuarioObj["nombre"] = u.nombre
                usuarioObj["correo"] = u.correo
                usuarioObj["contrasena"] = u.contrasena as Any
                usuarioObj["telefono"] = u.telefono as Any
                usuarioObj["departamento"] = u.departamento as Any
                usuarioObj["ciudad"] = u.ciudad as Any
                usuarioObj["region"] = u.region as Any
            }
            let tipoApi = mapTipoToApi(tipo)
            var payload: [String:Any] = [:]
            payload["usuario"] = usuarioObj
            payload["tipo"] = tipoApi
            payload["descripcion"] = descripcion
            payload["latitud"] = la
            payload["longitud"] = lo
            // include multiple possible keys for compatibility with backend naming
            payload["fotoUrl"] = trimmed
            payload["fotoURL"] = trimmed
            payload["urlFoto"] = trimmed
            vm.postReportPayload(payload, token: authVM.token)
            mensaje = "Enviando reporte con URL de imagen..."
            return
        }

        // else if there's a selected image, upload it first then send payload with returned URL
        if let image = selectedImage {
            // Diagnostic info to help debug upload issues
            print("[ReportView] uploading image. size=\(image.size), scale=\(image.scale), hasCGImage=\(image.cgImage != nil), orientation=\(image.imageOrientation.rawValue)")
            ImageUploadService.shared.upload(image: image) { result in
                switch result {
                case .success(let urlString):
                    var usuarioObj: [String:Any] = ["usuarioId": uid]
                    if let u = authVM.user {
                        usuarioObj["nombre"] = u.nombre
                        usuarioObj["correo"] = u.correo
                        usuarioObj["contrasena"] = u.contrasena as Any
                        usuarioObj["telefono"] = u.telefono as Any
                        usuarioObj["departamento"] = u.departamento as Any
                        usuarioObj["ciudad"] = u.ciudad as Any
                        usuarioObj["region"] = u.region as Any
                    }
                    let tipoApi = mapTipoToApi(tipo)
                    var payload: [String:Any] = [:]
                    payload["usuario"] = usuarioObj
                    payload["tipo"] = tipoApi
                    payload["descripcion"] = descripcion
                    payload["latitud"] = la
                    payload["longitud"] = lo
                    payload["fotoUrl"] = urlString
                    payload["fotoURL"] = urlString
                    payload["urlFoto"] = urlString
                    vm.postReportPayload(payload, token: authVM.token)
                    DispatchQueue.main.async { mensaje = "Subiendo imagen y enviando reporte..." }
                case .failure(let err):
                    DispatchQueue.main.async {
                        vm.sending = false
                        vm.error = "Error subiendo imagen: \(err.localizedDescription)"
                    }
                }
            }
            return
        }

        // otherwise send payload without foto
        var usuarioObj: [String:Any] = ["usuarioId": uid]
        if let u = authVM.user {
            usuarioObj["nombre"] = u.nombre
            usuarioObj["correo"] = u.correo
            usuarioObj["contrasena"] = u.contrasena as Any
            usuarioObj["telefono"] = u.telefono as Any
            usuarioObj["departamento"] = u.departamento as Any
            usuarioObj["ciudad"] = u.ciudad as Any
            usuarioObj["region"] = u.region as Any
        }
        let tipoApi = mapTipoToApi(tipo)
        let payload: [String:Any] = [
            "usuario": usuarioObj,
            "tipo": tipoApi,
            "descripcion": descripcion,
            "latitud": la,
            "longitud": lo
        ]
        vm.postReportPayload(payload, token: authVM.token)
        mensaje = "Enviando reporte..."

        // observe result: ReportViewModel will update lastPosted / error
        Task {
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            DispatchQueue.main.async {
                if vm.lastPosted != nil {
                    descripcion = ""
                    selectedImage = nil
                    imageURL = ""
                    mensaje = "Reporte enviado correctamente."
                    vm.sending = false
                }
            }
        }
    }
}

// Helper: map human-readable tipo to API enum value
fileprivate func mapTipoToApi(_ tipo: String) -> String {
    switch tipo {
    case "Calle inundada": return "Calle_inundada"
    case "Refugio disponible": return "Refugio_disponible"
    case "Paso cerrado": return "Paso_cerrado"
    default: return "Otro"
    }
}


// MARK: - ImagePicker (UIKit wrapper)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
