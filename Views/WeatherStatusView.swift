import SwiftUI

struct WeatherStatusView: View {
    @StateObject private var vm = CurrentWeatherViewModel()
    var body: some View {
        Group {
            if vm.loading {
                HStack { ProgressView(); Text("Cargando clima...") }
            } else if let err = vm.error {
                VStack(alignment: .leading, spacing: 6) {
                    Text(err).foregroundColor(.red).font(.caption)
                    if let dbg = vm.debugMessage {
                        Text(dbg).font(.caption2).foregroundColor(.secondary)
                    }
                    if let url = vm.lastRequestURL {
                        Text(url).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                    Button("Reintentar") { vm.loadForCurrentLocation() }
                        .padding(.top, 6)
                }
                } else if let w = vm.weather {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        // Small weather icon from OpenWeather
                        if let icon = w.weather?.first?.icon {
                            AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")) { img in
                                img.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 44, height: 44)
                        }

                        VStack(alignment: .leading) {
                            Text(w.name ?? "Ubicación")
                                .font(.headline)
                            if let desc = w.weather?.first?.description {
                                Text(desc.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if let temp = w.main?.temp {
                            Text(String(format: "%.0f°C", temp))
                                .font(.title2)
                                .bold()
                        }
                    }
                    HStack(spacing: 12) {
                        if let hum = w.main?.humidity { Text("Humedad: \(hum)%").font(.caption) }
                        if let wind = w.wind?.speed { Text(String(format: "Viento: %.1fm/s", wind)).font(.caption) }
                    }
                }
                .padding(8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sin datos de clima").foregroundColor(.secondary)
                    if WeatherAPI.apiKey.isEmpty {
                        Text("API key no encontrada. Añade OPENWEATHER_API_KEY en Info.plist o usa WeatherAPI.setFallbackKey(_:) en AppDelegate.")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    if let dbg = vm.debugMessage {
                        Text(dbg).font(.caption2).foregroundColor(.secondary)
                    }
                    if let url = vm.lastRequestURL {
                        Text(url).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                    Button("Cargar clima") { vm.loadForCurrentLocation() }
                        .padding(.top, 6)
                }
            }
        }
        .onAppear {
            // Do not auto-load on appear to avoid side-effects during login; allow user to trigger.
            // The button below triggers vm.loadForCurrentLocation().
        }
    }
}

struct WeatherStatusView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherStatusView()
    }
}
