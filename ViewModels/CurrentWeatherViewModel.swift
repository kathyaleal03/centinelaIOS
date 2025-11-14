import Foundation
import CoreLocation

@MainActor
class CurrentWeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var weather: CurrentWeather?
    @Published var error: String?
    @Published var loading: Bool = false

    @Published var debugMessage: String?
    @Published var lastRequestURL: String?
    // Derived, display-ready strings
    @Published var feelsLikeText: String?
    @Published var visibilityText: String?
    @Published var cloudsText: String?
    @Published var sunriseText: String?
    @Published var sunsetText: String?
    @Published var updatedAtText: String?
    @Published var windText: String?
    @Published var precipitationText: String?

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public: Load weather
    func loadForCurrentLocation() {
        error = nil
        debugMessage = nil

        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        locationManager.requestLocation()
        loading = true
    }

    // MARK: - CoreLocation delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else {
            self.error = "No se pudo obtener la ubicación"
            self.loading = false
            return
        }

        lastLocation = loc
        Task { await fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = "Error al obtener ubicación: \(error.localizedDescription)"
        self.loading = false
    }

    // MARK: - Fetch weather
    func fetchWeather(lat: Double, lon: Double) async {
        do {
            let w = try await WeatherService.shared.fetchCurrentWeather(lat: lat, lon: lon)
            self.weather = w
            self.lastRequestURL = "lat=\(lat), lon=\(lon)"
            self.error = nil

            // compute derived display strings
            if let feels = w.main?.feels_like {
                self.feelsLikeText = String(format: "Sensación: %.0f°C", feels)
            } else { self.feelsLikeText = nil }

            if let vis = w.visibility {
                // visibility in meters -> km
                let km = Double(vis) / 1000.0
                self.visibilityText = String(format: "Visibilidad: %.1f km", km)
            } else { self.visibilityText = nil }

            if let clouds = w.clouds?.all {
                self.cloudsText = "Nubes: \(clouds)%"
            } else { self.cloudsText = nil }

            if let sun = w.sys?.sunrise, let tz = w.timezone {
                self.sunriseText = formatUnix(sun, timezoneOffset: tz)
            } else { self.sunriseText = nil }

            if let sun = w.sys?.sunset, let tz = w.timezone {
                self.sunsetText = formatUnix(sun, timezoneOffset: tz)
            } else { self.sunsetText = nil }

            if let dt = w.dt, let tz = w.timezone {
                self.updatedAtText = "Actualizado: \(formatUnix(dt, timezoneOffset: tz))"
            } else { self.updatedAtText = nil }

            if let wind = w.wind {
                var parts: [String] = []
                if let s = wind.speed { parts.append(String(format: "%.1f m/s", s)) }
                if let deg = wind.deg { parts.append(windDirection(from: deg)) }
                if let gust = wind.gust { parts.append(String(format: "ráfagas %.1f m/s", gust)) }
                if parts.isEmpty { self.windText = nil } else { self.windText = "Viento: \(parts.joined(separator: ", "))" }
            } else { self.windText = nil }

            // precipitation from rain or snow
            if let rain = w.rain, let r1 = rain.oneH ?? rain.threeH {
                self.precipitationText = String(format: "Lluvia: %.2f mm", r1)
            } else if let snow = w.snow, let s1 = snow.oneH ?? snow.threeH {
                self.precipitationText = String(format: "Nieve: %.2f mm", s1)
            } else {
                self.precipitationText = nil
            }
        } catch {
            self.error = "Error al obtener clima: \(error.localizedDescription)"
        }
        loading = false
    }

    // Helper: format unix timestamp to local time string using timezone offset (seconds)
    private func formatUnix(_ ts: Int, timezoneOffset: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        if let tz = TimeZone(secondsFromGMT: timezoneOffset) {
            let df = DateFormatter()
            df.timeStyle = .short
            df.dateStyle = .none
            df.timeZone = tz
            return df.string(from: date)
        } else {
            let df = DateFormatter()
            df.timeStyle = .short
            df.dateStyle = .none
            return df.string(from: date)
        }
    }

    private func windDirection(from degrees: Int) -> String {
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let idx = Int((Double(degrees) + 11.25) / 22.5) & 15
        return dirs[idx]
    }
}

