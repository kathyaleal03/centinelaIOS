import SwiftUI

struct SubscriptionView: View {
    enum Mode { case subscribe, addPayment }

    let mode: Mode
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isProUser") private var isProUser: Bool = false

    @State private var cardNumber: String = ""
    @State private var cardName: String = ""
    @State private var expiry: String = ""
    @State private var cvc: String = ""
    @State private var processing: Bool = false
    @State private var message: String = ""

    @State private var paymentMethods: [PaymentMethod] = []
    @State private var selectedMethodId: UUID? = nil

    init(mode: Mode = .subscribe) {
        self.mode = mode
    }

    var body: some View {
        NavigationView {
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
                        // Enhanced header with weather theme
                        VStack(spacing: 16) {
                            // Cloud icons decoration
                            HStack {
                                Spacer()
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white.opacity(0.3))
                                    .offset(x: -20, y: -10)
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.4))
                                    .offset(x: 10, y: 5)
                            }
                            
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color.yellow.opacity(0.5), radius: 20, x: 0, y: 0)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Suscripción Pro")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Sin anuncios • Alertas prioritarias")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("$3.99 / mes")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        VStack(spacing: 16) {
                            // Payment methods section
                            if !paymentMethods.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                            .foregroundColor(.blue)
                                        Text("Métodos de pago")
                                            .font(.headline)
                                    }
                                    .padding(.horizontal)
                                    
                                    ForEach(paymentMethods) { pm in
                                        HStack(spacing: 16) {
                                            Image(systemName: "creditcard")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                                .frame(width: 40)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(pm.masked)
                                                    .font(.headline)
                                                Text(pm.cardholderName)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text(pm.expiry)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                if pm.id == selectedMethodId {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "checkmark.circle.fill")
                                                        Text("Activa")
                                                    }
                                                    .font(.caption2)
                                                    .foregroundColor(.green)
                                                } else {
                                                    Button("Usar") { selectMethod(pm) }
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    Button(action: clearInputsForNew) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Agregar método de pago")
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // New card form
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Nueva tarjeta")
                                        .font(.headline)
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    PaymentTextField(
                                        icon: "person.fill",
                                        placeholder: "Nombre en la tarjeta",
                                        text: $cardName
                                    )
                                    
                                    PaymentTextField(
                                        icon: "creditcard.fill",
                                        placeholder: "Número de tarjeta",
                                        text: $cardNumber,
                                        keyboardType: .numberPad,
                                        onChange: { new in cardNumber = formatCardNumber(new) }
                                    )
                                    
                                    HStack(spacing: 12) {
                                        PaymentTextField(
                                            icon: "calendar",
                                            placeholder: "MM/AA",
                                            text: $expiry,
                                            keyboardType: .numbersAndPunctuation,
                                            onChange: { new in expiry = formatExpiry(new) }
                                        )
                                        
                                        PaymentTextField(
                                            icon: "lock.fill",
                                            placeholder: "CVC",
                                            text: $cvc,
                                            keyboardType: .numberPad,
                                            onChange: { new in cvc = new.filter({ $0.isNumber }).prefix(4).map { String($0) }.joined() }
                                        )
                                        .frame(maxWidth: 130)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            
                            // Action button
                            VStack(spacing: 12) {
                                if processing {
                                    HStack {
                                        ProgressView()
                                        Text("Procesando...")
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.7))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                } else {
                                    Button(action: primaryAction) {
                                        HStack(spacing: 8) {
                                            Image(systemName: mode == .subscribe ? "crown.fill" : "checkmark.circle.fill")
                                            Text(primaryButtonTitle)
                                                .fontWeight(.bold)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            LinearGradient(
                                                colors: [Color.blue, Color.cyan],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                                        .padding(.horizontal)
                                    }
                                    .disabled(!canPerformPrimaryAction())
                                    .opacity(canPerformPrimaryAction() ? 1.0 : 0.5)
                                }
                                
                                if !message.isEmpty {
                                    HStack {
                                        Image(systemName: message.contains("¡") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        Text(message)
                                    }
                                    .font(.caption)
                                    .foregroundColor(message.contains("¡") ? .green : .red)
                                    .padding()
                                    .background(message.contains("¡") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle(mode == .subscribe ? "Pro" : "Pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .onAppear(perform: loadSavedMethods)
        }
    }

    // MARK: - UI pieces
    private var primaryButtonTitle: String { mode == .subscribe ? "Suscribirme ahora" : "Guardar método" }

    // MARK: - Actions
    private func loadSavedMethods() {
        paymentMethods = UserDefaults.standard.loadPaymentMethods()
        if let first = paymentMethods.first(where: { $0.isDefault }) { selectedMethodId = first.id }
    }

    private func selectMethod(_ pm: PaymentMethod) {
        // mark selected as default
        paymentMethods = paymentMethods.map { var m = $0; m.isDefault = (m.id == pm.id); return m }
        UserDefaults.standard.savePaymentMethods(paymentMethods)
        selectedMethodId = pm.id
    }

    private func clearInputsForNew() {
        cardNumber = ""
        cardName = ""
        expiry = ""
        cvc = ""
        selectedMethodId = nil
    }

    private func primaryAction() {
        // If in subscribe mode and a saved method is selected, use it; otherwise create new
        if mode == .subscribe, let selected = paymentMethods.first(where: { $0.id == selectedMethodId }) {
            // simulate subscription using selected method
            performSubscription(using: selected)
            return
        }

        // Validate inputs
        let digits = cardNumber.filter { $0.isNumber }
        guard digits.count >= 12, luhnCheck(digits) else { message = "Número de tarjeta inválido"; return }
        guard let (m, y) = parseExpiry(expiry) else { message = "Fecha de expiración inválida"; return }
        guard (cvc.count == 3 || cvc.count == 4) else { message = "CVC inválido"; return }

        // Save payment method
        let pm = PaymentMethod(cardholderName: cardName.isEmpty ? "Titular" : cardName, last4: String(digits.suffix(4)), masked: PaymentMethod.maskedNumber(from: digits), expiry: expiry, isDefault: true)
        // update list: make others non-default
        paymentMethods = paymentMethods.map { var t = $0; t.isDefault = false; return t }
        paymentMethods.insert(pm, at: 0)
        UserDefaults.standard.savePaymentMethods(paymentMethods)
        selectedMethodId = pm.id

        if mode == .subscribe {
            performSubscription(using: pm)
        } else {
            message = "Método guardado"
            // Dismiss after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { presentationMode.wrappedValue.dismiss() }
        }
    }

    private func performSubscription(using pm: PaymentMethod) {
        processing = true
        message = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // simulate success
            isProUser = true
            UserDefaults.standard.set(Date(), forKey: "proSince")
            // ensure payment method saved
            if !paymentMethods.contains(where: { $0.id == pm.id }) {
                paymentMethods.insert(pm, at: 0)
                UserDefaults.standard.savePaymentMethods(paymentMethods)
            }
            processing = false
            message = "¡Suscripción activa!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { presentationMode.wrappedValue.dismiss() }
        }
    }

    private func canPerformPrimaryAction() -> Bool {
        if mode == .subscribe {
            if selectedMethodId != nil { return true }
        }
        // if adding new or no selected method, require inputs
        let digits = cardNumber.filter { $0.isNumber }
        return !cardName.isEmpty && digits.count >= 12 && (cvc.count == 3 || cvc.count == 4) && parseExpiry(expiry) != nil
    }

    // MARK: - Helpers: formatting and validation
    private func formatCardNumber(_ s: String) -> String {
        let digits = s.filter { $0.isNumber }
        var groups: [String] = []
        var current = digits
        while !current.isEmpty {
            let take = String(current.prefix(4))
            groups.append(take)
            current = String(current.dropFirst(take.count))
        }
        return groups.joined(separator: " ")
    }

    private func formatExpiry(_ s: String) -> String {
        let digits = s.filter { $0.isNumber }
        var res = digits
        if digits.count > 2 { res.insert("/", at: res.index(res.startIndex, offsetBy: 2)) }
        return String(res.prefix(5))
    }

    private func parseExpiry(_ s: String) -> (Int, Int)? {
        let cleaned = s.filter { $0.isNumber }
        guard cleaned.count == 4 else { return nil }
        let mm = Int(cleaned.prefix(2)) ?? 0
        let yy = Int(cleaned.suffix(2)) ?? 0
        guard (1...12).contains(mm) else { return nil }
        return (mm, yy)
    }

    private func luhnCheck(_ digits: String) -> Bool {
        let nums = digits.compactMap { Int(String($0)) }
        guard !nums.isEmpty else { return false }
        let checksum = nums.reversed().enumerated().reduce(0) { sum, pair in
            let (i, n) = pair
            if i % 2 == 1 {
                let dbl = n * 2
                return sum + (dbl > 9 ? dbl - 9 : dbl)
            } else { return sum + n }
        }
        return checksum % 10 == 0
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
}

// MARK: - Payment TextField Component
struct PaymentTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var onChange: ((String) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .onChange(of: text) { newValue in
                    onChange?(newValue)
                }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
