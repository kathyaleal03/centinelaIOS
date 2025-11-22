import SwiftUI

struct EmergencyButtonView: View {
    @State private var isPressed = false
    @State private var showConfirmation = false
    @State private var emergencyActivated = false
    
    var body: some View {
        ZStack {
            // Emergency gradient background (red theme)
            LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)),
                    Color(#colorLiteral(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("Emergencia")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Presiona el botón para solicitar ayuda inmediata")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Emergency button
                if !emergencyActivated {
                    Button(action: {
                        showConfirmation = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 200, height: 200)
                                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 180, height: 180)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "sos")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("SOS")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in isPressed = true }
                            .onEnded { _ in isPressed = false }
                    )
                } else {
                    // Activated state
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 200, height: 200)
                            
                            Circle()
                                .fill(Color.green)
                                .frame(width: 180, height: 180)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("¡Ayuda en camino!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Las autoridades han sido notificadas")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Emergency info cards
                VStack(spacing: 12) {
                    EmergencyInfoCard(
                        icon: "phone.fill",
                        title: "Línea Directa",
                        subtitle: "911 - Emergencias",
                        color: .white
                    )
                    
                    EmergencyInfoCard(
                        icon: "location.fill",
                        title: "Tu Ubicación",
                        subtitle: "Será compartida automáticamente",
                        color: .white
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .alert("Confirmar Emergencia", isPresented: $showConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Confirmar", role: .destructive) {
                activateEmergency()
            }
        } message: {
            Text("¿Confirmas que necesitas ayuda de emergencia? Se notificará a las autoridades con tu ubicación.")
        }
    }
    
    private func activateEmergency() {
        emergencyActivated = true
        // TODO: Implement actual emergency notification logic
        print("[Emergency] SOS activated")
    }
}

// MARK: - Emergency Info Card
struct EmergencyInfoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(color.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}
