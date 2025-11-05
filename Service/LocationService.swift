//
//  LocationService.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    private var locationCompletion: ((CLLocationCoordinate2D?) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func requestOnce() {
        // Simple request without callback — keep for existing callers
        manager.requestLocation()
    }

    // New overload that accepts a completion handler for immediate callback when location arrives/fails
    func requestOnce(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        self.locationCompletion = completion
        manager.requestLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coord = locations.first?.coordinate
        userLocation = coord
        // If a one-shot completion handler was provided, call it and clear
        if let completion = locationCompletion {
            completion(coord)
            locationCompletion = nil
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        if let completion = locationCompletion {
            completion(nil)
            locationCompletion = nil
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            manager.stopUpdatingLocation()
        }
    }
}
