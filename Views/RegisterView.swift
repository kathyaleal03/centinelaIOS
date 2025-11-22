//
//  RegisterView.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import SwiftUI

struct RegisterView: View {
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    Text("Registro de usuario")
                        .font(.title2)
                        .bold()
                        .padding(.top, 20)
                    
                    Group {
                        TextField("Nombre", text: $viewModel.nombre)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Correo", text: $viewModel.correo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                        
                        SecureField("Contraseña", text: $viewModel.contrasena)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Departamento", text: $viewModel.departamento)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Teléfono", text: $viewModel.telefono)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Picker("Región", selection: $viewModel.region) {
                            ForEach([Region.norte, Region.sur, Region.este, Region.oeste], id: \ .id) { r in
                                // Use the shortName so the picker shows only "Norte", "Sur", etc.
                                Text(r.shortName).tag(r)
                            }
                        }
                        // Use a menu-style picker so long region names are visible instead of truncated segments
                        .pickerStyle(MenuPickerStyle())
                        
                        TextField("Ciudad", text: $viewModel.direccion)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if viewModel.cargando {
                        ProgressView("Registrando...")
                    }
                    
                    Button(action: {
                        viewModel.registrarUsuario()
                    }) {
                        Text("Registrar")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                    
                    if !viewModel.mensajeError.isEmpty {
                        Text(viewModel.mensajeError)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    if viewModel.registroExitoso {
                        Text("✅ Usuario registrado correctamente.")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .padding()
            }
        }
    }
}
