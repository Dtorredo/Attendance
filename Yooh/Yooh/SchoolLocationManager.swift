//
//  SchoolLocationManager.swift
//  Yooh
//
//  Dynamic school location management
//

import Foundation
import CoreLocation
import SwiftUI

struct SchoolLocation: Codable, Identifiable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var radius: Double // in meters
    var isActive: Bool
    let dateCreated: Date
    
    init(name: String, address: String, latitude: Double, longitude: Double, radius: Double = 300.0) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.radius = min(300.0, radius)
        self.isActive = true
        self.dateCreated = Date()
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

class SchoolLocationManager: ObservableObject {
    @Published var schoolLocations: [SchoolLocation] = []
    @Published var activeSchoolLocation: SchoolLocation?
    @Published var isFirstLaunch: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let schoolLocationsKey = "SchoolLocations"
    private let firstLaunchKey = "IsFirstLaunch"
    
    init() {
        loadSchoolLocations()
        checkFirstLaunch()
    }
    
    // MARK: - School Location Management
    
    func addSchoolLocation(_ location: SchoolLocation) {
        // Allow only one-time setup; if already set, ignore
        guard schoolLocations.isEmpty else { return }
        var newLocation = location
        newLocation.isActive = true
        newLocation.radius = min(300.0, newLocation.radius)
        schoolLocations = [newLocation]
        activeSchoolLocation = newLocation
        saveSchoolLocations()
    }
    
    func setActiveSchool(_ location: SchoolLocation) {
        // Single location mode; no-op
    }
    
    func deleteSchoolLocation(_ location: SchoolLocation) {
        // Deleting is not allowed once set
    }
    
    // MARK: - Location Validation
    
    func isWithinSchoolBounds(_ userLocation: CLLocation) -> Bool {
        guard let activeSchool = activeSchoolLocation else { return false }
        
        let schoolLocation = activeSchool.clLocation
        let distance = userLocation.distance(from: schoolLocation)
        
        return distance <= activeSchool.radius
    }
    
    func distanceFromSchool(_ userLocation: CLLocation) -> Double? {
        guard let activeSchool = activeSchoolLocation else { return nil }
        
        let schoolLocation = activeSchool.clLocation
        return userLocation.distance(from: schoolLocation)
    }
    
    // MARK: - First Launch Setup
    
    private func checkFirstLaunch() {
        isFirstLaunch = !userDefaults.bool(forKey: firstLaunchKey)
    }
    
    func completeFirstLaunchSetup() {
        isFirstLaunch = false
        userDefaults.set(true, forKey: firstLaunchKey)
    }
    
    // MARK: - Data Persistence
    
    private func loadSchoolLocations() {
        guard let data = userDefaults.data(forKey: schoolLocationsKey) else {
            // Set your original school location as default
            setDefaultSchoolLocation()
            return
        }
        
        do {
            let locations = try JSONDecoder().decode([SchoolLocation].self, from: data)
            schoolLocations = locations
            activeSchoolLocation = locations.first { $0.isActive }
        } catch {
            print("Failed to load school locations: \(error)")
            setDefaultSchoolLocation()
        }
    }
    
    private func saveSchoolLocations() {
        do {
            let data = try JSONEncoder().encode(schoolLocations)
            userDefaults.set(data, forKey: schoolLocationsKey)
        } catch {
            print("Failed to save school locations: \(error)")
        }
    }
    
    private func setDefaultSchoolLocation() {
        // Use your original coordinates as the default
        let defaultSchool = SchoolLocation(
            name: "My School",
            address: "School Address",
            latitude: -1.191397,
            longitude: 36.655940,
            radius: 300.0
        )
        addSchoolLocation(defaultSchool)
    }
}
