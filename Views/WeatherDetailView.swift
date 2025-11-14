import SwiftUI
import CoreLocation

struct WeatherDetailView: View {
    @StateObject private var vm = CurrentWeatherViewModel()
    @State private var animateIcon = false

    var body: some View {
        ZStack {
            backgroundView
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: { vm.loadForCurrentLocation() }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding()

                if vm.loading {
                    Spacer()
                    ProgressView("Cargando clima...")
                        .tint(.white)
                    Spacer()
                } else if let w = vm.weather {
                    VStack(spacing: 12) {
                            // Animated / remote icon
                            if let icon = w.weather?.first?.icon, let url = URL(string: "https://openweathermap.org/img/wn/\(icon)@4x.png") {
                                AsyncImage(url: url) { img in
                                    img.resizable().scaledToFit()
                                } placeholder: {
                                    Image(systemName: symbolName(for: w.weather?.first?.main))
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 120, height: 120)
                                .scaleEffect(animateIcon ? 1.05 : 0.95)
                                .rotationEffect(.degrees(animateIcon ? 6 : -6))
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                            } else {
                                Image(systemName: symbolName(for: w.weather?.first?.main))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.white)
                                    .scaleEffect(animateIcon ? 1.05 : 0.95)
                                    .rotationEffect(.degrees(animateIcon ? 6 : -6))
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                            }

                        Text(w.name ?? "Mi ubicación")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.title2)

                        if let temp = w.main?.temp {
                            Text(String(format: "%.0f°", temp))
                                .font(.system(size: 64, weight: .heavy))
                                .foregroundColor(.white)
                        }

                        if let desc = w.weather?.first?.description {
                            Text(desc.capitalized)
                                .foregroundColor(.white.opacity(0.9))
                                .font(.title3)
                        }

                        HStack(spacing: 24) {
                            if let hum = w.main?.humidity {
                                VStack { Text("Humedad"); Text("\(hum)%") }
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                            if let windStr = vm.windText {
                                VStack { Text("Viento"); Text(windStr.replacingOccurrences(of: "Viento: ", with: "")) }
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.top, 8)

                        // Additional details block
                        VStack(spacing: 10) {
                            Divider().background(Color.white.opacity(0.5))
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    if let feels = vm.feelsLikeText { Text(feels).foregroundColor(.white) }
                                    if let vis = vm.visibilityText { Text(vis).foregroundColor(.white) }
                                    if let clouds = vm.cloudsText { Text(clouds).foregroundColor(.white) }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 6) {
                                    if let precip = vm.precipitationText { Text(precip).foregroundColor(.white) }
                                    if let sunrise = vm.sunriseText { Text("Amanecer: \(sunrise)").foregroundColor(.white) }
                                    if let sunset = vm.sunsetText { Text("Atardecer: \(sunset)").foregroundColor(.white) }
                                }
                            }
                            if let updated = vm.updatedAtText {
                                HStack { Spacer(); Text(updated).font(.caption).foregroundColor(.white.opacity(0.85)) }
                            }
                        }
                    }
                    .padding()
                    .onAppear { animateIcon = true }
                } else {
                    VStack(spacing: 12) {
                        Text("Sin datos de clima")
                            .foregroundColor(.white)
                        if let dbg = vm.debugMessage { Text(dbg).font(.caption).foregroundColor(.white.opacity(0.85)) }
                        if let url = vm.lastRequestURL { Text(url).font(.caption2).foregroundColor(.white.opacity(0.8)).lineLimit(1) }
                        Button("Cargar clima") { vm.loadForCurrentLocation() }
                            .padding(.top, 8)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Clima completo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.loadForCurrentLocation() }
    }

    private var backgroundView: some View {
        let main = vm.weather?.weather?.first?.main
        return ZStack {
            LinearGradient(gradient: Gradient(colors: gradientColors(for: main)), startPoint: .topLeading, endPoint: .bottomTrailing)
                .animation(.easeInOut(duration: 0.8), value: main)

            // Particle overlays
            if let mainLower = main?.lowercased() {
                if mainLower.contains("rain") || mainLower.contains("drizzle") || mainLower.contains("thunderstorm") {
                    RainView(count: 26)
                        .transition(.opacity)
                } else if mainLower.contains("snow") {
                    SnowView(count: 24)
                        .transition(.opacity)
                }
            }
        }
    }

    private func gradientColors(for main: String?) -> [Color] {
        switch main?.lowercased() {
        case "clear": return [Color.blue, Color.cyan]
        case "clouds": return [Color.gray, Color.blue.opacity(0.6)]
        case "rain", "drizzle": return [Color.blue.opacity(0.7), Color.gray]
        case "thunderstorm": return [Color.purple, Color.black]
        case "snow": return [Color.white, Color.blue.opacity(0.6)]
        case "mist", "fog", "haze": return [Color.gray.opacity(0.6), Color.gray]
        default: return [Color.blue, Color.indigo]
        }
    }

    private func symbolName(for main: String?) -> String {
        switch main?.lowercased() {
        case "clear": return "sun.max.fill"
        case "clouds": return "cloud.fill"
        case "rain", "drizzle": return "cloud.rain.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snow": return "snow"
        case "mist", "fog", "haze": return "cloud.fog.fill"
        default: return "cloud.sun.fill"
        }
    }
}

struct WeatherDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDetailView()
    }
}
