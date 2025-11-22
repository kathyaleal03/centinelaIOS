import SwiftUI

struct ManageSubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isProUser") private var isProUser: Bool = false
    @State private var showingConfirmCancel: Bool = false
    @State private var paymentMethods: [PaymentMethod] = []
    @State private var infoMessage: String = ""

    private func loadMethods() {
        paymentMethods = UserDefaults.standard.loadPaymentMethods()
    }

    var body: some View {
        ZStack {
            // Weather-themed gradient background
            LinearGradient(
                colors: [
                    Color(#colorLiteral(red: 0.5, green: 0.85, blue: 0.98, alpha: 1.0)),
                    Color(#colorLiteral(red: 0.3, green: 0.65, blue: 0.85, alpha: 1.0))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header with crown and clouds
                    VStack(spacing: 16) {
                        // Cloud decorations
                        HStack {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 35))
                                .foregroundColor(.white.opacity(0.4))
                                .offset(x: -10, y: -5)
                            Spacer()
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.3))
                                .offset(x: 15, y: 8)
                        }
                        .padding(.horizontal, 30)
                        
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 90, height: 90)
                                .shadow(color: Color.yellow.opacity(0.6), radius: 20, x: 0, y: 0)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 45))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 6) {
                            Text("Gestionar Pro")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Administra tu suscripción")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        if isProUser {
                            // Status card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                    Text("Suscripción Activa")
                                        .font(.headline)
                                }
                                
                                if let since = UserDefaults.standard.object(forKey: "proSince") as? Date {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.blue)
                                        Text("Desde: \(since.formatted(.dateTime.year().month().day()))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                HStack {
                                    Image(systemName: "dollarsign.circle")
                                        .foregroundColor(.blue)
                                    Text("$3.99 / mes")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            
                            // Payment method card
                            if !paymentMethods.isEmpty {
                                let pm = paymentMethods.first { $0.isDefault } ?? paymentMethods.first!
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                            .foregroundColor(.blue)
                                        Text("Método de pago")
                                            .font(.headline)
                                    }
                                    
                                    HStack(spacing: 16) {
                                        Image(systemName: "creditcard")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(pm.masked)
                                                .font(.headline)
                                            Text(pm.cardholderName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(pm.expiry)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    
                                    NavigationLink(destination: SubscriptionView(mode: .addPayment)) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Cambiar o agregar método")
                                                .fontWeight(.medium)
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .padding(.horizontal)
                            } else {
                                // No payment method
                                VStack(spacing: 12) {
                                    Image(systemName: "creditcard.and.123")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                    
                                    Text("Sin método de pago")
                                        .font(.headline)
                                    
                                    NavigationLink(destination: SubscriptionView(mode: .addPayment)) {
                                        Text("Agregar método de pago")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing))
                                            .cornerRadius(12)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .padding(.horizontal)
                            }
                            
                            // Cancel button
                            Button(action: { showingConfirmCancel = true }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Cancelar suscripción")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.8), Color.red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .alert("Lamentamos que te vayas", isPresented: $showingConfirmCancel) {
                                Button("Sí, cancelar", role: .destructive) {
                                    isProUser = false
                                    UserDefaults.standard.removeObject(forKey: "proSince")
                                    infoMessage = "Suscripción cancelada. Volverán los anuncios."
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                                Button("Mantener Pro", role: .cancel) { }
                            } message: {
                                Text("¿Estás seguro? Al cancelar volverán los anuncios.")
                            }
                            
                        } else {
                            // Not subscribed
                            VStack(spacing: 16) {
                                Image(systemName: "crown")
                                    .font(.system(size: 60))
                                    .foregroundColor(.yellow)
                                
                                Text("No estás suscrito a Pro")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Text("Suscríbete para disfrutar sin anuncios")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                NavigationLink(destination: SubscriptionView(mode: .subscribe)) {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                        Text("Suscribirme ahora")
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(12)
                                    .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                        }
                        
                        if !infoMessage.isEmpty {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text(infoMessage)
                            }
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Gestionar Pro")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadMethods)
    }
}

struct ManageSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        ManageSubscriptionView()
    }
}
