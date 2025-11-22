import SwiftUI

struct BannerAdView: View {
    let type: AdSimulator.AdType
    var onSubscribe: (() -> Void)? = nil
    @AppStorage("isProUser") private var isProUser: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(subtitle)
                    .font(.caption2)
            }
            Spacer()
            if isProUser {
                // pro users see no subscribe CTA, just a small label
                Text("Pro")
                    .font(.caption2)
                    .padding(6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
            } else {
                Button(action: {
                    // call parent to show subscription UI. Do not rely on this view staying alive.
                    onSubscribe?()
                }) {
                    Text("Ir a Pro $3.99/mes")
                        .font(.caption2)
                        .padding(6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
        .padding(10)
        .background(LinearGradient(colors: bgColors, startPoint: .leading, endPoint: .trailing))
        .cornerRadius(8)
        .shadow(radius: 6)
        .padding(.horizontal)
    }

    private var title: String {
        switch type {
        case .food: return "Promo: 2x1 Pupusas"
        case .unicaes: return "UNICAES - Inscripciones abiertas"
        }
    }

    private var subtitle: String {
        switch type {
        case .food: return "Llévate 2 pupusas al precio de 1 — oferta válida hoy"
        case .unicaes: return "Estudia carreras técnicas y profesionales en UNICAES. Conoce más."
        }
    }

    private var bgColors: [Color] {
        switch type {
        case .food: return [Color.orange, Color.red]
        case .unicaes: return [Color.blue, Color.purple]
        }
    }
}

struct BannerAdView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BannerAdView(type: .food)
            BannerAdView(type: .unicaes)
        }
    }
}
