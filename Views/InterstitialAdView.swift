import SwiftUI

struct InterstitialAdView: View {
    let type: AdSimulator.AdType

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(header)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(iconColor)
                Text(bodyText)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.95))
                Button(action: {}) {
                    Text(buttonText)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: 320)
            .background(Color.primary.opacity(0.12))
            .cornerRadius(12)
        }
    }

    private var header: String {
        switch type {
        case .food: return "Oferta gastronómica"
        case .unicaes: return "UNICAES te invita"
        }
    }

    private var bodyText: String {
        switch type {
        case .food: return "Disfruta de nuestra promoción exclusiva: 2x1 en pupusas y combos especiales. Visítanos hoy y aprovecha."
        case .unicaes: return "Inscripciones abiertas en UNICAES. Programas técnicos y profesionales con becas disponibles. Infórmate ahora."
        }
    }

    private var buttonText: String { (type == .food) ? "Ver menú" : "Más info UNICAES" }

    private var iconName: String { (type == .food) ? "fork.knife" : "graduationcap.fill" }

    private var iconColor: Color { (type == .food) ? Color.yellow : Color.green }
}

struct InterstitialAdView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InterstitialAdView(type: .food)
            InterstitialAdView(type: .unicaes)
        }
    }
}
