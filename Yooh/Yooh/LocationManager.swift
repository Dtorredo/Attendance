//
//  LocationManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var isWithinSchool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // School coordinates (replace with actual school coordinates)
    private let schoolLocation = CLLocation(latitude: -1.191397,longitude: 36.655940)
    private let schoolRadius: CLLocationDistance = 500 // 100 meters radius
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    private func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        locationManager.startUpdatingLocation()
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    private func checkIfWithinSchool() {
        guard let currentLocation = currentLocation else {
            isWithinSchool = false
            return
        }
        
        let distance = currentLocation.distance(from: schoolLocation)
        isWithinSchool = distance <= schoolRadius
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        checkIfWithinSchool()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            isWithinSchool = false
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
