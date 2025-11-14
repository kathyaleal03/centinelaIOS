import Foundation
import CoreLocation

enum WeatherError: Error {
    case missingApiKey
    case requestFailed(String)
    case decodingError(String)
}

struct CurrentWeather: Codable {
    struct WeatherDescription: Codable {
        let id: Int?
        let main: String?
        let description: String?
        let icon: String?
    }
    struct Main: Codable {
        let temp: Double?
        let feels_like: Double?
        let temp_min: Double?
        let temp_max: Double?
        let pressure: Int?
        let humidity: Int?
    }
    struct Wind: Codable { let speed: Double?; let deg: Int?; let gust: Double? }
    struct Clouds: Codable { let all: Int? }
    struct Sys: Codable { let country: String?; let sunrise: Int?; let sunset: Int? }
    struct Rain: Codable { let oneH: Double?; let threeH: Double?
        private enum CodingKeys: String, CodingKey { case oneH = "1h"; case threeH = "3h" }
    }
    struct Snow: Codable { let oneH: Double?; let threeH: Double?
        private enum CodingKeys: String, CodingKey { case oneH = "1h"; case threeH = "3h" }
    }

    let weather: [WeatherDescription]?
    let main: Main?
    let wind: Wind?
    let clouds: Clouds?
    let sys: Sys?
    let rain: Rain?
    let snow: Snow?
    let visibility: Int?
    let dt: Int?
    let timezone: Int?
    let name: String?
}

class WeatherService {
    static let shared = WeatherService()
    private init() {}

    /// Fetch current weather for given coordinates using OpenWeatherMap Current Weather API.
    func fetchCurrentWeather(lat: Double, lon: Double, units: String = "metric", lang: String = "es") async throws -> CurrentWeather {
        let key = WeatherAPI.apiKey
        guard !key.isEmpty else { throw WeatherError.missingApiKey }

        var comps = URLComponents(string: "\(WeatherAPI.baseURL)/weather")!
        comps.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "lang", value: lang),
            URLQueryItem(name: "appid", value: key)
        ]
        guard let url = comps.url else { throw WeatherError.requestFailed("Invalid URL") }

        var req = URLRequest(url: url, timeoutInterval: APIConstants.timeout)
        req.httpMethod = "GET"

        print("[WeatherService] -> Requesting weather: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[WeatherService] <- Non-2xx response (\((response as? HTTPURLResponse)?.statusCode ?? -1)): \(body)")
            throw WeatherError.requestFailed("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1): \(body)")
        }

        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(CurrentWeather.self, from: data)
            if let bodyStr = String(data: data, encoding: .utf8) {
                print("[WeatherService] <- Success body: \(bodyStr)")
            }
            return decoded
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[WeatherService] Decoding error: \(error). Body: \(body)")
            throw WeatherError.decodingError(body)
        }
    }
}
