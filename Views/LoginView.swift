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
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bienvenido")
                        .font(.system(size: 40, weight: .bold))
                    Text("a Centinela")
                        .font(.title2)
                        .foregroundColor(Color("AccentColor"))
                }
                .padding(.top, 40)

                // Card with inputs and overlapping image
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 6)

                    VStack(spacing: 16) {
                        Group {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Correo:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("ejemplo@correo.com", text: $correo)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Contraseña")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                SecureField("********", text: $contrasena)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            }
                        }

                        if !authVM.mensajeError.isEmpty {
                            Text(authVM.mensajeError)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }

                        Button(action: loginAction) {
                            if loading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Iniciar Sesión")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color(#colorLiteral(red: 0.1176, green: 0.4235, blue: 0.6, alpha: 1)))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, 6)
                    }
                    .padding(24)

                    // Decorative robot image overlapping the card
                    Group {
                        if UIImage(named: "robot") != nil {
                            Image("robot")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .offset(x: 20, y: -30)
                        } else {
                            // Fallback illustration using a system image
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(Color(#colorLiteral(red: 0.1176, green: 0.4235, blue: 0.6, alpha: 1)))
                                .offset(x: 12, y: -20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 320)

                Spacer()

                // Register link at bottom
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        NavigationLink(destination: RegisterView().environmentObject(authVM).environmentObject(locationService)) {
                            HStack(spacing: 6) {
                                Text("¿No tienes una cuenta?")
                                    .foregroundColor(.primary)
                                Text("Regístrate")
                                    .foregroundColor(Color(#colorLiteral(red: 0.1176, green: 0.4235, blue: 0.6, alpha: 1)))
                                    .underline()
                            }
                        }

                        // Allow viewing the onboarding before logging in
                        Button(action: { showingOnboarding = true }) {
                            Text("Ver introducción")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .sheet(isPresented: $showingOnboarding) {
                            OnboardingView()
                        }
                    }
                    Spacer()
                }

            }
            .padding(.horizontal, 24)
            .navigationBarHidden(true)
        }
        .onAppear {
            NotificationService.shared.requestAuthorization()
            locationService.requestOnce()
        }
    }
}

// MARK: - Actions
extension LoginView {
    private func loginAction() {
        Task {
            loading = true
            await authVM.login(correo: correo, contrasena: contrasena)
            loading = false
        }
    }
}
