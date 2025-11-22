import Foundation

struct PaymentMethod: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var cardholderName: String
    var last4: String
    var masked: String
    var expiry: String // MM/YY
    var isDefault: Bool = false

    static func maskedNumber(from full: String) -> String {
        let digits = full.filter { $0.isNumber }
        let last = String(digits.suffix(4))
        return "•••• •••• •••• \(last)"
    }
}

extension UserDefaults {
    private static let pmKey = "paymentMethods"

    func savePaymentMethods(_ methods: [PaymentMethod]) {
        if let data = try? JSONEncoder().encode(methods) {
            set(data, forKey: Self.pmKey)
        }
    }

    func loadPaymentMethods() -> [PaymentMethod] {
        guard let data = data(forKey: Self.pmKey) else { return [] }
        if let arr = try? JSONDecoder().decode([PaymentMethod].self, from: data) { return arr }
        return []
    }
}
