import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.082, green: 0.478, blue: 0.702, alpha: 1.0))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top illustration area
                VStack {
                    Spacer(minLength: 30)   // antes era un spacer grande
                    if UIImage(named: "onboarding_illustration") != nil {
                        Image("onboarding_illustration")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 420)   // 🔼 reducido para subir el contenido
                    } else {
                        Image("astronauta")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 420)  // 🔼 más pequeño
                    }
                    Spacer(minLength: 10)
                }
                .frame(maxWidth: .infinity)
                
                // Bottom card
                VStack(spacing: 16) {
                    // Logo circle
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 54, height: 150)
                            .shadow(radius: 4)
                        
                        if UIImage(named: "icono") != nil {
                            Image("icono")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 94, height: 94)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "shield.lefthalf.filled")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundColor(Color(#colorLiteral(red: 0.082, green: 0.478, blue: 0.702, alpha: 1.0)))
                        }
                    }
                    
                    Text("Sistema de alertas")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Una aplicación que te ayuda a identificar los riesgos y alertas que suceden durante las lluvias")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Button(action: {
                        hasSeenOnboarding = true
                        authVM.logout()
                        dismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "cloud.fill")
                            Text("Empezar")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)      // 🔼 reducido
                        .padding(.horizontal, 26)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(#colorLiteral(red: 0.082, green: 0.478, blue: 0.702, alpha: 1.0)),
                                    Color(#colorLiteral(red: 0.129, green: 0.701, blue: 0.898, alpha: 1.0))
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 10)   // 🔼 MUCHO más arriba
                }
                .padding(.top, 10)           // 🔼 sube la tarjeta
                .frame(maxWidth: .infinity)
                .background(Color.white)
          


            }
        }
    }
}
