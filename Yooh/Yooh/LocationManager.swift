//
//  LocationManager.swift
//  Yooh
//
//  Enhanced with dynamic school location support
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var isWithinSchool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var distanceFromSchool: Double?
    
    // Dynamic school location support
    private var schoolLocationManager: SchoolLocationManager?
    
    // Fallback to your original coordinates if no dynamic location is set
    private let defaultSchoolLocation = CLLocation(latitude: -1.191397, longitude: 36.655940)
    private let defaultSchoolRadius: CLLocationDistance = 500
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }
    
    func setSchoolLocationManager(_ manager: SchoolLocationManager) {
        self.schoolLocationManager = manager
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = "Location access denied. Please enable in Settings."
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
            distanceFromSchool = nil
            return
        }
        
        // Use dynamic school location if available, otherwise use default
        let schoolLocation: CLLocation
        let schoolRadius: CLLocationDistance
        
        if let schoolManager = schoolLocationManager,
           let activeSchool = schoolManager.activeSchoolLocation {
            schoolLocation = activeSchool.clLocation
            schoolRadius = activeSchool.radius
        } else {
            schoolLocation = defaultSchoolLocation
            schoolRadius = defaultSchoolRadius
        }
        
        let distance = currentLocation.distance(from: schoolLocation)
        distanceFromSchool = distance
        isWithinSchool = distance <= schoolRadius
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationError = nil
        checkIfWithinSchool()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "Location manager failed with error: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            isWithinSchool = false
            locationError = "Location access denied"
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
