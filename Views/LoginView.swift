//
//  LoginView.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var locationService: LocationService
    
    @State private var correo = ""
    @State private var contrasena = ""
    @State private var isRegisterPresented = false
    @State private var loading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "cloud.rain.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .padding(.top, 40)
                    .foregroundColor(.blue)
                
                Text("AlertaLluvia SV")
                    .font(.largeTitle).bold()
                
                TextField("Correo electrónico", text: $correo)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                SecureField("Contraseña", text: $contrasena)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if !authVM.mensajeError.isEmpty {
                    Text(authVM.mensajeError).foregroundColor(.red).font(.footnote)
                }
                
                Button {
                    Task {
                        loading = true
                        await authVM.login(correo: correo, contrasena: contrasena)
                        loading = false
                    }
                } label: {
                    if loading {
                        ProgressView()
                    } else {
                        Text("Iniciar sesión")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Button(action: { isRegisterPresented = true }) {
                    Text("Crear cuenta")
                }
                .sheet(isPresented: $isRegisterPresented) {
                    RegisterView()
                        .environmentObject(authVM)
                        .environmentObject(locationService)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            NotificationService.shared.requestAuthorization()
            locationService.requestOnce()
        }
    }
}
